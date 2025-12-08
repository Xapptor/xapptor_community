import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Metadata extracted from a video file without fully downloading it.
class VideoMetadata {
  final int width;
  final int height;
  final Duration duration;

  VideoMetadata({
    required this.width,
    required this.height,
    this.duration = Duration.zero,
  });

  bool get is_portrait => height > width;
  bool get is_landscape => width >= height;
  double get aspect_ratio => width / height;

  @override
  String toString() => 'VideoMetadata(${width}x$height, portrait: $is_portrait)';
}

/// Extracts video metadata (dimensions) using HTTP Range requests.
///
/// This approach downloads only ~5-50KB instead of 1-5MB per video,
/// reducing bandwidth usage by 97%+ compared to full video initialization.
class VideoMetadataExtractor {
  static final Map<String, VideoMetadata> _cache = {};

  /// Maximum bytes to download for metadata extraction.
  /// MP4 moov atom is usually in first 64KB or last 64KB of file.
  static const int _max_header_bytes = 65536; // 64KB

  /// Maximum cache entries to prevent unbounded memory growth.
  /// Each entry is ~100 bytes, so 200 entries = ~20KB.
  static const int _max_cache_entries = 200;

  /// Extract video metadata using minimal bandwidth.
  /// Returns null if extraction fails.
  static Future<VideoMetadata?> get_metadata(String url) async {
    // Check cache first
    if (_cache.containsKey(url)) {
      return _cache[url];
    }

    try {
      // Step 1: Try to get content length with HEAD request
      int? content_length;
      try {
        final head_response = await http.head(Uri.parse(url)).timeout(
          const Duration(seconds: 10),
        );
        content_length = int.tryParse(
          head_response.headers['content-length'] ?? '',
        );
      } catch (e) {
        debugPrint('VideoMetadataExtractor: HEAD request failed: $e');
      }

      // Step 2: Download first chunk (contains moov atom for most MP4 files)
      final range_response = await http.get(
        Uri.parse(url),
        headers: {'Range': 'bytes=0-${_max_header_bytes - 1}'},
      ).timeout(const Duration(seconds: 15));

      debugPrint('VideoMetadataExtractor: Range response status=${range_response.statusCode}, '
          'bytes=${range_response.bodyBytes.length}, content-length=$content_length');

      // Check if server supports range requests
      if (range_response.statusCode == 206) {
        final metadata = _parse_mp4_metadata(range_response.bodyBytes);
        debugPrint('VideoMetadataExtractor: Parsed from 206 response: $metadata');
        if (metadata != null) {
          _enforce_cache_limit();
          _cache[url] = metadata;
          debugPrint('VideoMetadataExtractor: Extracted from header - $metadata');
          return metadata;
        }
      } else if (range_response.statusCode == 200) {
        // Server doesn't support range requests, try to parse what we got
        final metadata = _parse_mp4_metadata(range_response.bodyBytes);
        debugPrint('VideoMetadataExtractor: Parsed from 200 response: $metadata');
        if (metadata != null) {
          _enforce_cache_limit();
          _cache[url] = metadata;
          debugPrint('VideoMetadataExtractor: Extracted (no range support) - $metadata');
          return metadata;
        }
      }

      // Step 3: If moov atom at end (some encodings), try downloading last chunk
      if (content_length != null && content_length > _max_header_bytes) {
        try {
          final start = content_length - _max_header_bytes;
          final end_range_response = await http.get(
            Uri.parse(url),
            headers: {'Range': 'bytes=$start-${content_length - 1}'},
          ).timeout(const Duration(seconds: 15));

          if (end_range_response.statusCode == 206) {
            final metadata = _parse_mp4_metadata(end_range_response.bodyBytes);
            if (metadata != null) {
              _enforce_cache_limit();
              _cache[url] = metadata;
              debugPrint('VideoMetadataExtractor: Extracted from end - $metadata');
              return metadata;
            }
          }
        } catch (e) {
          debugPrint('VideoMetadataExtractor: End range request failed: $e');
        }
      }

      debugPrint('VideoMetadataExtractor: Could not extract metadata for $url');
      return null;
    } catch (e) {
      debugPrint('VideoMetadataExtractor: Error extracting metadata: $e');
      return null;
    }
  }

  /// Parse MP4 metadata from bytes.
  /// Looks for tkhd (track header) atom which contains video dimensions.
  static VideoMetadata? _parse_mp4_metadata(Uint8List bytes) {
    try {
      // Look for tkhd atom (track header) which contains dimensions
      final tkhd_index = _find_atom(bytes, 'tkhd');
      debugPrint('VideoMetadataExtractor: tkhd_index=$tkhd_index');
      if (tkhd_index != -1) {
        final result = _parse_tkhd_atom(bytes, tkhd_index);
        debugPrint('VideoMetadataExtractor: tkhd parsed result=$result');
        if (result != null) return result;
      }

      // Alternative: look for stsd atom which may contain video dimensions
      final stsd_index = _find_atom(bytes, 'stsd');
      debugPrint('VideoMetadataExtractor: stsd_index=$stsd_index');
      if (stsd_index != -1) {
        final result = _parse_stsd_atom(bytes, stsd_index);
        debugPrint('VideoMetadataExtractor: stsd parsed result=$result');
        if (result != null) return result;
      }

      // Try to find dimensions in avc1 or hvc1 atoms (H.264/H.265 video)
      final avc1_index = _find_atom(bytes, 'avc1');
      debugPrint('VideoMetadataExtractor: avc1_index=$avc1_index');
      if (avc1_index != -1) {
        final result = _parse_visual_sample_entry(bytes, avc1_index);
        debugPrint('VideoMetadataExtractor: avc1 parsed result=$result');
        if (result != null) return result;
      }

      final hvc1_index = _find_atom(bytes, 'hvc1');
      debugPrint('VideoMetadataExtractor: hvc1_index=$hvc1_index');
      if (hvc1_index != -1) {
        final result = _parse_visual_sample_entry(bytes, hvc1_index);
        debugPrint('VideoMetadataExtractor: hvc1 parsed result=$result');
        if (result != null) return result;
      }

      return null;
    } catch (e) {
      debugPrint('VideoMetadataExtractor: Parse error: $e');
      return null;
    }
  }

  /// Find an atom by its 4-character name in the byte array.
  /// Returns the index of the atom's size field, or -1 if not found.
  static int _find_atom(Uint8List bytes, String atom_name) {
    if (bytes.length < 8) return -1;

    final atom_bytes = atom_name.codeUnits;
    if (atom_bytes.length != 4) return -1;

    // Search for the atom type (4 bytes after size field)
    for (int i = 4; i < bytes.length - 4; i++) {
      if (bytes[i] == atom_bytes[0] &&
          bytes[i + 1] == atom_bytes[1] &&
          bytes[i + 2] == atom_bytes[2] &&
          bytes[i + 3] == atom_bytes[3]) {
        return i - 4; // Return start of atom (size field)
      }
    }
    return -1;
  }

  /// Parse tkhd (track header) atom for dimensions.
  /// Structure:
  /// - 4 bytes: size
  /// - 4 bytes: 'tkhd'
  /// - 1 byte: version (0 or 1)
  /// - 3 bytes: flags
  /// - if version 0: 4 bytes creation, 4 bytes modification, 4 bytes track_id, 4 bytes reserved, 4 bytes duration
  /// - if version 1: 8 bytes creation, 8 bytes modification, 4 bytes track_id, 4 bytes reserved, 8 bytes duration
  /// - then matrix (36 bytes), then width (4 bytes 16.16 fixed point), height (4 bytes 16.16 fixed point)
  static VideoMetadata? _parse_tkhd_atom(Uint8List bytes, int atom_start) {
    try {
      final offset = atom_start + 8; // Skip size (4) + type (4)
      if (offset >= bytes.length) return null;

      final version = bytes[offset];

      // Calculate offset to width/height based on version
      int dimension_offset;
      if (version == 0) {
        // v0: 1 version + 3 flags + 4 creation + 4 modification + 4 track_id + 4 reserved + 4 duration + 36 matrix = 60 bytes
        dimension_offset = offset + 1 + 3 + 4 + 4 + 4 + 4 + 4 + 36;
      } else {
        // v1: 1 version + 3 flags + 8 creation + 8 modification + 4 track_id + 4 reserved + 8 duration + 36 matrix = 72 bytes
        dimension_offset = offset + 1 + 3 + 8 + 8 + 4 + 4 + 8 + 36;
      }

      if (dimension_offset + 8 > bytes.length) return null;

      // Width and height are 32-bit fixed-point (16.16)
      final width_fixed = _read_uint32(bytes, dimension_offset);
      final height_fixed = _read_uint32(bytes, dimension_offset + 4);

      // Convert from 16.16 fixed-point to integer
      final width = width_fixed >> 16;
      final height = height_fixed >> 16;

      // Validate dimensions
      if (width <= 0 || height <= 0 || width > 10000 || height > 10000) {
        return null;
      }

      return VideoMetadata(width: width, height: height);
    } catch (e) {
      return null;
    }
  }

  /// Parse stsd (sample description) atom for video dimensions.
  static VideoMetadata? _parse_stsd_atom(Uint8List bytes, int atom_start) {
    try {
      // stsd structure: size (4) + type (4) + version (1) + flags (3) + entry_count (4)
      final offset = atom_start + 8 + 4 + 4; // Skip to first entry

      if (offset + 8 > bytes.length) return null;

      // Look for visual sample entry (avc1, hvc1, etc.) within stsd
      for (int i = offset; i < bytes.length - 8; i++) {
        if ((bytes[i] == 0x61 && bytes[i + 1] == 0x76 && bytes[i + 2] == 0x63 && bytes[i + 3] == 0x31) || // avc1
            (bytes[i] == 0x68 && bytes[i + 1] == 0x76 && bytes[i + 2] == 0x63 && bytes[i + 3] == 0x31) || // hvc1
            (bytes[i] == 0x6D && bytes[i + 1] == 0x70 && bytes[i + 2] == 0x34 && bytes[i + 3] == 0x76)) { // mp4v
          return _parse_visual_sample_entry(bytes, i - 4);
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Parse visual sample entry (avc1, hvc1, mp4v) for dimensions.
  /// Structure:
  /// - 4 bytes: size
  /// - 4 bytes: type (avc1, hvc1, etc.)
  /// - 6 bytes: reserved
  /// - 2 bytes: data_reference_index
  /// - 2 bytes: pre_defined
  /// - 2 bytes: reserved
  /// - 12 bytes: pre_defined
  /// - 2 bytes: width
  /// - 2 bytes: height
  static VideoMetadata? _parse_visual_sample_entry(Uint8List bytes, int atom_start) {
    try {
      // Width at offset 32, height at offset 34 (from atom start)
      final width_offset = atom_start + 8 + 6 + 2 + 2 + 2 + 12;
      final height_offset = width_offset + 2;

      if (height_offset + 2 > bytes.length) return null;

      final width = _read_uint16(bytes, width_offset);
      final height = _read_uint16(bytes, height_offset);

      // Validate dimensions
      if (width <= 0 || height <= 0 || width > 10000 || height > 10000) {
        return null;
      }

      return VideoMetadata(width: width, height: height);
    } catch (e) {
      return null;
    }
  }

  /// Read a 32-bit big-endian unsigned integer from bytes.
  static int _read_uint32(Uint8List bytes, int offset) {
    return (bytes[offset] << 24) |
        (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) |
        bytes[offset + 3];
  }

  /// Read a 16-bit big-endian unsigned integer from bytes.
  static int _read_uint16(Uint8List bytes, int offset) {
    return (bytes[offset] << 8) | bytes[offset + 1];
  }

  /// Enforce maximum cache size by removing oldest entries.
  static void _enforce_cache_limit() {
    while (_cache.length >= _max_cache_entries) {
      final oldest_key = _cache.keys.first;
      _cache.remove(oldest_key);
    }
  }

  /// Clear the metadata cache.
  static void clear_cache() {
    _cache.clear();
  }

  /// Check if metadata is cached for a URL.
  static bool is_cached(String url) {
    return _cache.containsKey(url);
  }

  /// Get cached metadata without making network request.
  static VideoMetadata? get_cached(String url) {
    return _cache[url];
  }
}

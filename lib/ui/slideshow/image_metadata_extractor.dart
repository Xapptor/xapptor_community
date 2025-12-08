import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Metadata extracted from an image file without fully downloading it.
class ImageMetadata {
  final int width;
  final int height;
  final String format;

  ImageMetadata({
    required this.width,
    required this.height,
    this.format = 'unknown',
  });

  bool get is_portrait => height > width;
  bool get is_landscape => width >= height;
  double get aspect_ratio => width / height;
  Size get size => Size(width.toDouble(), height.toDouble());

  @override
  String toString() => 'ImageMetadata(${width}x$height, $format, portrait: $is_portrait)';
}

/// Extracts image metadata (dimensions) using HTTP Range requests.
///
/// This approach downloads only ~1-10KB instead of 1-5MB per image,
/// reducing bandwidth usage by 99%+ compared to full image download.
class ImageMetadataExtractor {
  static final Map<String, ImageMetadata> _cache = {};

  /// Maximum bytes to download for metadata extraction.
  /// Most image formats have dimensions in the first few KB.
  static const int _max_header_bytes = 16384; // 16KB

  /// Maximum cache entries to prevent unbounded memory growth.
  /// Each entry is ~100 bytes, so 500 entries = ~50KB.
  static const int _max_cache_entries = 500;

  /// Extract image metadata using minimal bandwidth.
  /// Returns null if extraction fails.
  static Future<ImageMetadata?> get_metadata(String url) async {
    // Check cache first
    if (_cache.containsKey(url)) {
      return _cache[url];
    }

    try {
      // Download first chunk (contains header for all common formats)
      final range_response = await http.get(
        Uri.parse(url),
        headers: {'Range': 'bytes=0-${_max_header_bytes - 1}'},
      ).timeout(const Duration(seconds: 15));

      Uint8List bytes;
      if (range_response.statusCode == 206 || range_response.statusCode == 200) {
        bytes = range_response.bodyBytes;
      } else {
        debugPrint('ImageMetadataExtractor: Unexpected status ${range_response.statusCode}');
        return null;
      }

      if (bytes.length < 8) {
        debugPrint('ImageMetadataExtractor: Response too short');
        return null;
      }

      // Try to detect format and parse dimensions
      ImageMetadata? metadata;

      // Check for JPEG
      if (bytes[0] == 0xFF && bytes[1] == 0xD8) {
        metadata = _parse_jpeg(bytes);
      }
      // Check for PNG
      else if (bytes[0] == 0x89 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x4E &&
          bytes[3] == 0x47) {
        metadata = _parse_png(bytes);
      }
      // Check for GIF
      else if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) {
        metadata = _parse_gif(bytes);
      }
      // Check for WebP
      else if (bytes.length >= 12 &&
          bytes[0] == 0x52 &&
          bytes[1] == 0x49 &&
          bytes[2] == 0x46 &&
          bytes[3] == 0x46 &&
          bytes[8] == 0x57 &&
          bytes[9] == 0x45 &&
          bytes[10] == 0x42 &&
          bytes[11] == 0x50) {
        metadata = _parse_webp(bytes);
      }
      // Check for BMP
      else if (bytes[0] == 0x42 && bytes[1] == 0x4D) {
        metadata = _parse_bmp(bytes);
      }

      if (metadata != null) {
        _enforce_cache_limit();
        _cache[url] = metadata;
        debugPrint('ImageMetadataExtractor: Extracted - $metadata');
        return metadata;
      }

      debugPrint('ImageMetadataExtractor: Could not extract metadata for $url');
      return null;
    } catch (e) {
      debugPrint('ImageMetadataExtractor: Error extracting metadata: $e');
      return null;
    }
  }

  /// Parse JPEG dimensions from bytes.
  /// JPEG stores dimensions in SOF (Start of Frame) markers.
  static ImageMetadata? _parse_jpeg(Uint8List bytes) {
    try {
      int offset = 2; // Skip SOI marker

      while (offset < bytes.length - 4) {
        // Check for marker
        if (bytes[offset] != 0xFF) {
          offset++;
          continue;
        }

        final marker = bytes[offset + 1];

        // Skip padding bytes
        if (marker == 0xFF) {
          offset++;
          continue;
        }

        // SOF markers (Start of Frame) contain dimensions
        // SOF0-SOF3, SOF5-SOF7, SOF9-SOF11, SOF13-SOF15
        if ((marker >= 0xC0 && marker <= 0xC3) ||
            (marker >= 0xC5 && marker <= 0xC7) ||
            (marker >= 0xC9 && marker <= 0xCB) ||
            (marker >= 0xCD && marker <= 0xCF)) {
          // SOF structure: length (2) + precision (1) + height (2) + width (2)
          if (offset + 9 > bytes.length) return null;

          final height = (bytes[offset + 5] << 8) | bytes[offset + 6];
          final width = (bytes[offset + 7] << 8) | bytes[offset + 8];

          if (width > 0 && height > 0 && width < 100000 && height < 100000) {
            return ImageMetadata(width: width, height: height, format: 'jpeg');
          }
        }

        // EOI (End of Image)
        if (marker == 0xD9) break;

        // Markers without length: RST0-RST7, SOI, EOI, TEM
        if ((marker >= 0xD0 && marker <= 0xD7) ||
            marker == 0xD8 ||
            marker == 0xD9 ||
            marker == 0x01) {
          offset += 2;
          continue;
        }

        // Read segment length and skip
        if (offset + 4 > bytes.length) break;
        final length = (bytes[offset + 2] << 8) | bytes[offset + 3];
        offset += 2 + length;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Parse PNG dimensions from bytes.
  /// PNG stores dimensions in IHDR chunk.
  static ImageMetadata? _parse_png(Uint8List bytes) {
    try {
      // PNG structure: 8 byte signature + IHDR chunk
      // IHDR: length (4) + 'IHDR' (4) + width (4) + height (4) + ...
      if (bytes.length < 24) return null;

      // Check IHDR chunk type at offset 12
      if (bytes[12] != 0x49 ||
          bytes[13] != 0x48 ||
          bytes[14] != 0x44 ||
          bytes[15] != 0x52) {
        return null;
      }

      // Width at offset 16, height at offset 20 (big-endian)
      final width = (bytes[16] << 24) |
          (bytes[17] << 16) |
          (bytes[18] << 8) |
          bytes[19];
      final height = (bytes[20] << 24) |
          (bytes[21] << 16) |
          (bytes[22] << 8) |
          bytes[23];

      if (width > 0 && height > 0 && width < 100000 && height < 100000) {
        return ImageMetadata(width: width, height: height, format: 'png');
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Parse GIF dimensions from bytes.
  static ImageMetadata? _parse_gif(Uint8List bytes) {
    try {
      // GIF structure: 'GIF' (3) + version (3) + width (2 LE) + height (2 LE)
      if (bytes.length < 10) return null;

      // Width and height are little-endian at offsets 6 and 8
      final width = bytes[6] | (bytes[7] << 8);
      final height = bytes[8] | (bytes[9] << 8);

      if (width > 0 && height > 0 && width < 100000 && height < 100000) {
        return ImageMetadata(width: width, height: height, format: 'gif');
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Parse WebP dimensions from bytes.
  static ImageMetadata? _parse_webp(Uint8List bytes) {
    try {
      if (bytes.length < 30) return null;

      // Check for VP8 (lossy), VP8L (lossless), or VP8X (extended)
      // After RIFF header (12 bytes), look for chunk type

      // VP8 chunk
      if (bytes.length >= 30 &&
          bytes[12] == 0x56 &&
          bytes[13] == 0x50 &&
          bytes[14] == 0x38 &&
          bytes[15] == 0x20) {
        // VP8 bitstream: skip to frame header
        // Width and height at specific offsets (little-endian, 14 bits each)
        if (bytes.length >= 30) {
          final width = (bytes[26] | (bytes[27] << 8)) & 0x3FFF;
          final height = (bytes[28] | (bytes[29] << 8)) & 0x3FFF;

          if (width > 0 && height > 0 && width < 100000 && height < 100000) {
            return ImageMetadata(width: width, height: height, format: 'webp');
          }
        }
      }

      // VP8L chunk (lossless)
      if (bytes.length >= 25 &&
          bytes[12] == 0x56 &&
          bytes[13] == 0x50 &&
          bytes[14] == 0x38 &&
          bytes[15] == 0x4C) {
        // VP8L signature: 0x2F at offset 20
        if (bytes[20] == 0x2F) {
          // Width and height encoded in next 4 bytes
          final bits =
              bytes[21] | (bytes[22] << 8) | (bytes[23] << 16) | (bytes[24] << 24);
          final width = (bits & 0x3FFF) + 1;
          final height = ((bits >> 14) & 0x3FFF) + 1;

          if (width > 0 && height > 0 && width < 100000 && height < 100000) {
            return ImageMetadata(width: width, height: height, format: 'webp');
          }
        }
      }

      // VP8X chunk (extended)
      if (bytes.length >= 30 &&
          bytes[12] == 0x56 &&
          bytes[13] == 0x50 &&
          bytes[14] == 0x38 &&
          bytes[15] == 0x58) {
        // Canvas size at offset 24 (3 bytes each, little-endian, +1)
        final width = (bytes[24] | (bytes[25] << 8) | (bytes[26] << 16)) + 1;
        final height = (bytes[27] | (bytes[28] << 8) | (bytes[29] << 16)) + 1;

        if (width > 0 && height > 0 && width < 100000 && height < 100000) {
          return ImageMetadata(width: width, height: height, format: 'webp');
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Parse BMP dimensions from bytes.
  static ImageMetadata? _parse_bmp(Uint8List bytes) {
    try {
      // BMP structure: 'BM' (2) + file size (4) + reserved (4) + offset (4) + header size (4) + width (4) + height (4)
      if (bytes.length < 26) return null;

      // Width at offset 18, height at offset 22 (little-endian, signed for height)
      final width = bytes[18] | (bytes[19] << 8) | (bytes[20] << 16) | (bytes[21] << 24);
      var height = bytes[22] | (bytes[23] << 8) | (bytes[24] << 16) | (bytes[25] << 24);

      // Height can be negative (top-down bitmap)
      if (height < 0) height = -height;

      if (width > 0 && height > 0 && width < 100000 && height < 100000) {
        return ImageMetadata(width: width, height: height, format: 'bmp');
      }

      return null;
    } catch (e) {
      return null;
    }
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
  static ImageMetadata? get_cached(String url) {
    return _cache[url];
  }
}

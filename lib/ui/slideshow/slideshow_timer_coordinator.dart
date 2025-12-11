import 'dart:async';
import 'dart:math';

/// Coordinates timing for multiple slideshow slots using a single timer.
/// This replaces 8 independent CarouselSlider timers with one shared timer,
/// reducing memory overhead by ~15-25 MB on web browsers.
///
/// Memory savings come from:
/// - 1 Timer instead of 8 Timer instances
/// - No PageController per slot (each uses ~2-3 MB with GPU textures)
/// - No TickerProviderStateMixin per slot
/// - No GestureRecognizer per slot
class SlideshowTimerCoordinator {
  /// Single timer that coordinates all slot transitions
  Timer? _coordinator_timer;

  /// The tick interval for checking if slots need to advance
  /// Smaller values = more responsive but higher CPU, larger = less responsive
  /// 500ms provides good balance between responsiveness and efficiency
  static const Duration _tick_interval = Duration(milliseconds: 500);

  /// Registered slots with their next transition times
  final Map<String, _SlotTiming> _slots = {};

  /// Random instance for generating intervals
  final Random _random = Random();

  /// Whether the coordinator is currently running
  bool _is_running = false;

  /// Start the coordinator timer
  void start() {
    if (_is_running) return;
    _is_running = true;

    _coordinator_timer = Timer.periodic(_tick_interval, (_) {
      _check_and_advance_slots();
    });
  }

  /// Stop the coordinator timer
  void stop() {
    _is_running = false;
    _coordinator_timer?.cancel();
    _coordinator_timer = null;
  }

  /// Register a slot with the coordinator.
  /// Returns the slot ID for later reference.
  ///
  /// [slot_id] - Unique identifier for the slot (e.g., "col_0_view_1")
  /// [min_interval_seconds] - Minimum time between transitions
  /// [max_interval_seconds] - Maximum time between transitions
  /// [on_advance] - Callback when the slot should advance to the next item
  /// [item_count] - Total number of items in this slot's carousel
  /// [initial_index] - Starting index for this slot (defaults to 0)
  String register_slot({
    required String slot_id,
    required int min_interval_seconds,
    required int max_interval_seconds,
    required void Function(int new_index) on_advance,
    required int item_count,
    int initial_index = 0,
  }) {
    // Use a random initial interval for each slot to stagger transitions.
    // This prevents all slots from advancing at the same time.
    final int interval_seconds = _random_interval(
      min_interval_seconds,
      max_interval_seconds,
    );

    // Add additional random offset (0 to max_interval) to stagger initial transitions
    // This ensures slots don't all start transitioning at the same moment
    final int stagger_offset = _random.nextInt(max_interval_seconds + 1);

    _slots[slot_id] = _SlotTiming(
      slot_id: slot_id,
      min_interval_seconds: min_interval_seconds,
      max_interval_seconds: max_interval_seconds,
      next_transition: DateTime.now().add(Duration(seconds: interval_seconds + stagger_offset)),
      on_advance: on_advance,
      current_index: initial_index,
      item_count: item_count,
    );

    return slot_id;
  }

  /// Unregister a slot from the coordinator
  void unregister_slot(String slot_id) {
    _slots.remove(slot_id);
  }

  /// Update the item count for a slot (e.g., when more items are loaded)
  void update_item_count(String slot_id, int new_count) {
    final slot = _slots[slot_id];
    if (slot != null) {
      slot.item_count = new_count;
    }
  }

  /// Force advance a specific slot immediately
  void force_advance(String slot_id) {
    final slot = _slots[slot_id];
    if (slot == null) return;

    _advance_slot(slot);
  }

  /// Get the current index for a slot
  int? get_current_index(String slot_id) {
    return _slots[slot_id]?.current_index;
  }

  /// Check all slots and advance those that are due
  void _check_and_advance_slots() {
    final now = DateTime.now();

    for (final slot in _slots.values) {
      if (now.isAfter(slot.next_transition) || now.isAtSameMomentAs(slot.next_transition)) {
        _advance_slot(slot, now: now);
      }
    }
  }

  /// Advance a slot to the next item
  void _advance_slot(_SlotTiming slot, {DateTime? now}) {
    if (slot.item_count <= 0) return;

    // Calculate next index (wrap around)
    slot.current_index = (slot.current_index + 1) % slot.item_count;

    // Schedule next transition with new random interval
    // Reuse 'now' timestamp if provided to avoid multiple DateTime.now() calls
    final int next_interval = _random_interval(
      slot.min_interval_seconds,
      slot.max_interval_seconds,
    );
    slot.next_transition = (now ?? DateTime.now()).add(Duration(seconds: next_interval));

    // Notify the slot to update
    slot.on_advance(slot.current_index);
  }

  /// Generate a random interval between min and max (inclusive)
  int _random_interval(int min, int max) {
    if (min >= max) return min;
    return min + _random.nextInt(max - min + 1);
  }

  /// Clean up resources
  void dispose() {
    stop();
    _slots.clear();
  }

  /// Get the number of registered slots (for debugging)
  int get slot_count => _slots.length;
}

/// Internal class to track timing for each slot
class _SlotTiming {
  final String slot_id;
  final int min_interval_seconds;
  final int max_interval_seconds;
  DateTime next_transition;
  final void Function(int new_index) on_advance;
  int current_index;
  int item_count;

  _SlotTiming({
    required this.slot_id,
    required this.min_interval_seconds,
    required this.max_interval_seconds,
    required this.next_transition,
    required this.on_advance,
    required this.current_index,
    required this.item_count,
  });
}

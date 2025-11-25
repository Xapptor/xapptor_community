import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:xapptor_community/gender_reveal/user/charts/bar_chart_widget.dart';
import 'package:xapptor_community/gender_reveal/user/charts/pie_chart.dart';
import 'package:xapptor_community/gender_reveal/user/countdown_view.dart';
import 'package:xapptor_community/gender_reveal/user/glowing_vote_button.dart';
import 'package:xapptor_community/ui/adaptive_glossy_card.dart';
import 'package:xapptor_community/gender_reveal/user/reaction_recorder.dart';
import 'package:xapptor_community/ui/slideshow/slideshow.dart';
import 'package:xapptor_ui/utils/is_portrait.dart';
import 'package:confetti/confetti.dart';

class VotingView extends StatefulWidget {
  final String mother_name;
  final String father_name;

  const VotingView({
    super.key,
    required this.mother_name,
    required this.father_name,
  });

  @override
  State<VotingView> createState() => _VotingViewState();
}

class _VotingViewState extends State<VotingView> with TickerProviderStateMixin {
  final GlobalKey<TooltipState> _celebration_tooltip_key = GlobalKey<TooltipState>();

  String user_name = '';
  double boy_votes = 10;
  double girl_votes = 62;
  String? selected_vote;

  // Glow animation for vote buttons
  late final AnimationController _glow_controller;
  late final Animation<double> _glow_animation;

  // Shake animation for celebration icon
  late final AnimationController _shake_controller;
  late final Animation<double> _shake_animation;
  Timer? _shake_timer;

  // Scroll → frost logic
  late final ScrollController _card_scroll_controller;
  double initial_frost = 0.2;
  double _card_scroll_factor = 0.2;

  bool confirmed = false;

  final _player = AudioPlayer();

  late ConfettiController _controller_top_center;

  @override
  void initState() {
    super.initState();

    _controller_top_center = ConfettiController(
      duration: const Duration(seconds: 6),
    );

    _card_scroll_controller = ScrollController();

    // After first layout, we know maxScrollExtent and can jump
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_card_scroll_controller.hasClients) return;

      final max = _card_scroll_controller.position.maxScrollExtent;
      if (max <= 0) return;

      final target_offset = max * initial_frost;
      _card_scroll_controller.jumpTo(target_offset);

      setState(() {
        _card_scroll_factor = initial_frost;
      });
    });

    _card_scroll_controller.addListener(_handleCardScroll);

    // Glow controller
    _glow_controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _glow_animation = CurvedAnimation(
      parent: _glow_controller,
      curve: Curves.easeInOut,
    );

    // Shake controller (for celebration icon)
    _shake_controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _shake_animation = CurvedAnimation(
      parent: _shake_controller,
      curve: Curves.easeOut,
    );

    _shake_controller.addStatusListener((status) {
      _celebration_tooltip_key.currentState?.ensureTooltipVisible();

      if (status == AnimationStatus.completed) {
        _shake_controller.reset();
        _schedule_next_shake();
      }
    });

    _schedule_next_shake();
  }

  void _schedule_next_shake() {
    _shake_timer?.cancel();

    // Random interval between 3 and 5 seconds
    final seconds = 3 + math.Random().nextInt(3); // 3, 4, or 5
    _shake_timer = Timer(Duration(seconds: seconds), () {
      if (!mounted) return;
      _shake_controller.forward();
    });
  }

  void _handleCardScroll() {
    if (!_card_scroll_controller.hasClients) return;
    final max = _card_scroll_controller.position.maxScrollExtent;
    final offset = _card_scroll_controller.offset;

    final factor = max > 0 ? (offset / max).clamp(0.0, 1.0) : 0.0;

    setState(() {
      _card_scroll_factor = factor;
    });
  }

  @override
  void dispose() {
    _card_scroll_controller.dispose();
    _glow_controller.dispose();
    _shake_timer?.cancel();
    _shake_controller.dispose();
    _player.dispose();
    _controller_top_center.dispose();
    super.dispose();
  }

  Future<void> _onVoteSelected(String vote) async {
    if (vote == selected_vote || confirmed) return;

    await showDialog<bool>(
      context: context,
      builder: (dialog_context) => AlertDialog(
        title: const Text('Confirm your vote'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to vote for ${vote == 'boy' ? 'Boy' : 'Girl'}?'),
            const SizedBox(height: 8),
            const Text(
              'Your vote is final.',
              style: TextStyle(
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              confirmed = false;
              Navigator.of(dialog_context).pop(false);
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              confirmed = true;
              Navigator.of(dialog_context).pop(true);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      if (selected_vote == 'boy') boy_votes -= 1;
      if (selected_vote == 'girl') girl_votes -= 1;
      if (vote == 'boy') boy_votes += 1;
      if (vote == 'girl') girl_votes += 1;
      selected_vote = vote;
    });
  }

  bool show_slideshow = false;

  bool show_reaction_recorder = true;

  bool show_voting_card = false;
  bool enable_voting_card = false;

  bool show_countdown = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    double screen_width = size.width;
    double screen_height = size.height;
    bool portrait = is_portrait(context);

    double total_votes = boy_votes + girl_votes;
    bool has_votes = total_votes > 0;
    final Color boy_color = Colors.blueAccent.shade200;
    final Color girl_color = Colors.pinkAccent.shade200;

    final double card_width = math.min(screen_width * (portrait ? 0.94 : 0.55), 1024);
    final double? card_height = portrait ? screen_height * 0.75 : null;

    return SafeArea(
      child: Stack(
        children: [
          Center(
            child: Container(
              color: const Color.fromARGB(255, 0, 0, 0),
              child: Stack(
                children: [
                  if (show_reaction_recorder) const ReactionRecorder(),
                  if (show_slideshow)
                    const Slideshow(
                      image_paths: [
                        'assets/example_photos/example_photo_1.jpeg',
                        'assets/example_photos/example_photo_2.jpeg',
                        'assets/example_photos/example_photo_3.jpeg',
                        'assets/example_photos/example_photo_4.jpeg',
                        'assets/example_photos/example_photo_5.jpeg',
                        'assets/example_photos/example_photo_6.jpeg',
                        'assets/example_photos/example_photo_7.jpeg',
                        'assets/example_photos/example_photo_8.jpeg',
                        'assets/example_photos/example_photo_9.jpeg',
                        'assets/example_photos/example_photo_10.jpeg',
                      ],
                      use_examples: false,
                    ),
                  if (show_countdown) const CountdownView(epoch: 1763924400),
                  if (enable_voting_card)
                    AnimatedOpacity(
                      opacity: show_voting_card ? 1.0 : 0.0,
                      duration: const Duration(seconds: 2),
                      curve: Curves.easeOut,
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(24),
                        child: SizedBox(
                          width: card_width,
                          height: card_height,
                          child: AdaptiveGlossyCard(
                            scroll_factor: portrait ? _card_scroll_factor : 0.0,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final bool stacked = portrait || constraints.maxWidth < 760;

                                // ───────────────── intro section ─────────────────
                                Widget introSection = Align(
                                  alignment: Alignment.topCenter,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: stacked ? constraints.maxWidth : 420,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 16,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.transparent,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Column(
                                            children: [
                                              AnimatedBuilder(
                                                animation: _shake_animation,
                                                builder: (context, child) {
                                                  final t = _shake_animation.value;

                                                  // small shake: translate + rotate
                                                  final double dx = math.sin(t * math.pi * 6) * 4; // ±4 px
                                                  final double angle = math.sin(t * math.pi * 6) * 0.04; // ±0.04 rad

                                                  return Transform.translate(
                                                    offset: Offset(dx, 0),
                                                    child: Transform.rotate(
                                                      angle: angle,
                                                      child: child,
                                                    ),
                                                  );
                                                },
                                                child: Tooltip(
                                                  key: _celebration_tooltip_key,
                                                  message: 'Click me',
                                                  child: IconButton(
                                                    iconSize: 44,
                                                    color: Theme.of(context).colorScheme.onPrimary,
                                                    onPressed: () async {
                                                      show_voting_card = false;
                                                      setState(() {});

                                                      Timer(const Duration(milliseconds: 1200), () {
                                                        enable_voting_card = false;
                                                        setState(() {});
                                                      });

                                                      Timer(const Duration(seconds: 30), () {
                                                        show_voting_card = true;
                                                        enable_voting_card = true;
                                                        setState(() {});
                                                      });

                                                      _controller_top_center.play();

                                                      Timer(const Duration(seconds: 1), () async {
                                                        if (!_player.playing) {
                                                          await _player.setAsset("assets/example_song/song.mp3");
                                                          await _player.play();
                                                        }
                                                      });
                                                    },
                                                    icon: const Icon(Icons.celebration),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                'Celebrate the Moment!',
                                                textAlign: TextAlign.center,
                                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                      color: Theme.of(context).colorScheme.onPrimary,
                                                      fontWeight: FontWeight.w800,
                                                      letterSpacing: 1.0,
                                                    ),
                                              ),
                                              const SizedBox(height: 10),
                                              RichText(
                                                textAlign: TextAlign.center,
                                                text: TextSpan(
                                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                        color: Theme.of(context).colorScheme.onPrimary,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                  children: [
                                                    const TextSpan(text: 'Welcome to the '),
                                                    TextSpan(
                                                      text: widget.mother_name,
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.w800,
                                                      ),
                                                    ),
                                                    const TextSpan(text: ' & '),
                                                    TextSpan(
                                                      text: widget.father_name,
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.w800,
                                                      ),
                                                    ),
                                                    const TextSpan(
                                                      text: ' gender reveal celebration!',
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        AnimatedBuilder(
                                          animation: _glow_animation,
                                          builder: (context, _) {
                                            final glow = _glow_animation.value;
                                            return Row(
                                              children: [
                                                Expanded(
                                                  child: GlowingVoteButton(
                                                    label: 'Boy',
                                                    icon: Icons.male,
                                                    color: boy_color,
                                                    isSelected: selected_vote == 'boy',
                                                    glowStrength: selected_vote == 'boy' ? glow : 0,
                                                    onTap: () => _onVoteSelected('boy'),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: GlowingVoteButton(
                                                    label: 'Girl',
                                                    icon: Icons.female,
                                                    color: girl_color,
                                                    isSelected: selected_vote == 'girl',
                                                    glowStrength: selected_vote == 'girl' ? glow : 0,
                                                    onTap: () => _onVoteSelected('girl'),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );

                                // ───────────────── charts section ─────────────────
                                Widget chartsSection = Align(
                                  alignment: Alignment.topCenter,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: stacked ? constraints.maxWidth : 520,
                                    ),
                                    child: AspectRatio(
                                      aspectRatio: stacked ? 0.9 : 1.35,
                                      child: !has_votes
                                          ? _buildNoVotesMessage(context)
                                          : _buildChartsSection(context, portrait, boy_color, girl_color),
                                    ),
                                  ),
                                );

                                final Widget content = stacked
                                    ? Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          introSection,
                                          const SizedBox(height: 72),
                                          chartsSection,
                                        ],
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Flexible(flex: 48, child: introSection),
                                          const SizedBox(width: 24),
                                          Flexible(flex: 52, child: chartsSection),
                                        ],
                                      );

                                // ⭐ This scrolls INSIDE the card when content > card height.
                                return SingleChildScrollView(
                                  controller: _card_scroll_controller,
                                  padding: EdgeInsets.fromLTRB(
                                    0,
                                    32,
                                    0,
                                    stacked ? 40 : 56,
                                  ),
                                  physics: const BouncingScrollPhysics(
                                    parent: AlwaysScrollableScrollPhysics(),
                                  ),
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minHeight: portrait ? constraints.maxHeight : 0,
                                    ),
                                    child: Align(
                                      alignment: Alignment.topCenter,
                                      child: content,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: ConfettiWidget(
                confettiController: _controller_top_center,
                blastDirectionality: BlastDirectionality.explosive,
                blastDirection: math.pi / 2,
                emissionFrequency: 0.05, // how often particles spawn
                numberOfParticles: 12, // per tick
                gravity: 0.2, // fall speed
                maxBlastForce: 20, // speed range
                minBlastForce: 5,
                shouldLoop: false,
                // colors: const [
                //   Colors.green,
                //   Colors.blue,
                //   Colors.pink,
                //   Colors.purple,
                //   Colors.yellow,
                // ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoVotesMessage(BuildContext context) {
    return Center(
      child: Text(
        'No votes yet',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
            ),
      ),
    );
  }

  Widget _buildChartsSection(
    BuildContext context,
    bool portrait,
    Color boy_color,
    Color girl_color,
  ) {
    return Flex(
      direction: portrait ? Axis.vertical : Axis.horizontal,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: BarChartWidget(
            girl_votes: girl_votes,
            boy_votes: boy_votes,
          ),
        ),
        if (portrait) const SizedBox(height: 16) else const SizedBox(width: 16),
        Expanded(
          child: VotePieChart(
            boy_votes: boy_votes,
            girl_votes: girl_votes,
            boy_color: boy_color,
            girl_color: girl_color,
          ),
        ),
      ],
    );
  }
}

import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class DIYLoadingAnimation extends StatefulWidget {
  final String taskName;
  final String assetName;

  const DIYLoadingAnimation({
    super.key,
    required this.taskName,
    required this.assetName,
  });

  @override
  State<DIYLoadingAnimation> createState() => _DIYLoadingAnimationState();
}

class _DIYLoadingAnimationState extends State<DIYLoadingAnimation>
    with TickerProviderStateMixin {
  late final AnimationController _spin;
  late final AnimationController _pulse;
  late final AnimationController _progress;
  late final AnimationController _textCycle;

  late final Animation<double> _pulseScale;
  late final Animation<double> _progressVal;
  late final Animation<double> _textOpacity;

  int _msgIdx = 0;
  late final List<String> _messages;

  @override
  void initState() {
    super.initState();

    _messages = [
      'Analyzing ${widget.assetName}…',
      'Researching ${widget.taskName}…',
      'Identifying required tools…',
      'Evaluating safety precautions…',
      'Estimating task duration…',
      'Building step-by-step guide…',
      'Finalizing your DIY plan…',
    ];

    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulseScale = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );

    _progress = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..forward();
    _progressVal = Tween<double>(begin: 0, end: 0.92).animate(
      CurvedAnimation(parent: _progress, curve: Curves.easeOutCubic),
    );

    _textCycle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
    _textOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 12),
      TweenSequenceItem(tween: Tween(begin: 1, end: 1), weight: 72),
      TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 16),
    ]).animate(_textCycle);
    _textCycle.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        setState(() => _msgIdx = (_msgIdx + 1) % _messages.length);
      }
    });
  }

  @override
  void dispose() {
    _spin.dispose();
    _pulse.dispose();
    _progress.dispose();
    _textCycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 48),

          // ── Single ring spinner + center icon ──
          SizedBox(
            height: 140,
            width: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Spinning ring
                AnimatedBuilder(
                  animation: _spin,
                  builder: (_, _) => CustomPaint(
                    size: const Size(140, 140),
                    painter: _SingleRingPainter(
                      progress: _spin.value,
                      color: AppColors.primary,
                    ),
                  ),
                ),

                // Pulsing center circle + icon
                ScaleTransition(
                  scale: _pulseScale,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary10,
                    ),
                    child: Icon(
                      Icons.home_repair_service_rounded,
                      size: 26,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 36),

          // ── Title ──
          Text(
            'Generating Your DIY Guide',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(height: 10),

          // ── Cycling subtitle ──
          SizedBox(
            height: 22,
            child: FadeTransition(
              opacity: _textOpacity,
              child: Text(
                _messages[_msgIdx],
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          const SizedBox(height: 32),

          // ── Thin progress bar ──
          AnimatedBuilder(
            animation: _progressVal,
            builder: (_, _) => Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: SizedBox(
                    height: 4,
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          color: AppColors.primary05,
                        ),
                        FractionallySizedBox(
                          widthFactor: _progressVal.value,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primaryDark,
                                  AppColors.primary,
                                  AppColors.primaryLight,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${(_progressVal.value * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'This may take a few seconds',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}

// Single smooth arc ring with a gradient tail

class _SingleRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _SingleRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Background track
    canvas.drawArc(
      rect,
      0,
      2 * pi,
      false,
      Paint()
        ..color = color.withValues(alpha: 0.08)
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke,
    );

    // Animated arc (~70% of circle) with gradient
    final startAngle = progress * 2 * pi;
    const sweepAngle = 0.7 * 2 * pi;

    final gradient = SweepGradient(
      startAngle: startAngle,
      endAngle: startAngle + sweepAngle,
      colors: [
        color.withValues(alpha: 0.0),
        color.withValues(alpha: 0.4),
        color,
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..shader = gradient.createShader(rect)
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Head dot
    final headAngle = startAngle + sweepAngle;
    canvas.drawCircle(
      Offset(
        center.dx + cos(headAngle) * radius,
        center.dy + sin(headAngle) * radius,
      ),
      3.5,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _SingleRingPainter old) =>
      old.progress != progress;
}
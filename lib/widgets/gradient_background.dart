import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Widget per sfondi con gradiente personalizzabili
class GradientBackground extends StatelessWidget {
  final Widget child;
  final LinearGradient? gradient;
  final bool addSafeArea;
  final EdgeInsets? padding;
  final bool animated;
  final Duration animationDuration;

  const GradientBackground({
    super.key,
    required this.child,
    this.gradient,
    this.addSafeArea = true,
    this.padding,
    this.animated = false,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  /// Costruttore per gradiente di successo
  const GradientBackground.success({
    super.key,
    required this.child,
    this.addSafeArea = true,
    this.padding,
    this.animated = false,
    this.animationDuration = const Duration(milliseconds: 300),
  }) : gradient = AppTheme.successGradient;

  /// Costruttore per gradiente di warning
  const GradientBackground.warning({
    super.key,
    required this.child,
    this.addSafeArea = true,
    this.padding,
    this.animated = false,
    this.animationDuration = const Duration(milliseconds: 300),
  }) : gradient = AppTheme.warningGradient;

  /// Costruttore per gradiente chiaro
  const GradientBackground.light({
    super.key,
    required this.child,
    this.addSafeArea = true,
    this.padding,
    this.animated = false,
    this.animationDuration = const Duration(milliseconds: 300),
  }) : gradient = AppTheme.lightGradient;

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: gradient ?? AppTheme.gradient,
      ),
      padding: padding,
      child: addSafeArea ? SafeArea(child: child) : child,
    );

    if (animated) {
      return AnimatedContainer(
        duration: animationDuration,
        curve: Curves.easeInOut,
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: gradient ?? AppTheme.gradient,
        ),
        padding: padding,
        child: addSafeArea ? SafeArea(child: child) : child,
      );
    }

    return content;
  }
}

/// Widget per sfondi con pattern decorativi
class DecorativeBackground extends StatelessWidget {
  final Widget child;
  final LinearGradient? gradient;
  final bool showPattern;
  final double patternOpacity;
  final bool addSafeArea;

  const DecorativeBackground({
    super.key,
    required this.child,
    this.gradient,
    this.showPattern = true,
    this.patternOpacity = 0.1,
    this.addSafeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: gradient ?? AppTheme.gradient,
      ),
      child: Stack(
        children: [
          // Pattern decorativo
          if (showPattern) _buildPattern(),
          
          // Contenuto principale
          addSafeArea ? SafeArea(child: child) : child,
        ],
      ),
    );
  }

  Widget _buildPattern() {
    return Positioned.fill(
      child: Opacity(
        opacity: patternOpacity,
        child: CustomPaint(
          painter: _PatternPainter(),
        ),
      ),
    );
  }
}

/// Painter per creare pattern decorativi
class _PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Crea un pattern di cerchi
    const spacing = 80.0;
    const radius = 30.0;

    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        canvas.drawCircle(
          Offset(x, y),
          radius,
          paint,
        );
      }
    }

    // Crea linee diagonali
    paint.strokeWidth = 0.5;
    for (double i = -size.height; i < size.width + size.height; i += 40) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Widget per sfondi con effetti particellari
class ParticleBackground extends StatefulWidget {
  final Widget child;
  final LinearGradient? gradient;
  final int particleCount;
  final bool addSafeArea;

  const ParticleBackground({
    super.key,
    required this.child,
    this.gradient,
    this.particleCount = 50,
    this.addSafeArea = true,
  });

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
    
    _particles = List.generate(
      widget.particleCount,
      (index) => Particle.random(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: widget.gradient ?? AppTheme.gradient,
      ),
      child: Stack(
        children: [
          // Particelle animate
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                size: Size.infinite,
                painter: _ParticlePainter(_particles, _controller.value),
              );
            },
          ),
          
          // Contenuto principale
          widget.addSafeArea 
            ? SafeArea(child: widget.child) 
            : widget.child,
        ],
      ),
    );
  }
}

/// Classe per rappresentare una particella
class Particle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final Color color;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.color,
  });

  factory Particle.random() {
    final random = DateTime.now().millisecondsSinceEpoch;
    return Particle(
      x: (random % 1000) / 1000,
      y: (random % 1000) / 1000,
      size: 1 + (random % 3),
      speed: 0.5 + (random % 100) / 200,
      color: Colors.white.withOpacity(0.3 + (random % 40) / 100),
    );
  }
}

/// Painter per disegnare le particelle
class _ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animationValue;

  _ParticlePainter(this.particles, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final paint = Paint()
        ..color = particle.color
        ..style = PaintingStyle.fill;

      // Calcola posizione animata
      final x = (particle.x * size.width + 
          (animationValue * particle.speed * size.width)) % size.width;
      final y = (particle.y * size.height + 
          (animationValue * particle.speed * size.height)) % size.height;

      canvas.drawCircle(
        Offset(x, y),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

/// Widget per transizioni tra sfondi
class TransitionBackground extends StatefulWidget {
  final Widget child;
  final LinearGradient fromGradient;
  final LinearGradient toGradient;
  final Duration duration;
  final bool addSafeArea;

  const TransitionBackground({
    super.key,
    required this.child,
    required this.fromGradient,
    required this.toGradient,
    this.duration = const Duration(seconds: 2),
    this.addSafeArea = true,
  });

  @override
  State<TransitionBackground> createState() => _TransitionBackgroundState();
}

class _TransitionBackgroundState extends State<TransitionBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.lerp(
                  widget.fromGradient.colors[0],
                  widget.toGradient.colors[0],
                  _animation.value,
                )!,
                Color.lerp(
                  widget.fromGradient.colors[1],
                  widget.toGradient.colors[1],
                  _animation.value,
                )!,
              ],
              begin: widget.fromGradient.begin,
              end: widget.fromGradient.end,
            ),
          ),
          child: widget.addSafeArea 
            ? SafeArea(child: widget.child) 
            : widget.child,
        );
      },
    );
  }
}
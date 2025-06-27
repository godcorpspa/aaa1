import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Pulsante per social login con animazioni e stati
class SocialButton extends StatefulWidget {
  final String asset;
  final VoidCallback onTap;
  final String? label;
  final bool showLabel;
  final double size;
  final bool enabled;
  final bool loading;
  final Duration animationDuration;

  const SocialButton({
    super.key,
    required this.asset,
    required this.onTap,
    this.label,
    this.showLabel = false,
    this.size = 90,
    this.enabled = true,
    this.loading = false,
    this.animationDuration = const Duration(milliseconds: 200),
  });

  /// Costruttore per Google
  const SocialButton.google({
    super.key,
    required VoidCallback onTap,
    bool showLabel = false,
    double size = 90,
    bool enabled = true,
    bool loading = false,
  }) : asset = 'assets/icons/google-logo.png',
       onTap = onTap,
       label = showLabel ? 'Google' : null,
       showLabel = showLabel,
       size = size,
       enabled = enabled,
       loading = loading,
       animationDuration = const Duration(milliseconds: 200);

  /// Costruttore per Facebook
  const SocialButton.facebook({
    super.key,
    required VoidCallback onTap,
    bool showLabel = false,
    double size = 90,
    bool enabled = true,
    bool loading = false,
  }) : asset = 'assets/icons/facebook.avif',
       onTap = onTap,
       label = showLabel ? 'Facebook' : null,
       showLabel = showLabel,
       size = size,
       enabled = enabled,
       loading = loading,
       animationDuration = const Duration(milliseconds: 200);

  /// Costruttore per Apple
  const SocialButton.apple({
    super.key,
    required VoidCallback onTap,
    bool showLabel = false,
    double size = 90,
    bool enabled = true,
    bool loading = false,
  }) : asset = 'assets/icons/apple.png',
       onTap = onTap,
       label = showLabel ? 'Apple' : null,
       showLabel = showLabel,
       size = size,
       enabled = enabled,
       loading = loading,
       animationDuration = const Duration(milliseconds: 200);

  @override
  State<SocialButton> createState() => _SocialButtonState();
}

class _SocialButtonState extends State<SocialButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (!widget.enabled || widget.loading) return;
    
    setState(() => _isPressed = true);
    _controller.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails details) {
    _onTapCancel();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _onTap() {
    if (!widget.enabled || widget.loading) return;
    
    HapticFeedback.selectionClick();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: widget.enabled ? _opacityAnimation.value : 0.5,
            child: GestureDetector(
              onTapDown: _onTapDown,
              onTapUp: _onTapUp,
              onTapCancel: _onTapCancel,
              onTap: _onTap,
              child: widget.showLabel ? _buildButtonWithLabel() : _buildIconButton(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIconButton() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: const Color(0xFFF9F6E8),
        borderRadius: BorderRadius.circular(widget.size * 0.18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isPressed ? 0.1 : 0.15),
            blurRadius: _isPressed ? 4 : 8,
            offset: Offset(0, _isPressed ? 2 : 4),
          ),
        ],
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
      ),
      child: _buildContent(),
    );
  }

  Widget _buildButtonWithLabel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F6E8),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isPressed ? 0.1 : 0.15),
            blurRadius: _isPressed ? 4 : 8,
            offset: Offset(0, _isPressed ? 2 : 4),
          ),
        ],
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: _buildContent(),
          ),
          const SizedBox(width: 12),
          Text(
            widget.label ?? '',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (widget.loading) {
      return Center(
        child: SizedBox(
          width: widget.showLabel ? 20 : widget.size * 0.3,
          height: widget.showLabel ? 20 : widget.size * 0.3,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.black54),
          ),
        ),
      );
    }

    return Center(
      child: Container(
        padding: EdgeInsets.all(widget.showLabel ? 0 : widget.size * 0.2),
        child: Image.asset(
          widget.asset,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              _getIconForAsset(widget.asset),
              size: widget.showLabel ? 24 : widget.size * 0.4,
              color: Colors.black54,
            );
          },
        ),
      ),
    );
  }

  IconData _getIconForAsset(String asset) {
    if (asset.contains('google')) return Icons.g_mobiledata;
    if (asset.contains('facebook')) return Icons.facebook;
    if (asset.contains('apple')) return Icons.apple;
    return Icons.login;
  }
}

/// Widget per griglia di social buttons
class SocialButtonGroup extends StatelessWidget {
  final List<SocialButtonConfig> buttons;
  final MainAxisAlignment alignment;
  final double spacing;
  final bool showLabels;

  const SocialButtonGroup({
    super.key,
    required this.buttons,
    this.alignment = MainAxisAlignment.spaceEvenly,
    this.spacing = 16,
    this.showLabels = false,
  });

  @override
  Widget build(BuildContext context) {
    if (showLabels) {
      return Column(
        children: buttons.map((config) => 
          Padding(
            padding: EdgeInsets.only(bottom: spacing),
            child: SizedBox(
              width: double.infinity,
              child: SocialButton(
                asset: config.asset,
                onTap: config.onTap,
                label: config.label,
                showLabel: true,
                enabled: config.enabled,
                loading: config.loading,
              ),
            ),
          ),
        ).toList(),
      );
    }

    return Row(
      mainAxisAlignment: alignment,
      children: buttons.map((config) => 
        SocialButton(
          asset: config.asset,
          onTap: config.onTap,
          enabled: config.enabled,
          loading: config.loading,
        ),
      ).toList(),
    );
  }
}

/// Configurazione per social button
class SocialButtonConfig {
  final String asset;
  final VoidCallback onTap;
  final String? label;
  final bool enabled;
  final bool loading;

  const SocialButtonConfig({
    required this.asset,
    required this.onTap,
    this.label,
    this.enabled = true,
    this.loading = false,
  });

  /// Factory per Google
  factory SocialButtonConfig.google({
    required VoidCallback onTap,
    bool enabled = true,
    bool loading = false,
  }) {
    return SocialButtonConfig(
      asset: 'assets/icons/google-logo.png',
      onTap: onTap,
      label: 'Continua con Google',
      enabled: enabled,
      loading: loading,
    );
  }

  /// Factory per Facebook
  factory SocialButtonConfig.facebook({
    required VoidCallback onTap,
    bool enabled = true,
    bool loading = false,
  }) {
    return SocialButtonConfig(
      asset: 'assets/icons/facebook.avif',
      onTap: onTap,
      label: 'Continua con Facebook',
      enabled: enabled,
      loading: loading,
    );
  }

  /// Factory per Apple
  factory SocialButtonConfig.apple({
    required VoidCallback onTap,
    bool enabled = true,
    bool loading = false,
  }) {
    return SocialButtonConfig(
      asset: 'assets/icons/apple.png',
      onTap: onTap,
      label: 'Continua con Apple',
      enabled: enabled,
      loading: loading,
    );
  }
}
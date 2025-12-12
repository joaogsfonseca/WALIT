import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Primary Button widget with loading state, gradient option, and haptic feedback
class PrimaryButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final bool useGradient;
  final IconData? icon;
  final double? width;
  final EdgeInsetsGeometry? padding;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.useGradient = false,
    this.icon,
    this.width,
    this.padding,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _isPressed = true);
      _animationController.forward();
      HapticFeedback.lightImpact();
    }
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.onPressed == null || widget.isLoading;
    
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: AppTheme.animationFast,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            gradient: !widget.isOutlined && widget.useGradient
                ? AppColors.goldGradient
                : null,
            color: widget.isOutlined
                ? Colors.transparent
                : (widget.useGradient ? null : Theme.of(context).colorScheme.onSurface),
            border: widget.isOutlined
                ? Border.all(
                    color: isDisabled 
                        ? Theme.of(context).disabledColor 
                        : (widget.useGradient ? AppColors.gold : Theme.of(context).colorScheme.onSurface),
                    width: 1.5,
                  )
                : null,
            boxShadow: !widget.isOutlined && !isDisabled
                ? [
                    BoxShadow(
                      color: widget.useGradient
                          ? AppColors.goldWithOpacity(0.3)
                          : Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                      blurRadius: _isPressed ? 4 : 8,
                      spreadRadius: _isPressed ? 0 : 1,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isDisabled ? null : () {
                HapticFeedback.mediumImpact();
                widget.onPressed?.call();
              },
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              splashColor: widget.useGradient
                  ? AppColors.goldWithOpacity(0.3)
                  : Theme.of(context).splashColor,
              highlightColor: Colors.transparent,
              child: Padding(
                padding: widget.padding ??
                    const EdgeInsets.symmetric(
                      vertical: AppTheme.spacingM,
                      horizontal: AppTheme.spacingL,
                    ),
                child: Center(
                  child: widget.isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              widget.isOutlined || widget.useGradient
                                  ? AppColors.gold
                                  : Theme.of(context).colorScheme.surface,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (widget.icon != null) ...[
                              Icon(
                                widget.icon,
                                size: 20,
                                color: widget.isOutlined
                                    ? Theme.of(context).colorScheme.onSurface
                                    : (widget.useGradient
                                        ? Colors.white // text on gradient usually white
                                        : Theme.of(context).colorScheme.surface),
                              ),
                              const SizedBox(width: AppTheme.spacingS),
                            ],
                            Text(
                              widget.text,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: widget.isOutlined
                                    ? (isDisabled
                                        ? Theme.of(context).disabledColor
                                        : Theme.of(context).colorScheme.onSurface)
                                    : Theme.of(context).colorScheme.surface,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Secondary/Outlined Button variant
class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double? width;

  const SecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isOutlined: true,
      icon: icon,
      width: width,
    );
  }
}

/// Gold Gradient Button variant for premium actions
class GoldButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double? width;

  const GoldButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      useGradient: true,
      icon: icon,
      width: width,
    );
  }
}

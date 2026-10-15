import 'package:dropline/core/theme/appcolors.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';

class PunchOutSlideBar extends StatefulWidget {
  final String actionText;
  final String timeText;
  final VoidCallback onCompleted;
  final bool isLoading;
  final double scale;

  const PunchOutSlideBar({
    super.key,
    required this.actionText,
    required this.timeText,
    required this.onCompleted,
    this.isLoading = false,
    this.scale = 1,
  });

  @override
  State<PunchOutSlideBar> createState() => _PunchOutSlideBarState();
}

class _PunchOutSlideBarState extends State<PunchOutSlideBar> {
  double _drag = 0;

  double get _barHeight => 150 * widget.scale;
  double get _handleSize => 88 * widget.scale;
  double get _padding => 42 * widget.scale;

  void _reset() {
    if (!mounted) return;
    setState(() => _drag = 0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxDrag = (constraints.maxWidth - _handleSize - (_padding * 2))
            .clamp(0.0, double.infinity)
            .toDouble();

        final drag = _drag.clamp(0.0, maxDrag);

        return Container(
          height: _barHeight,
          decoration: BoxDecoration(
            color: AppColors.cardBackground.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(52 * widget.scale),
            border: Border.all(
              color: AppColors.cardBorder.withValues(alpha: 0.55),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                left: 24 * widget.scale,
                top: 14 * widget.scale,
                bottom: 14 * widget.scale,
                width: (constraints.maxWidth * 0.57 + drag).clamp(
                  0.0,
                  constraints.maxWidth - 48 * widget.scale,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Color(0xFF48688D), Color(0xFF4C5A69)],
                    ),
                    borderRadius: BorderRadius.circular(70 * widget.scale),
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: 0.12),
                    ),
                  ),
                ),
              ),

              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 154 * widget.scale,
                    right: 24 * widget.scale,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 6,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            widget.actionText,
                            style: AppTextStyles.buttonLarge.copyWith(
                              fontSize: 36 * widget.scale,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 48 * widget.scale),
                      Expanded(
                        flex: 5,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            widget.timeText,
                            style: AppTextStyles.displaySmall.copyWith(
                              fontSize: 64 * widget.scale,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Positioned(
                left: _padding + drag,
                top: (_barHeight - _handleSize) / 2,
                child: GestureDetector(
                  onHorizontalDragUpdate: widget.isLoading
                      ? null
                      : (details) {
                          setState(() {
                            _drag = (_drag + details.delta.dx).clamp(
                              0.0,
                              maxDrag,
                            );
                          });
                        },
                  onHorizontalDragEnd: widget.isLoading
                      ? null
                      : (_) {
                          final completed =
                              maxDrag > 0 && _drag >= maxDrag * 0.85;
                          _reset();
                          if (completed) {
                            widget.onCompleted();
                          }
                        },
                  onHorizontalDragCancel: _reset,
                  child: Container(
                    width: _handleSize,
                    height: _handleSize,
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.white, width: 1.5),
                    ),
                    child: Center(
                      child: widget.isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : Icon(
                              Icons.keyboard_double_arrow_right_rounded,
                              color: AppColors.white,
                              size: 44 * widget.scale,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

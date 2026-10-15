import 'package:dropline/core/theme/appcolors.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';

class DashboardSlideButton extends StatefulWidget {
  final VoidCallback onCompleted;
  final bool isLoading;
  final bool isClockedIn;

  const DashboardSlideButton({
    super.key,
    required this.onCompleted,
    this.isLoading = false,
    this.isClockedIn = true,
  });

  @override
  State<DashboardSlideButton> createState() => _DashboardSlideButtonState();
}

class _DashboardSlideButtonState extends State<DashboardSlideButton> {
  double _dragPosition = 0;

  static const double _height = 76;
  static const double _handleSize = 64;
  static const double _padding = 6;

  void _reset() {
    if (!mounted) return;
    setState(() => _dragPosition = 0);
  }

  @override
  Widget build(BuildContext context) {
    // Let intrinsic-height parents measure the button without querying LayoutBuilder.
    return SizedBox(
      height: _height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxDrag = (constraints.maxWidth - _handleSize - (_padding * 2))
              .clamp(0.0, double.infinity)
              .toDouble();

          final drag = _dragPosition.clamp(0.0, maxDrag);

          return Container(
            height: _height,
            decoration: BoxDecoration(
              gradient: AppColors.buttonGradient,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: AppColors.buttonBorder.withValues(alpha: 0.4),
              ),
            ),
            child: Stack(
              children: [
                // Progress background
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: 0,
                  width: (drag + _handleSize + _padding).clamp(
                    0.0,
                    constraints.maxWidth,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                ),

                // Button label
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 58, right: 12),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        widget.isClockedIn
                            ? 'SLIDE TO CLOCK OUT'
                            : 'SLIDE TO CLOCK IN',
                        style: AppTextStyles.buttonLarge.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),

                // Draggable circular handle
                Positioned(
                  left: _padding + drag,
                  top: _padding,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragUpdate: widget.isLoading
                        ? null
                        : (details) {
                            setState(() {
                              _dragPosition = (_dragPosition + details.delta.dx)
                                  .clamp(0.0, maxDrag);
                            });
                          },
                    onHorizontalDragEnd: widget.isLoading
                        ? null
                        : (details) {
                            final completed =
                                maxDrag > 0 && _dragPosition >= maxDrag * 0.85;

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
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.white, width: 1.4),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadow,
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: widget.isLoading
                            ? const SizedBox(
                                height: 25,
                                width: 25,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.white,
                                ),
                              )
                            : const Icon(
                                Icons.keyboard_double_arrow_right,
                                color: AppColors.white,
                                size: 34,
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

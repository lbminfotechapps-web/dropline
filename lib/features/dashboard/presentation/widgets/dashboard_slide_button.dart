import 'package:dropline/core/theme/appcolors.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';

import 'package:dropline/core/theme/appcolors.dart';
import 'package:flutter/material.dart';

class DashboardSlideButton extends StatefulWidget {
  final VoidCallback onCompleted;
  final bool isLoading;
  final bool isClockedIn;

  const DashboardSlideButton({
    super.key,
    required this.onCompleted,
    this.isLoading = false,
    this.isClockedIn = false,
  });

  @override
  State<DashboardSlideButton> createState() =>
      _DashboardSlideButtonState();
}

class _DashboardSlideButtonState
    extends State<DashboardSlideButton> {
  double _dragPosition = 0;

  void _reset() {
    if (mounted) {
      setState(() => _dragPosition = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    const height = 56.0;
    const handleSize = 46.0;
    const padding = 4.0;

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxDrag =
              (constraints.maxWidth - handleSize - padding * 2)
                  .clamp(0.0, double.infinity)
                  .toDouble();

          final drag = _dragPosition.clamp(0.0, maxDrag);

          return Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: AppColors.border),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: (drag + handleSize + padding)
                      .clamp(0.0, constraints.maxWidth),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(
                        alpha: 0.15,
                      ),
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                ),

                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 55,
                      right: 12,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        widget.isLoading
                            ? 'PLEASE WAIT...'
                            : widget.isClockedIn
                                ? 'SLIDE TO CLOCK OUT'
                                : 'SLIDE TO CLOCK IN',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ),
                ),

                Positioned(
                  left: padding + drag,
                  top: padding,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragUpdate: widget.isLoading
                        ? null
                        : (details) {
                            setState(() {
                              _dragPosition =
                                  (_dragPosition + details.delta.dx)
                                      .clamp(0.0, maxDrag);
                            });
                          },
                    onHorizontalDragEnd: widget.isLoading
                        ? null
                        : (_) {
                            final completed = maxDrag > 0 &&
                                _dragPosition >= maxDrag * 0.85;

                            _reset();

                            if (completed) {
                              widget.onCompleted();
                            }
                          },
                    onHorizontalDragCancel: _reset,
                    child: Container(
                      height: handleSize,
                      width: handleSize,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primaryText,
                          width: 1,
                        ),
                      ),
                      child: widget.isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primaryText,
                              ),
                            )
                          : const Icon(
                              Icons.keyboard_double_arrow_right,
                              color: AppColors.primaryText,
                              size: 29,
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

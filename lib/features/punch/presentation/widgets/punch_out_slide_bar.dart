import 'package:dropline/core/theme/app_theme.dart';
import 'package:dropline/core/theme/appcolors.dart';
import 'package:flutter/material.dart';

class PunchOutSlideBar extends StatefulWidget {
  final VoidCallback onCompleted;
  final bool isLoading;

  const PunchOutSlideBar({
    super.key,
    required this.onCompleted,
    this.isLoading = false,
  });

  @override
  State<PunchOutSlideBar> createState() => _PunchOutSlideBarState();
}

class _PunchOutSlideBarState extends State<PunchOutSlideBar> {
  double _drag = 0;

  void _reset() {
    if (mounted) {
      setState(() => _drag = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    const barHeight = 64.0;
    const handleSize = 52.0;
    const padding = 5.0;
    final whiteTheme = WhiteAppTheme.isEnabled(context);
    final trackColor = context.accentColor(AppColors.primary);
    final progressColor = whiteTheme ? Colors.black : AppColors.primary;
    final labelColor = whiteTheme ? Colors.white : AppColors.primaryText;
    final handleColor = whiteTheme ? Colors.white : AppColors.primarySoft;
    final handleInk = whiteTheme ? WhiteAppTheme.accent : AppColors.primaryText;

    return SizedBox(
      height: barHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxDrag = (constraints.maxWidth - handleSize - padding * 2)
              .clamp(0.0, double.infinity)
              .toDouble();

          final drag = _drag.clamp(0.0, maxDrag);

          return Container(
            decoration: BoxDecoration(
              color: trackColor,
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: context.borderColor(AppColors.border),
                width: 1.2,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: (drag + handleSize + padding)
                      .clamp(0.0, constraints.maxWidth)
                      .toDouble(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: progressColor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                ),

                Positioned.fill(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 55, right: 12),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          widget.isLoading
                              ? 'PLEASE WAIT...'
                              : 'Slide to clock out',
                          style: TextStyle(
                            color: labelColor,
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
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
                      height: handleSize,
                      width: handleSize,
                      decoration: BoxDecoration(
                        color: handleColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: handleInk,
                          width: 1.4,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: widget.isLoading
                          ? SizedBox(
                              width: 23,
                              height: 23,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: handleInk,
                              ),
                            )
                          : Icon(
                              Icons.keyboard_double_arrow_right_rounded,
                              color: handleInk,
                              size: 31,
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

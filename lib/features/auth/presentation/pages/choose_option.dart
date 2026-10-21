import 'package:dropline/core/router/app_router.dart';
import 'package:dropline/core/theme/app_text_styles.dart';
import 'package:dropline/core/theme/appcolors.dart';
import 'package:dropline/core/utility/widgets/app_background.dart';
import 'package:dropline/core/utility/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ChooseOptionPage extends StatelessWidget {
  const ChooseOptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.sizeOf(context).width / 591;
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final scale = constraints.maxWidth / 591;
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 42 * scale,
                      vertical: 52 * scale,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'CHOOSE AN OPTION',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.titleLarge.copyWith(
                            fontSize: 28 * scale,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
                          ),
                        ),
                        SizedBox(height: 51 * scale),
                        _option(
                          label: 'PERSONAL',
                          onTap: () => context.go(AppRouter.dashboard),
                          scale: scale,
                        ),
                        SizedBox(height: 28 * scale),
                        _option(
                          label: 'BUSINESS',
                          onTap: () {
                            // ScaffoldMessenger.of(context)
                            //   ..clearSnackBars()
                            //   ..showSnackBar(
                            //     const SnackBar(
                            //       content: Text('Business is coming soon.'),
                            //     ),
                            //   );
                             AppToast.error('Business is coming soon.');
                          },
                          scale: scale,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _option({
    required String label,
    required VoidCallback onTap,
    required double scale,
  }) {
    return Center(
      child: SizedBox(
        // width: 240,
        child: Material(
          color: AppColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),

            side: BorderSide(
              color: AppColors.cardBorder.withValues(alpha: 0.65),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 72),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleLarge.copyWith(
                        fontSize: 28 * scale,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

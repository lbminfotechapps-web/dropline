import 'package:dropline/core/theme/app_theme.dart';
import 'package:dropline/core/theme/appcolors.dart';
import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? titleIcon;
  final String? subtitle;
  final Widget? subtitleWidget;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final double height;
  final Color? backgroundColor;

  const CustomAppBar({
    super.key,
    required this.title,
    this.titleIcon,
    this.subtitle,
    this.subtitleWidget,
    this.showBackButton = true,
    this.onBackPressed,
    this.actions,
    this.height = 64,
    this.backgroundColor,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    // AppBar reserves the platform's top inset above the toolbar, keeping
    // controls below status bars, camera cutouts, and the Dynamic Island.
    return AppBar(
      backgroundColor:
          backgroundColor ?? context.backgroundColor(AppColors.background),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      centerTitle: false,
      toolbarHeight: height,
      titleSpacing: 16,
      title: Row(
        children: [
          if (showBackButton) ...[
            InkWell(
              onTap: onBackPressed ?? () => Navigator.maybePop(context),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: context.surfaceColor(AppColors.surface),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: context.borderColor(AppColors.border),
                  ),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: context.linkColor(AppColors.iconColor),
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: 15),
          ],

          if (titleIcon != null) ...[titleIcon!, const SizedBox(width: 8)],
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: context.foregroundColor(AppColors.textPrimary),
                  ),
                ),

                if (subtitleWidget != null) ...[
                  const SizedBox(height: 3),
                  subtitleWidget!,
                ] else if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.mutedColor(AppColors.textSecondary),
                    ),
                  ),
                ],
              ],
            ),
          ),

          ...?actions,
        ],
      ),
    );
  }
}

import 'package:dropline/core/theme/app_theme.dart';
import 'package:dropline/core/theme/appcolors.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/location_node.dart';

class LocationSelectionDropdown extends StatelessWidget {
  final int step;
  final String title;
  final String hintText;
  final List<LocationNode> items;
  final LocationNode? selectedItem;
  final ValueChanged<LocationNode?> onChanged;
  final bool enabled;

  const LocationSelectionDropdown({
    super.key,
    required this.step,
    required this.title,
    required this.hintText,
    required this.items,
    required this.selectedItem,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = enabled && items.isNotEmpty;

    final selected = selectedItem != null &&
            items.any((item) => item.id == selectedItem!.id)
        ? selectedItem
        : null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF354154),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: selected != null
              ? AppColors.primary
              : AppColors.white.withValues(alpha: 0.15),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected != null
                      ? AppColors.primary
                      : AppColors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  step.toString().padLeft(2, '0'),
                  style: context
                      .themedText(AppTextStyles.labelMedium)
                      .copyWith(
                        color: selected != null
                            ? const Color(0xFF253322)
                            : context.foregroundColor(AppColors.white),
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: context.themedText(AppTextStyles.titleSmall),
                ),
              ),
              if (!isEnabled)
                Icon(
                  Icons.lock_outline_rounded,
                  color: context.mutedColor(AppColors.textMuted),
                  size: 18,
                ),
            ],
          ),

          const SizedBox(height: 14),

          DropdownButtonFormField<String>(
            key: ValueKey(
              '$step-${selected?.id ?? "none"}',
            ),
            initialValue: selected?.id,
            isExpanded: true,
            dropdownColor: const Color(0xFF354154),
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: context.foregroundColor(AppColors.white),
            ),
            style: context.themedText(AppTextStyles.inputText),
            decoration: InputDecoration(
              filled: true,
              fillColor: context.surfaceColor(Color(0xFF263246)),
              hintText: hintText,
              hintStyle: context.themedText(AppTextStyles.inputHint),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(
                  color: AppColors.white.withValues(
                    alpha: 0.15,
                  ),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(
                  color: context.accentColor(AppColors.primary),
                  width: 1.5,
                ),
              ),
            ),
            items: items.map((node) {
              return DropdownMenuItem<String>(
                value: node.id,
                child: Text(
                  node.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: !isEnabled
                ? null
                : (id) {
                    if (id == null) {
                      onChanged(null);
                      return;
                    }

                    for (final node in items) {
                      if (node.id == id) {
                        onChanged(node);
                        return;
                      }
                    }
                  },
          ),
        ],
      ),
    );
  }
}

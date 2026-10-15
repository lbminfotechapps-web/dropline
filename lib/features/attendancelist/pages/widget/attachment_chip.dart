import 'package:dropline/core/theme/appcolors.dart';
import 'package:flutter/material.dart';

class AttachmentChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const AttachmentChip({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: active
                ? Appcolors.primaryColor.withOpacity(0.08)
                : const Color(0xFFF7F8F7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active
                  ? Appcolors.primaryColor.withOpacity(0.20)
                  : const Color(0xFFE5E9E7),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17,
                color: active
                    ? Appcolors.primaryColor
                    : const Color(0xFF7A827F),
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: active
                        ? Appcolors.primaryColor
                        : const Color(0xFF68706D),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

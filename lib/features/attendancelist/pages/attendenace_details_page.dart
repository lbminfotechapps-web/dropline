import 'package:dropline/core/theme/appcolors.dart';
import 'package:dropline/features/attendancelist/data/model/attendance_record.dart';
import 'package:flutter/material.dart';

class AttendanceCard extends StatelessWidget {
  final AttendanceRecord record;
  final VoidCallback onEdit;

  const AttendanceCard({super.key, required this.record, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7EBE9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Small accent line
              Container(width: 4, color: Appcolors.primaryColor),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(15, 14, 12, 13),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // =================================================
                      // HEADER
                      // =================================================
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  record.siteName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w800,
                                    color: Appcolors.darkColor,
                                    letterSpacing: -0.2,
                                  ),
                                ),

                                const SizedBox(height: 5),

                                Text(
                                  record.date,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF7C8581),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          // EDIT
                          Material(
                            color: const Color(0xFFF4F7F5),
                            borderRadius: BorderRadius.circular(10),
                            child: InkWell(
                              onTap: onEdit,
                              borderRadius: BorderRadius.circular(10),
                              child: const SizedBox(
                                width: 36,
                                height: 36,
                                child: Icon(
                                  Icons.edit_outlined,
                                  size: 17,
                                  color: Appcolors.primaryColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // =================================================
                      // TIME ROW
                      // =================================================
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F9F8),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Row(
                          children: [
                            // IN
                            Expanded(
                              child: _TimeItem(
                                title: 'IN',
                                time: record.inTime,
                                alignment: CrossAxisAlignment.start,
                              ),
                            ),

                            // TIMELINE
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Appcolors.primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      color: const Color(0xFFD8DEDB),
                                    ),
                                  ),
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFE07845),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // OUT
                            Expanded(
                              child: _TimeItem(
                                title: 'OUT',
                                time: record.outTime,
                                alignment: CrossAxisAlignment.end,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      // =================================================
                      // TOTAL + ATTACHMENTS
                      // =================================================
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Appcolors.primaryColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              '7h 30m',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Appcolors.primaryColor,
                              ),
                            ),
                          ),

                          const Spacer(),

                          if (record.hasPhoto)
                            const _SmallInfo(
                              icon: Icons.photo_outlined,
                              text: '2',
                            ),

                          if (record.hasPhoto && record.hasRecording)
                            const SizedBox(width: 12),

                          if (record.hasRecording)
                            const _SmallInfo(
                              icon: Icons.mic_none_rounded,
                              text: '1',
                            ),
                        ],
                      ),

                      // =================================================
                      // NOTE
                      // =================================================
                      if (record.note.trim().isNotEmpty) ...[
                        const SizedBox(height: 11),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.only(top: 10),
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Color(0xFFEEF1EF)),
                            ),
                          ),
                          child: Text(
                            record.note,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              height: 1.4,
                              color: Color(0xFF69716E),
                            ),
                          ),
                        ),
                      ],
                    ],
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

// ======================================================================
// TIME ITEM
// ======================================================================

class _TimeItem extends StatelessWidget {
  final String title;
  final String time;
  final CrossAxisAlignment alignment;

  const _TimeItem({
    required this.title,
    required this.time,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.7,
            color: Color(0xFF8B928F),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          time,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: Appcolors.darkColor,
          ),
        ),
      ],
    );
  }
}

// ======================================================================
// SMALL ATTACHMENT INFO
// ======================================================================

class _SmallInfo extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SmallInfo({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: const Color(0xFF7B8480)),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF6B7470),
          ),
        ),
      ],
    );
  }
}

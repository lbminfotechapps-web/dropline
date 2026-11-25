import 'package:dropline/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:dropline/core/theme/appcolors.dart';
import 'package:dropline/features/event/data/repositories/event_draft_store.dart';
import 'package:dropline/features/event/presentation/widgets/event_attachment_preview.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PunchEventRecords extends StatefulWidget {
  const PunchEventRecords({
    super.key,
    required this.records,
    this.showCounts = true,
  });
  final List<EventDraftRecord> records;
  final bool showCounts;

  @override
  State<PunchEventRecords> createState() => _PunchEventRecordsState();
}

class _PunchEventRecordsState extends State<PunchEventRecords> {
  bool _showOld = false;

  String _dateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (date == today) return 'Today';
    if (date == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _open(EventDraftRecord record) {
    if (record.item.type == EventItemType.photo) {
      showDialog<void>(
        context: context,
        useSafeArea: false,
        builder: (context) => Dialog.fullscreen(
          backgroundColor: Colors.black,
          child: Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              leading: IconButton(
                tooltip: 'Close image',
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: const Text('Photo'),
            ),
            body: SafeArea(
              child: record.file == null || !record.file!.existsSync()
                  ? const Center(
                      child: Text(
                        'This file is no longer available.',
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  : InteractiveViewer(
                      minScale: 1,
                      maxScale: 5,
                      child: SizedBox.expand(
                        child: Image.file(
                          record.file!,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Center(
                            child: Text(
                              'Unable to open photo.',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      );
      return;
    }
    if (record.item.type == EventItemType.note) {
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: context.surfaceColor(AppColors.surface),
          surfaceTintColor: Colors.transparent,
          scrollable: true,
          content: SelectableText(
            record.item.text,
            style: TextStyle(
              color: context.foregroundColor(AppColors.textPrimary),
              fontSize: 16,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.surfaceColor(AppColors.surface),
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .7,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: record.file == null || !record.file!.existsSync()
                ? const Center(child: Text('This file is no longer available.'))
                : record.item.type == EventItemType.pdf
                ? SfPdfViewer.file(record.file!)
                : EventAttachmentPreview(
                    file: record.file!,
                    item: record.item,
                    onEditPdf: () {},
                  ),
          ),
        ),
      ),
    );
  }

  Widget _card(EventDraftRecord record) {
    final item = record.item;
    final time = record.createdAt;
    final label = time == null
        ? ''
        : '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    final photo = item.type == EventItemType.photo;
    final icon = switch (item.type) {
      EventItemType.note => Icons.description_outlined,
      EventItemType.audio => Icons.play_circle_fill_rounded,
      EventItemType.pdf => Icons.picture_as_pdf_outlined,
      EventItemType.photo => Icons.image_outlined,
    };
    final title = switch (item.type) {
      EventItemType.note => 'Note',
      EventItemType.audio => 'Voice note',
      EventItemType.pdf => 'PDF',
      EventItemType.photo => 'Photo',
    };
    return Material(
      color: const Color(0xFF234256),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _open(record),
        child: photo && record.file != null && record.file!.existsSync()
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    record.file!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Icon(
                      Icons.broken_image_outlined,
                      color: context.mutedColor(AppColors.textSecondary),
                    ),
                  ),
                  Positioned(
                    left: 6,
                    bottom: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: context.foregroundColor(Colors.white),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF3A596E)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          icon,
                          color: context.mutedColor(AppColors.textSecondary),
                          size: item.type == EventItemType.audio ? 30 : 22,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: context.foregroundColor(Colors.white),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          label,
                          style: TextStyle(
                            color: context.mutedColor(AppColors.textSecondary),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Text(
                        item.type == EventItemType.note
                            ? item.text
                            : item.type == EventItemType.audio
                            ? 'Tap to play recording'
                            : 'Tap to open document',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.mutedColor(AppColors.textSecondary),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final groups = <DateTime, List<EventDraftRecord>>{today: []};
    for (final record in widget.records) {
      groups.putIfAbsent(record.date, () => []).add(record);
    }
    final dates = groups.keys.toList()..sort((a, b) => b.compareTo(a));
    final hasOld = dates.any((date) => date != today);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final date in dates.where(
          (date) => date == today || _showOld,
        )) ...[
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _dateLabel(date),
                    style: TextStyle(
                      color: context.foregroundColor(Colors.white),
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (widget.showCounts)
                  Text(
                    '${groups[date]!.length} items',
                    style: TextStyle(
                      color: context.mutedColor(AppColors.textSecondary),
                    ),
                  ),
              ],
            ),
          ),
          if (groups[date]!.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'No events yet. Tap Add to record your work.',
                style: TextStyle(
                  color: context.mutedColor(AppColors.textSecondary),
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final records = groups[date]!;
                final width = (constraints.maxWidth - 10) / 2;
                return Column(
                  children: [
                    for (var index = 0; index < records.length; index += 2)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: SizedBox(
                          height:
                              records[index].item.type == EventItemType.photo ||
                                  (index + 1 < records.length &&
                                      records[index + 1].item.type ==
                                          EventItemType.photo)
                              ? width * .48
                              : 78,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: _card(records[index])),
                              const SizedBox(width: 10),
                              Expanded(
                                child: index + 1 < records.length
                                    ? _card(records[index + 1])
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
        if (hasOld)
          TextButton.icon(
            onPressed: () => setState(() => _showOld = !_showOld),
            label: Text(_showOld ? 'Hide Old Records' : 'View Old Records'),
            icon: Icon(_showOld ? Icons.expand_less : Icons.expand_more),
            style: TextButton.styleFrom(
              foregroundColor: context.mutedColor(AppColors.textSecondary),
            ),
          ),
      ],
    );
  }
}

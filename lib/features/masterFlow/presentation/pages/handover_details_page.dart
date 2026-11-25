import 'package:dropline/core/theme/app_theme.dart';
import 'package:dropline/core/theme/appcolors.dart';
import 'package:dropline/core/utility/widgets/appbar.dart';
import 'package:dropline/features/masterFlow/presentation/pages/handover_action_pages.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// Import your existing CustomAppBar and AppColors.

class HandoverDetailsPage extends StatefulWidget {
  const HandoverDetailsPage({
    super.key,
    required this.handover,
    required this.companyName,
  });

  final Map<String, String> handover;
  final String companyName;

  @override
  State<HandoverDetailsPage> createState() => _HandoverDetailsPageState();
}

class _HandoverDetailsPageState extends State<HandoverDetailsPage> {
  static const Color _bg = AppColors.background;
  static const Color _surface = AppColors.surface;
  static const Color _border = AppColors.border;
  static const Color _muted = AppColors.textSecondary;
  static const Color _primaryAccent = AppColors.primary;
  static const Color _blue = Color(0xFFA7D3FF);

  bool showDetails = true;
  bool showUpdates = true;

  final Set<int> expandedRoutes = {0, 4, 6};
  Future<void> openHandOverArea() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => HandOverAreaPage(
          data: HandoverAreaData(
            area: 'Building A › Level 03 › Apartment 305',
            projectName: 'Laxmi Gauri',
            companyName: 'PlasterCo',
            receivingCompany: 'Prime Painting',
            activityCode: 'PL-01',
            activityName: 'Plastering',
            visitNumber: 1,
            checkSheetCode: 'CS-02',
            checkSheetTitle: 'Plaster finish check',
            questions: [
              'Is the wall finish even?',
              'Are the doorway edges clean?',
            ],
          ),
        ),
      ),
    );

    if (!mounted) return;

    if (result == 'sent') {
      // Refresh the handover list/details from storage or API.
    }
  }

  // Sample route data matching your screenshot.
  // Replace with API response later.
  final List<_WorkRouteItem> routeItems = [
    _WorkRouteItem(
      title: 'First handover',
      subtitle: 'Apex Build → PlasterCo',
      status: 'To review',
      type: 'handover',
    ),
    _WorkRouteItem(
      title: 'Plastering',
      subtitle: 'PL-01 · PlasterCo · Visit 1',
      status: 'To check',
      type: 'activity',
      number: '01',
    ),
    _WorkRouteItem(
      title: 'Handover hold point',
      subtitle: 'PlasterCo → Prime Painting',
      status: 'Later',
      type: 'hold',
      detail: 'Opens after PlasterCo finishes this activity.',
    ),
    _WorkRouteItem(
      title: 'First coat',
      subtitle: 'PT-01 · Prime Painting · Visit 1',
      status: 'Upcoming',
      type: 'activity',
      number: '02',
    ),
    _WorkRouteItem(
      title: 'Handover hold point',
      subtitle: 'Prime Painting → PlasterCo',
      status: 'Later',
      type: 'hold',
      detail: 'Opens after Prime Painting finishes this activity.',
    ),
    _WorkRouteItem(
      title: 'Touch-ups',
      subtitle: 'PL-02 · PlasterCo · Visit 2',
      status: 'Upcoming',
      type: 'activity',
      number: '03',
    ),
    _WorkRouteItem(
      title: 'Handover hold point',
      subtitle: 'PlasterCo → Prime Painting',
      status: 'Later',
      type: 'hold',
      detail: 'Opens after PlasterCo finishes this activity.',
    ),
    _WorkRouteItem(
      title: 'Final coat',
      subtitle: 'PT-02 · Prime Painting · Visit 2',
      status: 'Upcoming',
      type: 'activity',
      number: '04',
    ),
  ];

  String get fullArea => widget.handover['area'] ?? '';

  String get apartment {
    final parts = fullArea.split('›');
    if (parts.isEmpty) return fullArea;
    return parts.last.trim();
  }

  String get building {
    final parts = fullArea.split('›');

    if (parts.length < 2) return fullArea;

    return parts.take(parts.length - 1).map((e) => e.trim()).join(' › ');
  }

  String get startingCompany => widget.handover['company'] ?? 'Apex Build';

  String get receivingCompany => widget.companyName;

  void toggleRoute(int index) {
    setState(() {
      if (expandedRoutes.contains(index)) {
        expandedRoutes.remove(index);
      } else {
        expandedRoutes.add(index);
      }
    });
  }

  Future<void> acceptArea() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => AcceptAreaFlowPage(
          handover: widget.handover,
          companyName: widget.companyName,
        ),
      ),
    );

    if (!mounted || result != 'accepted') return;

    Navigator.pop(context, 'accepted');
  }

  void rejectArea() {
    Navigator.pop(context, 'rejected');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor(_bg),

      appBar: CustomAppBar(
        title: apartment,
        subtitle: building,
        backgroundColor: context.backgroundColor(_bg),
        onBackPressed: () => Navigator.pop(context),
      ),

      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 20, 12, 30),
              children: [
                // Company handover heading
                Text(
                  '$startingCompany  →  $receivingCompany',
                  style: TextStyle(
                    color: context.foregroundColor(Colors.white),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 8),

                Align(
                  alignment: Alignment.centerLeft,
                  child: _statusBadge(
                    'Awaiting acceptance',
                    highlighted: false,
                  ),
                ),

                const SizedBox(height: 14),

                Divider(height: 1, color: context.borderColor(_border)),

                const SizedBox(height: 13),

                // View details accordion
                InkWell(
                  onTap: () {
                    setState(() {
                      showDetails = !showDetails;
                    });
                  },
                  child: Row(
                    children: [
                      Text(
                        'View details',
                        style: TextStyle(
                          color: context.linkColor(_blue),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Icon(
                        showDetails
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: context.linkColor(_blue),
                        size: 18,
                      ),
                    ],
                  ),
                ),

                if (showDetails) ...[
                  const SizedBox(height: 13),

                  Text(
                    'Apartment finishes · Laxmi Gauri · Ref AF-003',
                    style: TextStyle(
                      color: context.linkColor(_blue),
                      fontSize: 11,
                    ),
                  ),

                  const SizedBox(height: 13),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: context.surfaceColor(_surface),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.borderColor(_border)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'What they sent',
                          style: TextStyle(
                            color: context.foregroundColor(Colors.white),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 9),
                        Text(
                          'Apartment 305 is ready for plastering.',
                          style: TextStyle(color: context.foregroundColor(Colors.white), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 18),

                // Work route heading
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HandOverAreaPage(
                              data: HandoverAreaData(
                                area: 'Building A › Level 03 › Apartment 305',
                                projectName: 'Laxmi Gauri',
                                companyName: 'PlasterCo',
                                receivingCompany: 'Prime Painting',
                                activityCode: 'PL-01',
                                activityName: 'Plastering',
                                visitNumber: 1,
                                checkSheetCode: 'CS-02',
                                checkSheetTitle: 'Plaster finish check',
                                questions: [
                                  'Is the wall finish even?',
                                  'Are the doorway edges clean?',
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      child: Expanded(
                        child: Text(
                          'Work route',
                          style: TextStyle(
                            color: context.foregroundColor(Colors.white),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    Text(
                      '0/4 activities finished',
                      style: TextStyle(
                        color: context.linkColor(_blue),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 11),

                // Work route cards
                ...List.generate(
                  routeItems.length,
                  (index) => _buildRouteCard(routeItems[index], index),
                ),

                // Finish area
                Padding(
                  padding: EdgeInsets.fromLTRB(22, 12, 0, 20),
                  child: Row(
                    children: [
                      Icon(
                        Icons.flag_outlined,
                        color: context.mutedColor(_muted),
                        size: 17,
                      ),
                      SizedBox(width: 9),
                      Text(
                        'Finish the area',
                        style: TextStyle(
                          color: context.linkColor(_blue),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Work updates
                _buildWorkUpdates(),
              ],
            ),
          ),

          // Fixed bottom buttons
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildRouteCard(_WorkRouteItem item, int index) {
    final bool isActivity = item.type == 'activity';
    final bool isHold = item.type == 'hold';
    final bool isCurrent = index == 0 || index == 1;
    final bool isExpanded = expandedRoutes.contains(index);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isCurrent
            ? const Color(0xFF153B40)
            : context.surfaceColor(_surface),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent
              ? AppColors.primaryBorder
              : context.borderColor(_border),
          width: 1,
          style: isHold ? BorderStyle.solid : BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: isHold ? () => toggleRoute(index) : null,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
              child: Row(
                children: [
                  // Route number/icon
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isCurrent && isActivity
                          ? _primaryAccent
                          : const Color(0xFF1C4254),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isCurrent && isActivity
                            ? _primaryAccent
                            : const Color(0xFF456477),
                      ),
                    ),
                    child: isActivity
                        ? Text(
                            item.number ?? '',
                            style: TextStyle(
                              color: isCurrent
                                  ? const Color(0xFF092537)
                                  : context.linkColor(_blue),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          )
                        : Icon(
                            Icons.sync_alt,
                            size: 18,
                            color: isCurrent ? context.accentColor(_primaryAccent) : context.linkColor(_blue),
                          ),
                  ),

                  const SizedBox(width: 9),

                  // Route name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: TextStyle(
                            color: context.foregroundColor(Colors.white),
                            fontSize: 13,
                            fontWeight: isHold
                                ? FontWeight.w600
                                : FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: context.linkColor(_blue),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 5),

                  _statusBadge(item.status, highlighted: isCurrent),

                  if (!isActivity) ...[
                    const SizedBox(width: 5),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: context.mutedColor(_muted),
                      size: 17,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Expanded handover information
          if (isExpanded && item.detail != null) ...[
            Divider(height: 1, color: context.borderColor(_border)),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 12, 10, 14),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  item.detail!,
                  style: TextStyle(
                    color: context.linkColor(_blue),
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusBadge(String title, {required bool highlighted}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFF284B36) : const Color(0xFF17394C),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: highlighted
              ? AppColors.primaryBorder
              : const Color(0xFF386078),
        ),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: highlighted ? context.accentColor(_primaryAccent) : context.linkColor(_blue),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildWorkUpdates() {
    return Container(
      margin: const EdgeInsets.fromLTRB(4, 0, 4, 0),
      decoration: BoxDecoration(
        color: context.surfaceColor(_surface),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor(_border)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                showUpdates = !showUpdates;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time_outlined,
                    color: context.linkColor(_blue),
                    size: 16,
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Text(
                      'Work updates',
                      style: TextStyle(
                        color: context.linkColor(_blue),
                        fontSize: 12,
                      ),
                    ),
                  ),

                  Icon(
                    showUpdates
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: context.linkColor(_blue),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),

          if (showUpdates)
            Padding(
              padding: EdgeInsets.fromLTRB(18, 4, 14, 15),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: CircleAvatar(
                      radius: 4,
                      backgroundColor: context.linkColor(_blue),
                    ),
                  ),

                  SizedBox(width: 7),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Flow started',
                          style: TextStyle(
                            color: context.foregroundColor(Colors.white),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Apex Build · 15 Nov · 08:30',
                          style: TextStyle(
                            color: context.linkColor(_blue),
                            fontSize: 10,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'With Apex Build for the first handover to PlasterCo.',
                          style: TextStyle(color: context.foregroundColor(Colors.white), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 8),
      decoration: BoxDecoration(
        color: context.backgroundColor(_bg),
        border: Border(
          top: BorderSide(color: context.borderColor(_border), width: 0.7),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: SizedBox(
                height: 51,
                child: OutlinedButton.icon(
                  onPressed: rejectArea,
                  icon: const Icon(Icons.close, size: 17),
                  label: const Text('Reject area'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFFD18C),
                    side: const BorderSide(color: Color(0xFF8C663B)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            Expanded(
              flex: 1,
              child: SizedBox(
                height: 51,
                child: ElevatedButton.icon(
                  onPressed: acceptArea,
                  icon: const Icon(Icons.check, size: 17),
                  label: const Text('Accept area'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryAccent,
                    foregroundColor: const Color(0xFF092537),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Local model for route display.
class _WorkRouteItem {
  final String title;
  final String subtitle;
  final String status;
  final String type;
  final String? number;
  final String? detail;

  const _WorkRouteItem({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.type,
    this.number,
    this.detail,
  });
}

// Keep your existing imports for:
// AppColors
// CustomAppBar
// HandoverAreaData
// HandoverCheckSheetPage
// AreaAcceptedPage

class AcceptAreaFlowPage extends StatefulWidget {
  const AcceptAreaFlowPage({
    super.key,
    required this.handover,
    required this.companyName,
  });

  final Map<String, String> handover;
  final String companyName;

  @override
  State<AcceptAreaFlowPage> createState() => _AcceptAreaFlowPageState();
}

class _AcceptAreaFlowPageState extends State<AcceptAreaFlowPage> {
  static const Color _primaryAccent = AppColors.primary;
  static const Color _blue = Color(0xFFA7D3FF);

  final TextEditingController noteController = TextEditingController();

  final ImagePicker imagePicker = ImagePicker();

  List<String>? answers;

  final List<String> attachments = [];

  bool isSubmitting = false;

  // Replace with assigned check sheet API data.
  final List<String> questions = [
    'Is access clear?',
    'Are the walls ready for plastering?',
  ];

  // Area details
  String get area =>
      widget.handover['area'] ?? 'Building A › Level 03 › Apartment 305';

  String get projectName => widget.handover['projectName'] ?? 'Laxmi Gauri';

  String get startingCompany => widget.handover['company'] ?? 'Apex Build';

  String get activityCode => widget.handover['activityCode'] ?? 'PL-01';

  String get activityName => widget.handover['trade'] ?? 'Plastering';

  String get visitNumber => widget.handover['visitNumber'] ?? '1';

  bool get answersSaved {
    return answers != null &&
        answers!.length == questions.length &&
        answers!.every((answer) => answer.isNotEmpty);
  }

  // Open check sheet
  Future<void> openCheckSheet() async {
    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => HandoverCheckSheetPage(
          data: HandoverAreaData(
            area: area,
            projectName: projectName,
            companyName: widget.companyName,
            receivingCompany: widget.companyName,
            activityCode: activityCode,
            activityName: activityName,
            visitNumber: int.tryParse(visitNumber) ?? 1,
            checkSheetCode: 'CS-01',
            checkSheetTitle: 'Plastering area check',
            questions: questions,
          ),
          existingAnswers: answers,
        ),
      ),
    );

    if (!mounted || result == null) return;

    setState(() {
      answers = result;
    });
  }

  // Attachment options bottom sheet
  Future<void> openAttachmentSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.surfaceColor(AppColors.surface),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Add to handover',
                        style: TextStyle(
                          color: context.foregroundColor(AppColors.textPrimary),
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),

                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: Icon(
                        Icons.close,
                        color: context.foregroundColor(AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                _attachmentOption(
                  icon: Icons.camera_alt_outlined,
                  title: 'Take photo',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    takePhoto();
                  },
                ),

                _attachmentOption(
                  icon: Icons.image_outlined,
                  title: 'Choose photos',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    choosePhotos();
                  },
                ),

                _attachmentOption(
                  icon: Icons.attach_file,
                  title: 'Attach file',
                  subtitle: 'PDF, Word or Excel',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    attachFile();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _attachmentOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      decoration: BoxDecoration(
        color: context.surfaceColor(AppColors.surface),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.borderColor(AppColors.border)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: context.linkColor(_blue), size: 20),
        title: Text(
          title,
          style: TextStyle(
            color: context.foregroundColor(AppColors.textPrimary),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(color: context.linkColor(_blue), fontSize: 10),
              )
            : null,
        trailing: Icon(
          Icons.chevron_right,
          color: context.linkColor(_blue),
          size: 20,
        ),
      ),
    );
  }

  Future<void> takePhoto() async {
    try {
      final photo = await imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (!mounted || photo == null) return;

      setState(() {
        attachments.add(photo.path);
      });
    } catch (e) {
      showMessage('Unable to take photo: $e');
    }
  }

  Future<void> choosePhotos() async {
    try {
      final photos = await imagePicker.pickMultiImage(imageQuality: 80);

      if (!mounted || photos.isEmpty) return;

      setState(() {
        attachments.addAll(photos.map((e) => e.path));
      });
    } catch (e) {
      showMessage('Unable to choose photos: $e');
    }
  }

  Future<void> attachFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx'],
        // allowMultiple: true,
      );

      if (!mounted || result == null) return;

      setState(() {
        attachments.addAll(
          result.where((file) => file.path != null).map((file) => file.path!),
        );
      });
    } catch (e) {
      showMessage('Unable to attach file: $e');
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // Confirm acceptance
  Future<void> confirmAcceptance() async {
    // if (!answersSaved || isSubmitting) return;

    // final confirmed = await showDialog<bool>(
    //   context: context,
    //   builder: (dialogContext) => AlertDialog(
    //     backgroundColor: AppColors.surface,
    //     shape: RoundedRectangleBorder(
    //       borderRadius: BorderRadius.circular(14),
    //     ),
    //     title: const Text(
    //       'Accept area?',
    //       style: TextStyle(
    //         color: AppColors.textPrimary,
    //         fontSize: 18,
    //         fontWeight: FontWeight.w700,
    //       ),
    //     ),
    //     content: Text(
    //       'The area will move from $startingCompany '
    //       'to ${widget.companyName} when you confirm.',
    //       style: const TextStyle(
    //         color: AppColors.textSecondary,
    //         fontSize: 13,
    //       ),
    //     ),
    //     actions: [
    //       TextButton(
    //         onPressed: () =>
    //             Navigator.pop(dialogContext, false),
    //         child: const Text('Cancel'),
    //       ),
    //       ElevatedButton(
    //         onPressed: () =>
    //             Navigator.pop(dialogContext, true),
    //         style: ElevatedButton.styleFrom(
    //           backgroundColor: _primaryAccent,
    //           foregroundColor:
    //               const Color(0xFF092537),
    //         ),
    //         child: const Text('Confirm'),
    //       ),
    //     ],
    //   ),
    // );

    // if (!mounted || confirmed != true) return;

    // setState(() => isSubmitting = true);

    // if (!mounted) return;

    // setState(() => isSubmitting = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => AreaAcceptedPage(
          handover: widget.handover,
          companyName: widget.companyName,
        ),
      ),
    );
  }

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor(AppColors.background),
      resizeToAvoidBottomInset: true,

      appBar: CustomAppBar(
        title: 'Accept area',
        subtitle: projectName,
        backgroundColor: context.backgroundColor(AppColors.background),
        onBackPressed: () => Navigator.pop(context),
      ),

      body: ListView(
        padding: const EdgeInsets.fromLTRB(7, 17, 7, 25),
        children: [
          // Area heading
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.surfaceColor(AppColors.surface),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: context.borderColor(AppColors.border),
                  ),
                ),
                child: Icon(
                  Icons.location_on_outlined,
                  color: context.linkColor(_blue),
                  size: 19,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      area,
                      style: TextStyle(
                        color: context.foregroundColor(AppColors.textPrimary),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      '$activityCode · $activityName  ·  Visit $visitNumber',
                      style: TextStyle(
                        color: context.linkColor(_blue),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Taking over from
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 11),
            decoration: BoxDecoration(
              color: context.surfaceColor(AppColors.surface),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.borderColor(AppColors.border)),
            ),
            child: Row(
              children: [
                Text(
                  'Taking over from',
                  style: TextStyle(
                    color: context.linkColor(_blue),
                    fontSize: 12,
                  ),
                ),

                const Spacer(),

                Text(
                  startingCompany,
                  style: TextStyle(
                    color: context.foregroundColor(AppColors.textPrimary),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 15),

          // Taking over check sheet
          Text(
            'Taking over check sheet',
            style: TextStyle(
              color: context.foregroundColor(AppColors.textPrimary),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 7),

          InkWell(
            onTap: openCheckSheet,
            borderRadius: BorderRadius.circular(11),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: context.surfaceColor(AppColors.surface),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: answersSaved
                      ? AppColors.primaryBorder
                      : context.borderColor(AppColors.border),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    height: 34,
                    width: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF244A39),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.assignment_turned_in_outlined,
                      color: context.accentColor(_primaryAccent),
                      size: 20,
                    ),
                  ),

                  const SizedBox(width: 9),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CS-01 · Plastering area check',
                          style: TextStyle(
                            color: context.foregroundColor(
                              AppColors.textPrimary,
                            ),
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          answersSaved
                              ? 'Answers saved'
                              : 'Tap to answer · Required',
                          style: TextStyle(
                            color: answersSaved
                                ? context.accentColor(_primaryAccent)
                                : context.linkColor(_blue),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Icon(
                    answersSaved ? Icons.check : Icons.chevron_right,
                    color: answersSaved ? context.accentColor(_primaryAccent) : context.linkColor(_blue),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 17),

          // Optional note
          Text(
            'Note (optional)',
            style: TextStyle(
              color: context.foregroundColor(AppColors.textPrimary),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 7),

          TextField(
            controller: noteController,
            minLines: 3,
            maxLines: 3,
            style: TextStyle(
              color: context.foregroundColor(AppColors.textPrimary),
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: 'Add a note if needed.',
              hintStyle: TextStyle(
                color: context.linkColor(_blue),
                fontSize: 14,
              ),
              filled: true,
              fillColor: context.backgroundColor(AppColors.background),
              contentPadding: const EdgeInsets.all(12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: context.borderColor(AppColors.border),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: context.accentColor(_primaryAccent), width: 1.5),
              ),
            ),
          ),

          const SizedBox(height: 9),

          // Photos and files
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: context.surfaceColor(AppColors.surface),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: context.borderColor(AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Photos and files',
                    style: TextStyle(
                      color: context.foregroundColor(AppColors.textPrimary),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                SizedBox(
                  height: 43,
                  child: OutlinedButton.icon(
                    onPressed: openAttachmentSheet,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.linkColor(_blue),
                      side: BorderSide(
                        color: context.borderColor(AppColors.border),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Selected attachments
          if (attachments.isNotEmpty) ...[
            const SizedBox(height: 8),

            ...attachments.map((path) {
              final fileName = path.split(RegExp(r'[/\\]')).last;

              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: context.surfaceColor(AppColors.surface),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: context.borderColor(AppColors.border),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.attach_file,
                      color: context.linkColor(_blue),
                      size: 18,
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: Text(
                        fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.foregroundColor(AppColors.textPrimary),
                          fontSize: 12,
                        ),
                      ),
                    ),

                    IconButton(
                      onPressed: () {
                        setState(() {
                          attachments.remove(path);
                        });
                      },
                      icon: const Icon(
                        Icons.close,
                        color: Colors.redAccent,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          const SizedBox(height: 15),

          // Information text
          Text(
            'The area moves to ${widget.companyName} when you confirm.',
            style: TextStyle(color: context.linkColor(_blue), fontSize: 12),
          ),
        ],
      ),

      // Fixed bottom button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(7, 10, 7, 8),
        decoration: BoxDecoration(
          color: context.backgroundColor(AppColors.background),
          border: Border(
            top: BorderSide(
              color: context.borderColor(AppColors.border),
              width: 0.7,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 46,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: answersSaved && !isSubmitting
                  ? confirmAcceptance
                  : null,

              icon: const Icon(Icons.check, size: 17),

              label: Text(
                isSubmitting ? 'Confirming...' : 'Confirm acceptance',
              ),

              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryAccent,
                foregroundColor: const Color(0xFF092537),
                disabledBackgroundColor: const Color(0xFF284853),
                disabledForegroundColor: context.linkColor(_blue),
                elevation: 0,
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AreaAcceptedPage extends StatelessWidget {
  const AreaAcceptedPage({
    super.key,
    required this.handover,
    required this.companyName,
  });

  final Map<String, String> handover;
  final String companyName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor(AppColors.background),
      appBar: CustomAppBar(title: 'Handover saved', subtitle: companyName),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 40, 12, 20),
        children: [
          Center(
            child: Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF214536),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryBorder),
              ),
              child: Icon(
                Icons.check,
                color: context.accentColor(AppColors.primary),
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: 17),
          Text(
            'Area accepted',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.foregroundColor(AppColors.textPrimary),
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Now with $companyName for Plastering.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFA7D3FF), fontSize: 14),
          ),
          const SizedBox(height: 30),
          Text(
            handover['area'] ?? '',
            style: TextStyle(
              color: context.foregroundColor(AppColors.textPrimary),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'PL-01 · Plastering · Visit 1',
            style: TextStyle(color: Color(0xFFA7D3FF), fontSize: 11),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(context, 'accepted');
            },
            child: const Text('View area'),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: SizedBox(
            height: 46,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, 'accepted'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: const Color(0xFF092537),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              child: const Text('Back to handovers'),
            ),
          ),
        ),
      ),
    );
  }
}

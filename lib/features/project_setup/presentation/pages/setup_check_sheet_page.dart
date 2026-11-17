import 'package:dropline/core/theme/app_text_styles.dart';
import 'package:dropline/core/theme/appcolors.dart';
import 'package:dropline/core/utility/widgets/appbar.dart';
import 'package:dropline/features/project_setup/presentation/pages/my_check_sheets_page.dart';
import 'package:flutter/material.dart';

// Add the correct imports for:
// CustomAppBar, AppColors, AppTextStyles,
// and your existing CheckSheetModel.


// Keep your existing imports for:
// AppColors
// AppTextStyles
// CustomAppBar
// CheckSheetModel

class SetupCheckSheetPage extends StatefulWidget {
  const SetupCheckSheetPage({
    super.key,
    required this.sheet,
    required this.companyName,
    this.isEditing = false,
  });

  final CheckSheetModel sheet;
  final String companyName;
  final bool isEditing;

  @override
  State<SetupCheckSheetPage> createState() =>
      _SetupCheckSheetPageState();
}

class _SetupCheckSheetPageState extends State<SetupCheckSheetPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController nameController;

  final TextEditingController pointController =
      TextEditingController();

  final TextEditingController editPointController =
      TextEditingController();

  final FocusNode editFocusNode = FocusNode();

  late List<String> points;
  late List<int> pointIds;

  int nextPointId = 0;
  int? editingPointId;

  bool showPointError = false;
  bool showEditError = false;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(
      text: widget.isEditing ? widget.sheet.title : '',
    );

    points = List<String>.from(
      widget.isEditing ? widget.sheet.points : [],
    );

    pointIds = List<int>.generate(
      points.length,
      (index) => index,
    );

    nextPointId = points.length;
  }

  // Add new checklist point
  void addPoint() {
    final value = pointController.text.trim();

    if (value.isEmpty) {
      setState(() {
        showPointError = true;
      });
      return;
    }

    setState(() {
      points.add(value);
      pointIds.add(nextPointId++);
      showPointError = false;
    });

    pointController.clear();
    FocusScope.of(context).unfocus();
  }

  // Open inline edit panel
  void editPoint(int index) {
    setState(() {
      editingPointId = pointIds[index];
      editPointController.text = points[index];
      showEditError = false;
    });

    editPointController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: editPointController.text.length,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        editFocusNode.requestFocus();
      }
    });
  }

  // Cancel editing
  void cancelEdit() {
    editFocusNode.unfocus();

    setState(() {
      editingPointId = null;
      editPointController.clear();
      showEditError = false;
    });
  }

  // Apply edited point
  void applyEdit() {
    final value = editPointController.text.trim();

    if (value.isEmpty) {
      setState(() {
        showEditError = true;
      });
      return;
    }

    final index = pointIds.indexOf(editingPointId ?? -1);

    if (index == -1) return;

    editFocusNode.unfocus();

    setState(() {
      points[index] = value;
      editingPointId = null;
      editPointController.clear();
      showEditError = false;
    });
  }

  // Remove selected point
  void removeEditingPoint() {
    final index = pointIds.indexOf(editingPointId ?? -1);

    if (index == -1) return;

    editFocusNode.unfocus();

    setState(() {
      points.removeAt(index);
      pointIds.removeAt(index);

      editingPointId = null;
      editPointController.clear();
      showEditError = false;
      showPointError = points.isEmpty;
    });
  }

  // Reorder points using drag handle
  void reorderPoints(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex--;
      }

      final movedPoint = points.removeAt(oldIndex);
      final movedId = pointIds.removeAt(oldIndex);

      points.insert(newIndex, movedPoint);
      pointIds.insert(newIndex, movedId);
    });
  }

  // Save check sheet
  void saveCheckSheet() {
    final isValid = _formKey.currentState?.validate() ?? false;

    setState(() {
      showPointError = points.isEmpty;
    });

    if (!isValid || points.isEmpty) return;

    if (editingPointId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please apply or cancel the point edit first',
          ),
        ),
      );
      return;
    }

    final updatedSheet = CheckSheetModel(
      code: widget.sheet.code,
      title: nameController.text.trim(),
      description: widget.sheet.description,
      isSaved: true,
      points: List<String>.from(points),
    );

    Navigator.pop(context, updatedSheet);
  }

  @override
  void dispose() {
    nameController.dispose();
    pointController.dispose();
    editPointController.dispose();
    editFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,

      appBar: CustomAppBar(
        title: widget.isEditing
            ? 'Edit ${widget.sheet.code}'
            : 'Set up ${widget.sheet.code}',
        subtitle: widget.companyName,
        backgroundColor: AppColors.background,
      ),

      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(11, 17, 11, 20),
          children: [
            // Flow description
            Text(
              widget.sheet.description,
              style: AppTextStyles.custom(
                color: const Color(0xFFB8FF65),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 17),

            // Check sheet name
            Text(
              'Check sheet name',
              style: AppTextStyles.custom(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 7),

            TextFormField(
              controller: nameController,
              autovalidateMode:
                  AutovalidateMode.onUserInteraction,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a check sheet name';
                }
                return null;
              },
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
              decoration: _inputDecoration(
                'e.g. Touch-up area check',
              ),
            ),

            const SizedBox(height: 16),

            // Points to check
            Text(
              'Points to check',
              style: AppTextStyles.custom(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 7),

            // New point input
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: pointController,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => addPoint(),
                    onChanged: (_) {
                      if (showPointError) {
                        setState(() {
                          showPointError = false;
                        });
                      }
                    },
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                    decoration: _inputDecoration('New point'),
                  ),
                ),

                const SizedBox(width: 8),

                SizedBox(
                  height: 46,
                  child: OutlinedButton(
                    onPressed: addPoint,
                    style: _outlinedButtonStyle(),
                    child: const Text(
                      'Add',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            if (showPointError) ...[
              const SizedBox(height: 6),
              Text(
                points.isEmpty
                    ? 'Please add at least one point'
                    : 'Please enter a point',
                style: AppTextStyles.inputError,
              ),
            ],

            // Reorderable points
            if (points.isNotEmpty) ...[
              const SizedBox(height: 12),

              Text(
                'Drag a handle to change the order.',
                style: AppTextStyles.custom(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),

              const SizedBox(height: 11),

              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                onReorder: reorderPoints,
                itemCount: points.length,
                proxyDecorator: (child, index, animation) {
                  return Material(
                    color: Colors.transparent,
                    elevation: 0,
                    child: child,
                  );
                },
                itemBuilder: (context, index) {
                  final pointId = pointIds[index];
                  final isCurrentlyEditing =
                      editingPointId == pointId;

                  return Column(
                    key: ValueKey(pointId),
                    children: [
                      // Point card
                      Container(
                        margin: EdgeInsets.only(
                          bottom: isCurrentlyEditing ? 8 : 8,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Drag handle
                            ReorderableDragStartListener(
                              index: index,
                              child: const SizedBox(
                                height: 42,
                                width: 30,
                                child: Icon(
                                  Icons.drag_indicator,
                                  size: 20,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),

                            const SizedBox(width: 7),

                            Expanded(
                              child: Text(
                                points[index],
                                style: AppTextStyles.custom(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),

                            const SizedBox(width: 8),

                            SizedBox(
                              height: 44,
                              child: OutlinedButton(
                                onPressed: () => editPoint(index),
                                style: _outlinedButtonStyle(),
                                child: const Text(
                                  'Edit',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Inline edit panel
                      if (isCurrentlyEditing)
                        _buildEditPointCard(),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),

      // Fixed bottom save button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 8),
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(
            top: BorderSide(
              color: AppColors.border,
              width: 0.7,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: saveCheckSheet,
              icon: const Icon(
                Icons.check,
                size: 18,
              ),
              label: const Text('Save check sheet'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB5FF60),
                foregroundColor: const Color(0xFF092537),
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

  // Inline edit panel matching screenshot
  Widget _buildEditPointCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Edit point',
            style: AppTextStyles.custom(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 9),

          TextField(
            controller: editPointController,
            focusNode: editFocusNode,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => applyEdit(),
            onChanged: (_) {
              if (showEditError) {
                setState(() {
                  showEditError = false;
                });
              }
            },
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
            ),
            decoration: _inputDecoration(
              'Edit point',
            ).copyWith(
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFB5FF60),
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFB5FF60),
                  width: 1.8,
                ),
              ),
            ),
          ),

          if (showEditError) ...[
            const SizedBox(height: 5),
            Text(
              'Please enter a point',
              style: AppTextStyles.inputError,
            ),
          ],

          const SizedBox(height: 5),

          Row(
            children: [
              // Remove button
              SizedBox(
                height: 43,
                child: OutlinedButton(
                  onPressed: removeEditingPoint,
                  style: _outlinedButtonStyle(),
                  child: const Text(
                    'Remove',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // Cancel button
              SizedBox(
                height: 43,
                child: OutlinedButton(
                  onPressed: cancelEdit,
                  style: _outlinedButtonStyle(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 7),

              // Apply button
              SizedBox(
                height: 43,
                child: OutlinedButton(
                  onPressed: applyEdit,
                  style: _outlinedButtonStyle(),
                  child: const Text(
                    'Apply',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Common outlined button style
  ButtonStyle _outlinedButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: AppColors.textPrimary,
      side: const BorderSide(
        color: AppColors.border,
        width: 1,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  // Common input decoration
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 14,
      ),
      filled: true,
      fillColor: AppColors.background,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 13,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: AppColors.border,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: AppColors.border,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Color(0xFFB5FF60),
          width: 1.5,
        ),
      ),
      errorStyle: AppTextStyles.inputError,
      errorMaxLines: 2,
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: AppColors.error,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: AppColors.error,
        ),
      ),
    );
  }
}

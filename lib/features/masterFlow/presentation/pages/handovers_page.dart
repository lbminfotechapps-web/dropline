import 'dart:convert';

import 'package:dropline/core/theme/appcolors.dart';
import 'package:dropline/core/utility/widgets/appbar.dart';
import 'package:dropline/features/masterFlow/presentation/pages/handover_details_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dropline/core/router/app_router.dart';
import 'select_flow_page.dart';
import '../../data/master_flow_store.dart';

class HandoversPage extends StatefulWidget {
  const HandoversPage({
    super.key,
    required this.projectId,
    required this.companyId,
    required this.projectName,
    required this.companyName,
    this.initialFlow,
  });

  final SavedMasterFlow? initialFlow;
  final String projectId;
  final String companyId;
  final String projectName;
  final String companyName;

  @override
  State<HandoversPage> createState() => _HandoversPageState();
}

class _HandoversPageState extends State<HandoversPage> {
  static const _background = Color(0xFF102633);
  static const _surface = Color(0xFF122C3B);
  static const _border = Color(0xFF2E4D5E);
  static const _muted = Color(0xFF9FBFD1);
  static const _lime = Color(0xFFB5FF65);
  List<Map<String, String>> _handovers = [
    {
      'area': 'Building A › Level 03 › Apartment 305',
      'activity': 'Apartment finishes',
      'trade': 'Plastering',
      'company': 'Apex Build',
      'status': 'waiting',
    },
  ];
  bool _allAreas = true;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  String get _key =>
      'project_handovers_v1:${jsonEncode([widget.projectId.isEmpty ? widget.projectName : widget.projectId, widget.companyId.isEmpty ? widget.companyName : widget.companyId])}';

  @override
  void initState() {
    super.initState();
    _load();
    if (widget.initialFlow != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _startHandover(widget.initialFlow);
      });
    }
  }

  Future<void> _load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = preferences.getString(_key);
      final items = saved == null
          ? <Map<String, String>>[
              {
                'area': 'Building A › Level 03 › Apartment 305',
                'activity': 'Apartment finishes',
                'trade': 'Plastering',
                'company': 'Apex Build',
                'status': 'waiting',
              },
            ]
          : (jsonDecode(saved) as List)
                .map((value) => Map<String, String>.from(value as Map))
                .toList();
      if (mounted) {
        setState(() {
          _handovers = items;
          _loading = false;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Unable to load handovers. Tap to retry.';
        });
      }
    }
  }

  Future<void> _startHandover([SavedMasterFlow? initialFlow]) async {
    final selected =
        initialFlow ??
        await Navigator.of(context).push<SavedMasterFlow>(
          MaterialPageRoute(
            builder: (_) => SelectFlowPage(
              projectId: widget.projectId,
              companyId: widget.companyId,
              projectName: widget.projectName,
              companyName: widget.companyName,
            ),
          ),
        );
    if (!mounted || selected == null) return;
    final form = GlobalKey<FormState>();
    var area = '';
    final activity = selected.name;
    final created = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _surface,
        title: const Text('Choose area', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Area',
                    hintText: 'Building › Level › Apartment',
                    hintStyle: TextStyle(color: _muted),
                    labelStyle: TextStyle(color: _muted),
                  ),
                  onChanged: (value) => area = value.trim(),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter an area'
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  activity,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _lime,
              foregroundColor: _background,
            ),
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.pop(context, {
                  'area': area,
                  'activity': activity,
                  'company': selected.startingCompany.isEmpty
                      ? widget.companyName
                      : selected.startingCompany,
                  'flow': jsonEncode(selected.toJson()),
                  'status': 'waiting',
                });
              }
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
    if (!mounted || created == null) return;
    setState(() => _saving = true);
    try {
      final updated = [..._handovers, created];
      final preferences = await SharedPreferences.getInstance();
      if (!await preferences.setString(_key, jsonEncode(updated))) {
        throw StateError('Save failed');
      }
      if (mounted) setState(() => _handovers = updated);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to save handover. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _viewArea(Map<String, String> handover) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => HandoverDetailsPage(
          handover: handover,
          companyName: widget.companyName,
        ),
      ),
    );

    if (!mounted || result == null) return;

    if (result == 'accepted' || result == 'rejected') {
      final updated = _handovers.map((item) {
        if (identical(item, handover)) {
          return <String, String>{...item, 'status': result};
        }
        return item;
      }).toList();

      try {
        final prefs = await SharedPreferences.getInstance();

        final saved = await prefs.setString(_key, jsonEncode(updated));

        if (!saved) {
          throw StateError('Unable to save status');
        }

        if (!mounted) return;

        setState(() {
          _handovers = updated;
        });
      } catch (_) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to update handover status')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingHandovers = _handovers
        .where((item) => item['status'] == 'waiting')
        .toList();

    final visible = _allAreas ? _handovers : pendingHandovers;

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: CustomAppBar(
        title: 'Handovers',
        subtitle: '${widget.projectName} · ${widget.companyName}',
        backgroundColor: AppColors.background,
        onBackPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRouter.me);
          }
        },
      ),

      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Divider(height: 1, color: _border),

            const SizedBox(height: 13),

            // To do / All areas tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 53,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C2535),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTabButton(
                        title: 'To do',
                        isSelected: !_allAreas,
                        count: pendingHandovers.length,
                        onTap: () {
                          setState(() {
                            _allAreas = false;
                          });
                        },
                      ),
                    ),

                    const SizedBox(width: 5),

                    Expanded(
                      child: _buildTabButton(
                        title: 'All areas',
                        isSelected: _allAreas,
                        onTap: () {
                          setState(() {
                            _allAreas = true;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 17),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: _lime))
                  : _error != null
                  ? Center(
                      child: TextButton(onPressed: _load, child: Text(_error!)),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      children: [
                        // Section heading
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              _allAreas ? 'All areas' : 'To check',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),

                            const SizedBox(width: 6),

                            Text(
                              '${visible.length}',
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        if (visible.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 35),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.assignment_turned_in_outlined,
                                  color: _muted,
                                  size: 38,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _allAreas
                                      ? 'No handovers available'
                                      : 'No handovers to check',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: _muted,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ...visible.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _handoverCard(item),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    int? count,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? _lime : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? const Color(0xFF092537) : Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),

            if (count != null) ...[
              const SizedBox(width: 6),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF94DB56)
                      : const Color(0xFF244354),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: isSelected ? const Color(0xFF092537) : Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _handoverCard(Map<String, String> item) {
    final bool isPending = item['status'] == 'waiting';

    final String area = item['area'] ?? '';
    final String activity = item['activity'] ?? '';
    final String company = item['company'] ?? '';

    // Use the saved trade when available.
    final String trade = item['trade'] ?? 'First handover';

    return Material(
      color: _surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isPending ? const Color(0xFF70AE3E) : _border,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _viewArea(item),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 13, 12, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Area name + status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      area,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        height: 1.35,
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isPending
                            ? const Color(0xFF254A33)
                            : const Color(0xFF244354),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: isPending ? const Color(0xFF4C8447) : _border,
                        ),
                      ),
                      child: Text(
                        isPending ? 'To check' : 'Completed',
                        style: TextStyle(
                          color: isPending ? const Color(0xFFD2FF9D) : _muted,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 5),

              // Activity
              Text(
                activity,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 4),

              // Trade and company
              Text(
                '$trade · With $company',
                style: const TextStyle(
                  color: Color(0xFFA7D3FF),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 12),

              const Divider(height: 1, thickness: 0.7, color: _border),

              // Bottom action
              InkWell(
                onTap: () => _viewArea(item),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          isPending ? 'Check handover' : 'View handover',
                          style: TextStyle(
                            color: isPending
                                ? const Color(0xFFB5FF65)
                                : Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),

                      Icon(
                        Icons.chevron_right_rounded,
                        color: isPending ? const Color(0xFFB5FF65) : _muted,
                        size: 21,
                      ),
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

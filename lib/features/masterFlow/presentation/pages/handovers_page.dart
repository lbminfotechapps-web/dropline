import 'dart:convert';

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
  List<Map<String, String>> _handovers = [];
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
          ? <Map<String, String>>[]
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

  void _viewArea(Map<String, String> handover) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: _surface,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                handover['area']!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                handover['activity']!,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'First handover · With ${handover['company']}',
                style: const TextStyle(color: _muted),
              ),
              const SizedBox(height: 20),
              const Text(
                'Awaiting acceptance',
                style: TextStyle(color: _muted),
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = _handovers
        .where((item) => _allAreas || item['status'] == 'waiting')
        .toList();
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Row(
                children: [
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: IconButton.outlined(
                      tooltip: 'Back to project',
                      onPressed: () => context.canPop()
                          ? context.pop()
                          : context.go(AppRouter.me),
                      style: IconButton.styleFrom(
                        backgroundColor: _surface,
                        foregroundColor: _muted,
                        side: const BorderSide(color: _border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                      ),
                      icon: const Icon(Icons.chevron_left_rounded, size: 22),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Handovers',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.projectName} · ${widget.companyName}',
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _border),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: () => context.push(
                    Uri(
                      path: AppRouter.masterFlow,
                      queryParameters: {
                        'projectId': widget.projectId,
                        'companyId': widget.companyId,
                        'projectName': widget.projectName,
                        'companyName': widget.companyName,
                      },
                    ).toString(),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _muted,
                    side: const BorderSide(color: _border),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.account_tree_outlined, size: 18),
                  label: const Text('Master flows'),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C2230),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  children: [
                    for (final all in [false, true])
                      Expanded(
                        child: TextButton(
                          onPressed: () => setState(() => _allAreas = all),
                          style: TextButton.styleFrom(
                            backgroundColor: _allAreas == all
                                ? _lime
                                : Colors.transparent,
                            foregroundColor: _allAreas == all
                                ? _background
                                : _muted,
                            minimumSize: const Size(0, 44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: Text(all ? 'All areas' : 'To do'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: _lime))
                  : _error != null
                  ? Center(
                      child: TextButton(onPressed: _load, child: Text(_error!)),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Waiting',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${visible.length}',
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (visible.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 28),
                            child: Text(
                              'No handovers yet. Start a handover to add an area.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: _muted, fontSize: 13),
                            ),
                          ),
                        for (final item in visible)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _handoverCard(item),
                          ),
                      ],
                    ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: const BoxDecoration(
                color: _surface,
                border: Border(top: BorderSide(color: _border)),
              ),
              child: SafeArea(
                top: false,
                child: FilledButton.icon(
                  onPressed: _loading || _saving || _error != null
                      ? null
                      : _startHandover,
                  style: FilledButton.styleFrom(
                    backgroundColor: _lime,
                    foregroundColor: _background,
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  icon: const Icon(Icons.add, size: 20),
                  label: Text(_saving ? 'Saving…' : 'Start handover'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _handoverCard(Map<String, String> item) => Material(
    color: _surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: _border),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => _viewArea(item),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item['area']!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF173545),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _border),
                  ),
                  child: const Text(
                    'Awaiting acceptance',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item['activity']!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'First handover · With ${item['company']}',
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: _border),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'View area',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 20, color: _muted),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

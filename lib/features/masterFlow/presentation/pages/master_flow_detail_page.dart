import 'package:dropline/core/theme/appcolors.dart';
import 'package:dropline/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

import '../../data/master_flow_store.dart';
import 'handovers_page.dart';
import 'master_flow.dart';

class MasterFlowDetailPage extends StatefulWidget {
  const MasterFlowDetailPage({
    super.key,
    required this.flow,
    required this.projectId,
    required this.companyId,
    required this.projectName,
    required this.companyName,
  });

  final SavedMasterFlow flow;
  final String projectId;
  final String companyId;
  final String projectName;
  final String companyName;

  @override
  State<MasterFlowDetailPage> createState() => _MasterFlowDetailPageState();
}

class _MasterFlowDetailPageState extends State<MasterFlowDetailPage> {
  late SavedMasterFlow _flow = widget.flow;

  Future<void> _edit() async {
    final name = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => CreateMasterFlowScreen(
          initialFlow: _flow,
          projectId: widget.projectId,
          companyId: widget.companyId,
          projectName: widget.projectName,
          companyName: widget.companyName,
        ),
      ),
    );
    if (!mounted || name == null) return;
    try {
      final flows = await MasterFlowStore(
        project: widget.projectId.isEmpty
            ? widget.projectName
            : widget.projectId,
        company: widget.companyId.isEmpty
            ? widget.companyName
            : widget.companyId,
      ).load();
      if (mounted) {
        setState(() => _flow = flows.firstWhere((f) => f.name == name));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to refresh flow. Reopen to retry.'),
          ),
        );
      }
    }
  }

  Widget _card(Widget child, {Color? color}) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: color ?? context.surfaceColor(const Color(0xFF122C3B)),
      border: Border.all(color: context.borderColor(borderColor)),
      borderRadius: BorderRadius.circular(11),
    ),
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    final visits = <String, int>{};
    final visitNumbers = _flow.activities.map((activity) {
      final company = activity['company'] ?? '';
      return visits.update(company, (value) => value + 1, ifAbsent: () => 1);
    }).toList();
    // Setup status is optional in older saved flows.
    final setupCount = _flow.activities
        .where((a) => a['needsSetup'] == 'true')
        .length;
    return Scaffold(
      backgroundColor: context.backgroundColor(bgColor),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                children: [
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: IconButton.outlined(
                      tooltip: 'Back to master flows',
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        foregroundColor: context.mutedColor(mutedColor),
                        backgroundColor: context.surfaceColor(cardColor),
                        side: BorderSide(
                          color: context.borderColor(borderColor),
                        ),
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
                        Text(
                          _flow.name,
                          style: TextStyle(
                            color: context.foregroundColor(Colors.white),
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.8,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Master flow${_flow.reference.isEmpty ? '' : ' · Ref ${_flow.reference}'}',
                          style: TextStyle(
                            color: context.mutedColor(mutedColor),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _edit,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.accentColor(AppColors.primarySoft),
                      minimumSize: const Size(68, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      side: BorderSide(color: context.accentColor(AppColors.primaryBorder)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                    child: const Text(
                      'Edit flow',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: context.borderColor(borderColor)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  Text(
                    'The flow numbers each check sheet and sends it to the right company for setup.',
                    style: TextStyle(
                      color: context.mutedColor(mutedColor),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _card(
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: const Color(0xFF20413E),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.sync_alt,
                            color: context.accentColor(accentColor),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'FIRST HANDOVER',
                                style: TextStyle(
                                  color: context.mutedColor(mutedColor),
                                  fontSize: 10,
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text:
                                          '${_flow.senderCompany.isEmpty ? widget.companyName : _flow.senderCompany} → ',
                                    ),
                                    TextSpan(
                                      text: _flow.startingCompany.isEmpty
                                          ? 'Unassigned company'
                                          : _flow.startingCompany,
                                      style: TextStyle(
                                        color: context.accentColor(AppColors.primarySoft),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                style: TextStyle(
                                  color: context.foregroundColor(Colors.white),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    color: context.surfaceColor(cardColor),
                  ),
                  const SizedBox(height: 12),
                  for (final entry in _flow.activities.indexed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: _card(
                        Row(
                          children: [
                            Container(
                              width: 31,
                              height: 31,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A3849),
                                border: Border.all(
                                  color: context.borderColor(borderColor),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${entry.$1 + 1}',
                                style: TextStyle(
                                  color: context.mutedColor(mutedColor),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.$2['name'] ?? '',
                                    style: TextStyle(
                                      color: context.foregroundColor(
                                        Colors.white,
                                      ),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${entry.$2['reference'] ?? ''} · ${entry.$2['company'] ?? 'Unassigned company'} · Visit ${visitNumbers[entry.$1]}',
                                    style: TextStyle(
                                      color: context.mutedColor(mutedColor),
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'In CS-${(entry.$1 * 2 + 1).toString().padLeft(2, '0')} · Out CS-${(entry.$1 * 2 + 2).toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      color: context.accentColor(AppColors.primarySoft),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (setupCount > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '$setupCount ${setupCount == 1 ? 'sheet needs' : 'sheets need'} setup by the assigned company.',
                      style: TextStyle(
                        color: context.mutedColor(mutedColor),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: context.borderColor(borderColor)),
                ),
              ),
              child: SafeArea(
                top: false,
                child: FilledButton.icon(
                  onPressed: _flow.activities.isEmpty
                      ? null
                      : () => Navigator.of(context).push<void>(
                          MaterialPageRoute(
                            builder: (_) => HandoversPage(
                              projectId: widget.projectId,
                              companyId: widget.companyId,
                              projectName: widget.projectName,
                              companyName: widget.companyName,
                              initialFlow: _flow,
                            ),
                          ),
                        ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: bgColor,
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                  icon: const Icon(Icons.sync_alt, size: 18),
                  label: const Text(
                    'Use this flow',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
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

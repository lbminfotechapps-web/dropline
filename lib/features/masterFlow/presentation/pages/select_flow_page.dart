import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:dropline/core/router/app_router.dart';
import '../../data/master_flow_store.dart';

class SelectFlowPage extends StatefulWidget {
  const SelectFlowPage({
    super.key,
    required this.projectId,
    required this.companyId,
    required this.projectName,
    required this.companyName,
  });

  final String projectId;
  final String companyId;
  final String projectName;
  final String companyName;

  @override
  State<SelectFlowPage> createState() => _SelectFlowPageState();
}

class _SelectFlowPageState extends State<SelectFlowPage> {
  static const _background = Color(0xFF102633);
  static const _border = Color(0xFF2E4D5E);
  static const _muted = Color(0xFF9FBFD1);
  List<SavedMasterFlow> _flows = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
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
        setState(() {
          _flows = flows;
          _loading = false;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Unable to load saved flows. Tap to retry.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _createFlow() async {
    await context.push(
      Uri(
        path: AppRouter.masterFlow,
        queryParameters: {
          'projectId': widget.projectId,
          'companyId': widget.companyId,
          'projectName': widget.projectName,
          'companyName': widget.companyName,
        },
      ).toString(),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
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
                    tooltip: 'Back to handovers',
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(
                      foregroundColor: _muted,
                      backgroundColor: const Color(0xFF153142),
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
                        'Select flow',
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
                        widget.projectName,
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
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF233F36),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF5E8249)),
                        ),
                        child: const Text(
                          '1. Flow',
                          style: TextStyle(
                            color: Color(0xFFD2F4AD),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 9),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: _muted,
                        ),
                      ),
                      const Text(
                        '2. Area',
                        style: TextStyle(
                          color: _muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 9),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: _muted,
                        ),
                      ),
                      const Text(
                        '3. Send',
                        style: TextStyle(
                          color: _muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Which saved flow do you want to start?',
                  style: TextStyle(color: _muted, fontSize: 12),
                ),
                const SizedBox(height: 14),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null)
                  TextButton(onPressed: _load, child: Text(_error!))
                else if (_flows.isEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No saved flows yet.',
                      style: TextStyle(color: _muted),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _createFlow,
                    icon: const Icon(Icons.add),
                    label: const Text('Create master flow'),
                  ),
                ] else
                  for (final flow in _flows)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Material(
                        color: const Color(0xFF102734),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                          side: const BorderSide(color: _border),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => Navigator.pop(context, flow),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.account_tree_outlined,
                                  size: 18,
                                  color: _muted,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        flow.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${flow.startingCompany.isEmpty ? 'Unassigned company' : '${flow.startingCompany} starts'} · ${flow.activities.length} ${flow.activities.length == 1 ? 'activity' : 'activities'}',
                                        style: const TextStyle(
                                          color: _muted,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  size: 20,
                                  color: _muted,
                                ),
                              ],
                            ),
                          ),
                        ),
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

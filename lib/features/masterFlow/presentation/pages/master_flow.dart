import 'package:flutter/material.dart';
import '../../data/master_flow_store.dart';
import 'master_flow_detail_page.dart';
import 'package:dropline/core/di/global_di.dart';
import 'package:dropline/features/companies/domain/usecase/get_sub_companies_usecase.dart';

const bgColor = Color(0xFF102633);
const cardColor = Color(0xFF142F3E);
const borderColor = Color(0xFF345464);
const mutedColor = Color(0xFFA5C3D3);
const accentColor = Color(0xFFB5FF65);

class MasterFlowsScreen extends StatefulWidget {
  const MasterFlowsScreen({
    super.key,
    this.projectId = '',
    this.companyId = '',
    this.projectName = 'Laxmi Gauri',
    this.companyName = 'Apex Build',
  });
  final String projectId;
  final String companyId;
  final String projectName;
  final String companyName;

  @override
  State<MasterFlowsScreen> createState() => _MasterFlowsScreenState();
}

class _MasterFlowsScreenState extends State<MasterFlowsScreen> {
  final List<SavedMasterFlow> flows = [];
  bool _loadingFlows = true;

  String? _loadError;

  MasterFlowStore get _store => MasterFlowStore(
    project: widget.projectId.isEmpty ? widget.projectName : widget.projectId,
    company: widget.companyId.isEmpty ? widget.companyName : widget.companyId,
  );

  @override
  void initState() {
    super.initState();
    _loadFlows();
  }

  Future<void> _loadFlows() async {
    try {
      final saved = await _store.load();
      if (mounted) {
        setState(() {
          flows
            ..clear()
            ..addAll(saved);
          _loadingFlows = false;
          _loadError = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadError = 'Unable to load saved flows. Retry.';
          _loadingFlows = false;
        });
      }
    }
  }

  Future<void> _createFlow([SavedMasterFlow? flow]) async {
    await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateMasterFlowScreen(
          projectId: widget.projectId,
          companyId: widget.companyId,
          projectName: widget.projectName,
          companyName: widget.companyName,
          initialFlow: flow,
        ),
      ),
    );
    if (mounted) await _loadFlows();
  }

  Future<void> _openFlow(SavedMasterFlow flow) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => MasterFlowDetailPage(
          flow: flow,
          projectId: widget.projectId,
          companyId: widget.companyId,
          projectName: widget.projectName,
          companyName: widget.companyName,
        ),
      ),
    );
    if (mounted) await _loadFlows();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: bgColor,
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
                    tooltip: 'Back to project',
                    onPressed: () => Navigator.maybePop(context),
                    style: IconButton.styleFrom(
                      foregroundColor: mutedColor,
                      backgroundColor: cardColor,
                      side: const BorderSide(color: borderColor),
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
                        'Master flows',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.8,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.projectName,
                        style: const TextStyle(
                          color: mutedColor,
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
          const Divider(height: 1, color: borderColor),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadFlows,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                children: [
                  const Text(
                    'Set the trade order once. Use it whenever an area is ready.',
                    style: TextStyle(
                      color: mutedColor,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_loadingFlows)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: CircularProgressIndicator(color: accentColor),
                      ),
                    )
                  else if (_loadError != null)
                    TextButton(onPressed: _loadFlows, child: Text(_loadError!))
                  else if (flows.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'No saved flows yet. Create your first master flow below.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: mutedColor, fontSize: 13),
                      ),
                    )
                  else
                    for (final flow in flows)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Material(
                          color: const Color(0xFF102734),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11),
                            side: const BorderSide(color: borderColor),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => _openFlow(flow),
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
                                    color: mutedColor,
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
                                            color: mutedColor,
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
                                    color: mutedColor,
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
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: SafeArea(
              top: false,
              child: FilledButton.icon(
                onPressed: () => _createFlow(),
                style: FilledButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: bgColor,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                icon: const Icon(Icons.add, size: 20),
                label: const Text(
                  'New master flow',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class ActivityControllers {
  ActivityControllers(String initialReference)
    : reference = TextEditingController(text: initialReference);
  final name = TextEditingController();
  final TextEditingController reference;
  String? company;

  void dispose() {
    name.dispose();
    reference.dispose();
  }
}

class CreateMasterFlowScreen extends StatefulWidget {
  const CreateMasterFlowScreen({
    super.key,
    this.projectId = '',
    this.companyId = '',
    this.projectName = 'Laxmi Gauri',
    this.companyName = 'Apex Build',
    this.tradeCompanies,
    this.initialFlow,
  });
  final String projectId;
  final String companyId;
  final String projectName;
  final String companyName;
  final List<String>? tradeCompanies;
  final SavedMasterFlow? initialFlow;

  @override
  State<CreateMasterFlowScreen> createState() => _CreateMasterFlowScreenState();
}

class _CreateMasterFlowScreenState extends State<CreateMasterFlowScreen> {
  final _formKey = GlobalKey<FormState>();
  final _flowName = TextEditingController();
  final _flowReference = TextEditingController();
  final _scroll = ScrollController();
  final List<ActivityControllers> activities = [ActivityControllers('ACT-01')];
  List<String> _companies = [];
  bool _loadingCompanies = true;
  String? _companyError;
  bool _saving = false;
  int _nextReference = 2;

  bool get _complete =>
      _flowName.text.trim().isNotEmpty &&
      activities.every(
        (activity) =>
            activity.name.text.trim().isNotEmpty &&
            activity.company != null &&
            activity.reference.text.trim().isNotEmpty,
      );

  @override
  void initState() {
    super.initState();
    final flow = widget.initialFlow;
    if (flow != null) {
      _flowName.text = flow.name;
      _flowReference.text = flow.reference;
      for (final activity in activities) {
        activity.dispose();
      }
      activities.clear();
      for (final item in flow.activities) {
        final activity = ActivityControllers(item['reference'] ?? '');
        activity.name.text = item['name'] ?? '';
        activity.company = item['company'];
        activities.add(activity);
      }
      if (activities.isEmpty) activities.add(ActivityControllers('ACT-01'));
      _nextReference = activities.length + 1;
      _companies = activities
          .map((item) => item.company)
          .whereType<String>()
          .toSet()
          .toList();
    }
    _loadCompanies();
  }

  Future<void> _loadCompanies() async {
    if (widget.tradeCompanies != null) {
      _companies = {..._companies, ...widget.tradeCompanies!}.toList();
      _loadingCompanies = false;
      return;
    }
    if (!sl.isRegistered<GetSubCompaniesUsecase>()) {
      _loadingCompanies = false;
      return;
    }
    setState(() {
      _loadingCompanies = true;
      _companyError = null;
    });
    try {
      final companies = await sl<GetSubCompaniesUsecase>()(
        projectId: widget.projectId,
        companyId: widget.companyId,
      );
      if (mounted) {
        setState(() {
          _companies = companies
              .map((company) => company.subCompanyName.trim())
              .where((name) => name.isNotEmpty)
              .toSet()
              .toList();
          _loadingCompanies = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingCompanies = false;
          _companyError = 'Unable to load trade companies. Retry';
        });
      }
    }
  }

  void _addActivity() {
    setState(
      () => activities.add(
        ActivityControllers(
          'ACT-${(_nextReference++).toString().padLeft(2, '0')}',
        ),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _removeActivity(int index) {
    if (_saving || activities.length == 1) return;
    final removed = activities[index];
    setState(() => activities.removeAt(index));
    WidgetsBinding.instance.addPostFrameCallback((_) => removed.dispose());
  }

  void _moveActivity(int index, int direction) {
    if (_saving) return;
    final target = index + direction;
    if (target < 0 || target >= activities.length) return;
    setState(() {
      final activity = activities.removeAt(index);
      activities.insert(target, activity);
    });
  }

  Future<void> _save() async {
    if (_saving || !_complete || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      await MasterFlowStore(
        project: widget.projectId.isEmpty
            ? widget.projectName
            : widget.projectId,
        company: widget.companyId.isEmpty
            ? widget.companyName
            : widget.companyId,
      ).save(
        SavedMasterFlow(
          name: _flowName.text.trim(),
          reference: _flowReference.text.trim(),
          senderCompany: widget.companyName,
          activities: activities
              .map(
                (activity) => {
                  'name': activity.name.text.trim(),
                  'reference': activity.reference.text.trim(),
                  'company': activity.company!,
                },
              )
              .toList(),
        ),
        previousName: widget.initialFlow?.name,
      );
      if (mounted) Navigator.pop(context, _flowName.text.trim());
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to save flow. Please try again.'),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _flowName.dispose();
    _flowReference.dispose();
    _scroll.dispose();
    for (final activity in activities) {
      activity.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: Form(
          key: _formKey,
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
                        onPressed: _saving
                            ? null
                            : () => Navigator.maybePop(context),
                        style: IconButton.styleFrom(
                          foregroundColor: mutedColor,
                          backgroundColor: cardColor,
                          side: const BorderSide(color: borderColor),
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
                            widget.initialFlow == null
                                ? 'New master flow'
                                : 'Edit master flow',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.8,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.projectName,
                            style: const TextStyle(
                              color: mutedColor,
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
              const Divider(height: 1, color: borderColor),
              Expanded(
                child: Scrollbar(
                  controller: _scroll,
                  thumbVisibility: true,
                  child: ListView(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 14, 24, 20),
                    children: [
                      const Text(
                        'Add the activities and companies. The flow creates the numbered check sheets when you save.',
                        style: TextStyle(
                          color: mutedColor,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 7,
                            child: _labeled(
                              'Flow name',
                              _field(
                                _flowName,
                                'Apartment finishes',
                                requiredField: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 4,
                            child: _labeled(
                              'Reference',
                              _field(_flowReference, 'AF'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.sync_alt_rounded,
                                size: 18,
                                color: accentColor,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'FIRST HANDOVER',
                                    style: TextStyle(
                                      color: mutedColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: '${widget.companyName} → ',
                                        ),
                                        const TextSpan(
                                          text: 'First trade',
                                          style: TextStyle(
                                            color: Color(0xFFD5F69A),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Trade activities',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'After ${widget.companyName} sends the first handover, each trade passes the area directly to the next.',
                        style: const TextStyle(
                          color: mutedColor,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_loadingCompanies)
                        const LinearProgressIndicator(color: accentColor),
                      if (_companyError != null)
                        TextButton(
                          onPressed: _loadCompanies,
                          child: Text(_companyError!),
                        ),
                      if (!_loadingCompanies &&
                          _companyError == null &&
                          _companies.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: Text(
                            'Add trade companies in Companies & people before saving a flow.',
                            style: TextStyle(color: mutedColor, fontSize: 12),
                          ),
                        ),
                      for (var index = 0; index < activities.length; index++)
                        _activityCard(index),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _saving ? null : _addActivity,
                          style: TextButton.styleFrom(
                            foregroundColor: accentColor,
                            padding: EdgeInsets.zero,
                          ),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text(
                            'Add activity',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: borderColor)),
                ),
                child: SafeArea(
                  top: false,
                  child: FilledButton.icon(
                    onPressed: _complete && !_saving ? _save : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: bgColor,
                      disabledBackgroundColor: const Color(0xFF213E48),
                      disabledForegroundColor: const Color(0xFFA6BEC4),
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                    icon: const Icon(Icons.check, size: 17),
                    label: Text(
                      _saving ? 'Saving…' : 'Save master flow',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _labeled(String label, Widget field) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: mutedColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 6),
      field,
    ],
  );

  Widget _field(
    TextEditingController controller,
    String hint, {
    bool requiredField = false,
  }) => TextFormField(
    controller: controller,
    enabled: !_saving,
    style: const TextStyle(color: Colors.white, fontSize: 14),
    decoration: _decoration(hint),
    onChanged: (_) => setState(() {}),
    validator: requiredField
        ? (value) => value == null || value.trim().isEmpty ? 'Required' : null
        : null,
  );

  Widget _activityCard(int index) {
    final activity = activities[index];
    return Container(
      key: ObjectKey(activity),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: mutedColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Activity ${index + 1}',
                  style: const TextStyle(
                    color: mutedColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _activityAction(
                'Move activity ${index + 1} up',
                Icons.keyboard_arrow_up_rounded,
                index > 0 && !_saving ? () => _moveActivity(index, -1) : null,
              ),
              _activityAction(
                'Move activity ${index + 1} down',
                Icons.keyboard_arrow_down_rounded,
                index < activities.length - 1 && !_saving
                    ? () => _moveActivity(index, 1)
                    : null,
              ),
              _activityAction(
                'Remove activity ${index + 1}',
                Icons.close_rounded,
                activities.length > 1 && !_saving
                    ? () => _removeActivity(index)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 7,
                child: _labeled(
                  'Activity',
                  _field(activity.name, 'e.g. Plastering', requiredField: true),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 4,
                child: _labeled(
                  'Activity ref',
                  _field(activity.reference, 'ACT-01', requiredField: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _labeled(
            'Trade company',
            DropdownButtonFormField<String>(
              key: ValueKey(
                '${identityHashCode(activity)}:${activity.company}',
              ),
              initialValue: activity.company,
              isExpanded: true,
              dropdownColor: cardColor,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: mutedColor,
                size: 20,
              ),
              decoration: _decoration('Select trade company'),
              items: _companies
                  .map(
                    (company) => DropdownMenuItem(
                      value: company,
                      child: Text(
                        company,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: _saving || _loadingCompanies
                  ? null
                  : (value) => setState(() => activity.company = value),
              validator: (value) =>
                  value == null ? 'Select trade company' : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _activityAction(String label, IconData icon, VoidCallback? onTap) =>
      IconButton(
        tooltip: label,
        onPressed: onTap,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 36),
        padding: const EdgeInsets.all(4),
        icon: Icon(icon, size: 18),
        color: mutedColor,
        disabledColor: mutedColor.withValues(alpha: 0.3),
        visualDensity: VisualDensity.compact,
      );
}

InputDecoration _decoration(String hint) {
  return InputDecoration(
    hintText: hint,
    labelStyle: TextStyle(color: Colors.white),
    hintStyle: const TextStyle(color: mutedColor, fontSize: 12),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(7),
      borderSide: const BorderSide(color: borderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(7),
      borderSide: const BorderSide(color: accentColor),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(7),
      borderSide: const BorderSide(color: Colors.redAccent),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(7),
      borderSide: const BorderSide(color: Colors.redAccent),
    ),
  );
}

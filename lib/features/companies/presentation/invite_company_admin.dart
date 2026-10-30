import 'dart:async';
import 'package:dropline/core/di/global_di.dart';
import 'package:dropline/core/secure_storage/secure_storage.dart';
import '../domain/entities/company_admin_entity.dart';
import 'bloc/company_admin_bloc.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:dropline/core/api_constant/api_client.dart';
import 'package:dropline/core/api_constant/dio_client.dart';
import 'package:flutter/material.dart';
import 'invitation_ready.dart';

class InviteCompanyAdminPage extends StatefulWidget {
  const InviteCompanyAdminPage({
    super.key,
    this.companyId = '',
    this.projectId = '',
    this.subCompanyId = '',
    this.fld_subcom_admin_det_id = '',
    this.companyName = 'PlasterCo',
    this.projectName = 'Laxmi Gauri',
  });

  final String companyId, projectId, subCompanyId, fld_subcom_admin_det_id;
  final String companyName;
  final String projectName;

  @override
  State<InviteCompanyAdminPage> createState() => _InviteCompanyAdminPageState();
}

class _InviteCompanyAdminPageState extends State<InviteCompanyAdminPage> {
  static const _background = Color(0xFF03283B);
  static const _surface = Color(0xFF0B2E44);
  static const _border = Color(0xFF264C63);
  static const _muted = Color(0xFF80B2CD);
  static const _text = Color(0xFFE9F2F8);
  static const _lime = Color(0xFFB5FF65);
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController(text: '');
  final _mobile = TextEditingController();
  final Map<String, bool> _permissions = {};
  List<Map<String, String>> _roles = [];
  List<Map<String, String>> _tasks = [];
  String? _roleId;
  bool _loadingRoles = true;
  bool _loadingTasks = false;
  String? _roleError;
  String? _taskError;
  int _taskRequest = 0;
  late final CompanyAdminBloc _adminBloc;
  StreamSubscription<CompanyAdminState>? _adminSubscription;
  bool _saving = false;

  Future<void> _submitAdmin() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final userId = await sl<SecureStorage>().getUserId();
      if (!mounted) return;
      if (userId.isEmpty ||
          widget.projectId.isEmpty ||
          widget.subCompanyId.isEmpty) {
        throw Exception(
          'Missing project or subcompany details. Reopen the subcompany from the list.',
        );
      }
      _adminBloc.add(
        SubmitCompanyAdminEvent(
          CompanyAdminRequest(
            loginUserId: userId,
            companyId: widget.companyId,
            projectId: widget.projectId,
            subCompanyId: widget.subCompanyId,
            fld_subcom_admin_det_id: widget.fld_subcom_admin_det_id,
            name: _name.text.trim(),
            mobile: _mobile.text.trim(),
            roleId: _roleId!,
            tasks: _permissions,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  void _onAdminState(CompanyAdminState state) {
    if (!mounted) return;
    if (state.error != null) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(state.error!)));
    } else if (state.admin != null) {
      setState(() => _saving = false);
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => InvitationReadyPage(
            admin: state.admin,
            adminName: state.admin!.name,
            companyName: widget.companyName,
            projectName: widget.projectName,
          ),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _adminBloc = sl<CompanyAdminBloc>();
    _adminSubscription = _adminBloc.stream.listen(_onAdminState);
    _loadRoles();
  }

  Future<List<Map<String, String>>> _fetchOptions(
    String endpoint,
    String idKey,
    String nameKey, {
    String? roleId,
  }) async {
    final response = await DioClient().client.post(
      endpoint,
      data: roleId == null ? null : FormData.fromMap({'role_id': roleId}),
    );
    final dynamic data = response.data is String
        ? jsonDecode(response.data as String)
        : response.data;
    if (data is! Map) throw const FormatException('Invalid response');
    if (data['status'] != true) {
      throw Exception(data['message'] ?? 'Unable to load options');
    }
    final dynamic result = data['result'];
    if (result is! List) throw const FormatException('Invalid options list');
    final options = <String, Map<String, String>>{};
    for (final item in result) {
      if (item is! Map) throw const FormatException('Invalid option');
      final id = item[idKey]?.toString() ?? '';
      final name = item[nameKey]?.toString() ?? '';
      if (id.isNotEmpty && name.isNotEmpty) {
        options[id] = {'id': id, 'name': name};
      }
    }
    return options.values.toList();
  }

  Future<void> _loadRoles() async {
    setState(() {
      _loadingRoles = true;
      _roleError = null;
    });
    try {
      final roles = await _fetchOptions(
        ApiClient.get_role,
        'fld_role_id',
        'fld_role_name',
      );
      if (!mounted) return;
      setState(() {
        _roles = roles;
        _loadingRoles = false;
      });
    } catch (error) {
      debugPrint('Load roles failed: $error');
      if (!mounted) return;
      setState(() {
        _loadingRoles = false;
        _roleError = 'Unable to load roles';
      });
    }
  }

  Future<void> _loadTasks(String roleId) async {
    final request = ++_taskRequest;
    setState(() {
      _roleId = roleId;
      _tasks = [];
      _permissions.clear();
      _loadingTasks = true;
      _taskError = null;
    });
    try {
      final tasks = await _fetchOptions(
        ApiClient.get_role_task_define,
        'fld_role_task_define_id',
        'fld_role_task_name',
        roleId: roleId,
      );
      if (!mounted || request != _taskRequest) return;
      setState(() {
        _tasks = tasks;
        for (final task in tasks) {
          _permissions[task['id']!] = true;
        }
        _loadingTasks = false;
      });
    } catch (error) {
      debugPrint('Load role tasks failed: $error');
      if (!mounted || request != _taskRequest) return;
      setState(() {
        _loadingTasks = false;
        _taskError = 'Unable to load role tasks';
      });
    }
  }

  @override
  void dispose() {
    _adminSubscription?.cancel();
    _adminBloc.close();
    _name.dispose();
    _mobile.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final s = constraints.maxWidth / 210;
            Text label(
              String value, {
              double size = 7,
              Color color = _text,
              bool bold = false,
            }) => Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: size * s,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              ),
            );
            BoxDecoration panel() => BoxDecoration(
              color: _surface,
              border: Border.all(color: _border),
              borderRadius: BorderRadius.circular(5 * s),
            );
            OutlineInputBorder border(Color color) => OutlineInputBorder(
              borderRadius: BorderRadius.circular(5 * s),
              borderSide: BorderSide(color: color),
            );
            Widget field(
              String title,
              TextEditingController controller, {
              bool phone = false,
            }) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                label(title, size: 6.5, color: _muted),
                SizedBox(height: 3 * s),
                TextFormField(
                  controller: controller,
                  keyboardType: phone
                      ? TextInputType.phone
                      : TextInputType.name,
                  textCapitalization: phone
                      ? TextCapitalization.none
                      : TextCapitalization.words,
                  style: TextStyle(color: _text, fontSize: 8 * s),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Required' : null,
                  decoration: InputDecoration(
                    hintText: phone ? '+91 *******88888' : 'Amit Desai',
                    hintStyle: TextStyle(
                      color: _muted.withValues(alpha: 0.55),
                      fontSize: 8 * s,
                    ),
                    filled: true,
                    fillColor: _surface,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8 * s,
                      vertical: 8 * s,
                    ),
                    enabledBorder: border(_border),
                    focusedBorder: border(_muted),
                    errorBorder: border(Colors.redAccent),
                    focusedErrorBorder: border(Colors.redAccent),
                  ),
                ),
              ],
            );
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(10 * s, 8 * s, 10 * s, 18 * s),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 22 * s,
                          height: 22 * s,
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).maybePop(),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              side: const BorderSide(color: _border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5 * s),
                              ),
                            ),
                            child: Icon(
                              Icons.chevron_left,
                              color: _muted,
                              size: 12 * s,
                            ),
                          ),
                        ),
                        SizedBox(width: 8 * s),
                        Expanded(
                          child: label(
                            'Invite company admin',
                            size: 12,
                            bold: true,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10 * s),
                    Container(
                      padding: EdgeInsets.all(8 * s),
                      decoration: panel(),
                      child: Row(
                        children: [
                          Icon(
                            Icons.apartment_outlined,
                            color: _muted,
                            size: 19 * s,
                          ),
                          SizedBox(width: 10 * s),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                label(widget.companyName, size: 8, bold: true),
                                SizedBox(height: 2 * s),
                                label(
                                  widget.projectName,
                                  size: 6.5,
                                  color: _muted,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 11 * s),
                    field('Full name', _name),
                    SizedBox(height: 11 * s),
                    field('Mobile number', _mobile, phone: true),
                    SizedBox(height: 11 * s),
                    label('Role', size: 6.5, color: _muted),
                    SizedBox(height: 3 * s),
                    DropdownButtonFormField<String>(
                      initialValue: _roleId,
                      isExpanded: true,
                      hint: Text(
                        _loadingRoles ? 'Loading roles…' : 'Select role',
                        style: const TextStyle(color: Colors.white),
                      ),
                      validator: (value) =>
                          value == null ? 'Select a role' : null,
                      dropdownColor: _surface,
                      style: TextStyle(color: Colors.white, fontSize: 8 * s),
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: _muted,
                        size: 13 * s,
                      ),
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.person_outline,
                          color: _muted,
                          size: 14 * s,
                        ),
                        prefixIconConstraints: BoxConstraints(minWidth: 29 * s),
                        isDense: true,
                        filled: true,
                        fillColor: _surface,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 7 * s,
                          vertical: 8 * s,
                        ),
                        enabledBorder: border(_border),
                        focusedBorder: border(_muted),
                      ),
                      items: _roles
                          .map(
                            (role) => DropdownMenuItem(
                              value: role['id'],
                              child: Text(
                                role['name']!,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: _loadingRoles || _roles.isEmpty
                          ? null
                          : (value) {
                              if (value != null) _loadTasks(value);
                            },
                    ),
                    if (_roleError != null)
                      TextButton(
                        onPressed: _loadRoles,
                        child: Text('$_roleError · Retry'),
                      ),
                    if (!_loadingRoles && _roleError == null && _roles.isEmpty)
                      label('No roles available', color: _muted),
                    SizedBox(height: 11 * s),
                    Container(
                      padding: EdgeInsets.all(11 * s),
                      decoration: panel(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          label(
                            'Can manage ${widget.companyName}',
                            size: 10,
                            bold: true,
                          ),
                          SizedBox(height: 4 * s),
                          if (_loadingTasks)
                            const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          if (_taskError != null)
                            TextButton(
                              onPressed: () => _loadTasks(_roleId!),
                              child: Text('$_taskError · Retry'),
                            ),
                          if (!_loadingTasks &&
                              _taskError == null &&
                              _tasks.isEmpty)
                            label(
                              _roleId == null
                                  ? 'Select a role to view tasks'
                                  : 'No tasks defined for this role',
                              color: _muted,
                            ),
                          for (final task in _tasks)
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 4 * s),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: label(
                                      task['name']!,
                                      size: 7,
                                      color: _muted,
                                    ),
                                  ),
                                  SizedBox(width: 6 * s),
                                  SizedBox(
                                    width: 25 * s,
                                    height: 16 * s,
                                    child: FittedBox(
                                      child: Switch(
                                        value: _permissions[task['id']]!,
                                        onChanged: (value) => setState(
                                          () =>
                                              _permissions[task['id']!] = value,
                                        ),
                                        activeThumbColor: Colors.white,
                                        activeTrackColor: _lime,
                                        inactiveThumbColor: _text,
                                        inactiveTrackColor: _border,
                                        trackOutlineColor:
                                            const WidgetStatePropertyAll(
                                              Colors.transparent,
                                            ),
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Divider(color: _border, height: 17 * s),
                          label(
                            'Access is for ${widget.companyName} on this project.',
                            size: 6.5,
                            color: _muted,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 15 * s),
                    SizedBox(
                      height: 28 * s,
                      child: FilledButton(
                        onPressed:
                            _saving ||
                                _loadingRoles ||
                                _loadingTasks ||
                                _taskError != null ||
                                _roleError != null
                            ? null
                            : _submitAdmin,
                        style: FilledButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: _lime,
                          foregroundColor: _background,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5 * s),
                          ),
                        ),
                        child: label(
                          _saving ? 'Creating…' : 'Create invite',
                          size: 8,
                          color: _background,
                          bold: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

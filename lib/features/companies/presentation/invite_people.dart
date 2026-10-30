import 'package:dropline/core/di/global_di.dart';
import 'package:dropline/core/secure_storage/secure_storage.dart';
import '../domain/entities/multiple_company_admin_entity.dart';
import 'bloc/multiple_company_admin_cubit.dart';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dropline/core/api_constant/api_client.dart';
import 'package:dropline/core/api_constant/dio_client.dart';
import 'package:flutter/material.dart';
import 'company_team_invitation.dart';

class InvitePeoplePage extends StatefulWidget {
  const InvitePeoplePage({
    super.key,
    this.onContacts,
    this.companyId = '',
    this.projectId = '',
    this.subCompanyId = '',
    this.companyName = 'Apex Build',
    this.projectName = 'Laxmi Gauri',
  });

  final String companyId, projectId, subCompanyId, companyName, projectName;

  final VoidCallback? onContacts;

  @override
  State<InvitePeoplePage> createState() => _InvitePeoplePageState();
}

class _InvitePeoplePageState extends State<InvitePeoplePage> {
  static const _background = Color(0xFF092A3B);
  static const _surface = Color(0xFF0D3042);
  static const _border = Color(0xFF31576B);
  static const _muted = Color(0xFF8EB5C9);
  static const _text = Color(0xFFF0F4FC);
  static const _lime = Color(0xFFB5FF65);

  final _formKey = GlobalKey<FormState>();
  final _people = [_PersonForm()];

  late final MultipleCompanyAdminCubit _submitCubit;
  bool _saving = false;

  Future<void> _submit() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final storage = sl<SecureStorage>();
      final userId = await storage.getUserId();
      final projectId = widget.projectId.isNotEmpty
          ? widget.projectId
          : await storage.getPunchProjectId();
      if (!mounted) return;
      await _submitCubit.submit(
        MultipleCompanyAdminRequest(
          loginUserId: userId,
          companyId: widget.companyId,
          projectId: projectId,
          subCompanyId: widget.subCompanyId,
          people: _people
              .map(
                (person) => CompanyAdminPerson(
                  name: person.name.text.trim(),
                  mobile: person.contact.text.trim(),
                  roleId: person.roleId!,
                  tasks: person.permissions,
                ),
              )
              .toList(),
        ),
      );
      if (!mounted) return;
      final state = _submitCubit.state;
      if (state.error != null) throw Exception(state.error);
      if (state.result == null) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(state.result!.message)));
      Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute<void>(
          builder: (_) => CompanyTeamInvitationPage(
            companyId: widget.companyId,
            projectId: projectId,
            subCompanyId: widget.subCompanyId,
            companyName: widget.companyName,
            projectName: widget.projectName,
            members: _people
                .map(
                  (person) => CompanyTeamMember(
                    name: person.name.text.trim(),
                    role: person.role,
                  ),
                )
                .toList(),
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  List<Map<String, String>> _roles = [];
  bool _loadingRoles = true;
  String? _roleError;

  @override
  void initState() {
    super.initState();
    _submitCubit = sl<MultipleCompanyAdminCubit>();
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
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingRoles = false;
        _roleError = 'Unable to load roles';
      });
    }
  }

  Future<void> _loadPermissions(_PersonForm person, String roleId) async {
    final request = ++person.request;
    setState(() {
      person.roleId = roleId;
      person.role = _roles.firstWhere((role) => role['id'] == roleId)['name']!;
      person.tasks = [];
      person.permissions.clear();
      person.loading = true;
      person.error = null;
    });
    try {
      final tasks = await _fetchOptions(
        ApiClient.get_role_task_define,
        'fld_role_task_define_id',
        'fld_role_task_name',
        roleId: roleId,
      );
      if (!mounted || person.request != request) return;
      setState(() {
        person.tasks = tasks;
        person.permissions.addEntries(
          tasks.map((task) => MapEntry(task['id']!, true)),
        );
        person.loading = false;
      });
    } catch (_) {
      if (!mounted || person.request != request) return;
      setState(() {
        person.loading = false;
        person.error = 'Unable to load permissions';
      });
    }
  }

  @override
  void dispose() {
    _submitCubit.close();
    for (final person in _people) {
      person.name.dispose();
      person.contact.dispose();
    }
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
                letterSpacing: .15 * s,
              ),
            );
            OutlineInputBorder border(Color color) => OutlineInputBorder(
              borderRadius: BorderRadius.circular(6 * s),
              borderSide: BorderSide(color: color),
            );
            InputDecoration decoration({String? hint}) => InputDecoration(
              isDense: true,
              filled: true,
              fillColor: _surface,
              hintText: hint,
              hintStyle: TextStyle(
                color: _muted.withValues(alpha: 0.55),
                fontSize: 7 * s,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 7 * s,
                vertical: 7 * s,
              ),
              enabledBorder: border(_border),
              focusedBorder: border(_muted),
              errorBorder: border(Colors.redAccent),
              focusedErrorBorder: border(Colors.redAccent),
            );
            Widget field(
              TextEditingController controller, {
              bool phone = false,
            }) => TextFormField(
              controller: controller,
              keyboardType: phone ? TextInputType.phone : TextInputType.name,
              textCapitalization: phone
                  ? TextCapitalization.none
                  : TextCapitalization.words,
              style: TextStyle(color: _text, fontSize: 7 * s),
              decoration: decoration(
                hint: phone ? '+91 *******88888' : 'Amit Desai',
              ),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Required' : null,
            );
            Widget permission(
              _PersonForm person,
              String taskId,
              String title,
            ) => Container(
              height: 24 * s,
              margin: EdgeInsets.only(bottom: 4 * s),
              padding: EdgeInsets.symmetric(horizontal: 7 * s),
              decoration: BoxDecoration(
                color: _surface,
                border: Border.all(color: _border),
                borderRadius: BorderRadius.circular(6 * s),
              ),
              child: Row(
                children: [
                  Expanded(child: label(title, bold: true)),
                  SizedBox(
                    width: 21 * s,
                    height: 14 * s,
                    child: FittedBox(
                      child: Switch(
                        value: person.permissions[taskId]!,
                        onChanged: (value) =>
                            setState(() => person.permissions[taskId] = value),
                        activeThumbColor: Colors.white,
                        activeTrackColor: _lime,
                        inactiveThumbColor: _text,
                        inactiveTrackColor: _border,
                        trackOutlineColor: const WidgetStatePropertyAll(
                          Colors.transparent,
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                ],
              ),
            );

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(10 * s, 6 * s, 10 * s, 8 * s),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - 14 * s).clamp(
                    0,
                    double.infinity,
                  ),
                ),
                child: IntrinsicHeight(
                  child: AbsorbPointer(
                    absorbing: _saving,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 21 * s,
                                height: 22 * s,
                                child: OutlinedButton(
                                  onPressed: () =>
                                      Navigator.of(context).maybePop(),
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    backgroundColor: _surface,
                                    side: const BorderSide(color: _border),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        6 * s,
                                      ),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.chevron_left,
                                    color: _muted,
                                    size: 13 * s,
                                  ),
                                ),
                              ),
                              SizedBox(width: 7 * s),
                              Expanded(
                                child: label(
                                  'Invite people',
                                  size: 12,
                                  bold: true,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10 * s),
                          label(
                            '${widget.projectName} · ${widget.companyName}',
                            size: 6.5,
                            color: _muted,
                          ),
                          for (final person in _people) ...[
                            SizedBox(height: 10 * s),
                            Row(
                              children: [
                                Expanded(
                                  child: label(
                                    'Full name',
                                    size: 6.5,
                                    color: _muted,
                                    bold: true,
                                  ),
                                ),
                                TextButton(
                                  onPressed:
                                      widget.onContacts ??
                                      () => ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Contact selection is not connected yet',
                                              ),
                                            ),
                                          ),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: label(
                                    'Contacts',
                                    size: 6,
                                    color: _lime,
                                    bold: true,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 3 * s),
                            field(person.name),
                            SizedBox(height: 8 * s),
                            label(
                              'Contact number',
                              size: 6.5,
                              color: _muted,
                              bold: true,
                            ),
                            SizedBox(height: 3 * s),
                            field(person.contact, phone: true),
                            SizedBox(height: 8 * s),
                            label('Role', size: 6.5, color: _muted, bold: true),
                            SizedBox(height: 3 * s),
                            DropdownButtonFormField<String>(
                              initialValue: person.roleId,
                              hint: Text(
                                _loadingRoles
                                    ? 'Loading roles…'
                                    : 'Select role',
                                style: const TextStyle(color: Colors.white),
                              ),
                              validator: (value) =>
                                  value == null ? 'Select a role' : null,
                              dropdownColor: _surface,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 7 * s,
                              ),
                              icon: Icon(
                                Icons.keyboard_arrow_down,
                                color: _muted,
                                size: 12 * s,
                              ),
                              decoration: decoration(),
                              items: _roles
                                  .map(
                                    (role) => DropdownMenuItem(
                                      value: role['id'],
                                      child: Text(
                                        role['name']!,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: _loadingRoles
                                  ? null
                                  : (roleId) {
                                      if (roleId != null) {
                                        _loadPermissions(person, roleId);
                                      }
                                    },
                            ),
                            SizedBox(height: 16 * s),
                            label('Project permissions', size: 8, bold: true),
                            SizedBox(height: 4 * s),
                            label(
                              'Choose permissions for the selected role.',
                              size: 6,
                              color: _muted,
                            ),
                            SizedBox(height: 7 * s),
                            if (_roleError != null)
                              TextButton(
                                onPressed: _loadRoles,
                                child: Text('$_roleError · Retry'),
                              ),
                            if (!_loadingRoles &&
                                _roleError == null &&
                                _roles.isEmpty)
                              label('No roles available', color: _muted),
                            if (person.loading)
                              const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                            if (person.error != null)
                              TextButton(
                                onPressed: () =>
                                    _loadPermissions(person, person.roleId!),
                                child: Text('${person.error} · Retry'),
                              ),
                            if (!person.loading &&
                                person.error == null &&
                                person.tasks.isEmpty)
                              label(
                                person.roleId == null
                                    ? 'Select a role to view permissions'
                                    : 'No permissions defined for this role',
                                color: _muted,
                              ),
                            for (final task in person.tasks)
                              permission(person, task['id']!, task['name']!),
                          ],
                          SizedBox(height: 10 * s),
                          TextButton(
                            onPressed: () =>
                                setState(() => _people.add(_PersonForm())),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 5 * s),
                            ),
                            child: label(
                              '+ Add another person',
                              color: _lime,
                              bold: true,
                            ),
                          ),
                          SizedBox(height: 15 * s),
                          const Spacer(),
                          SizedBox(
                            height: 27 * s,
                            child: FilledButton(
                              onPressed:
                                  _saving ||
                                      _loadingRoles ||
                                      _roleError != null ||
                                      _roles.isEmpty ||
                                      _people.any(
                                        (person) =>
                                            person.loading ||
                                            person.error != null,
                                      )
                                  ? null
                                  : _submit,
                              style: FilledButton.styleFrom(
                                padding: EdgeInsets.zero,
                                backgroundColor: _lime,
                                foregroundColor: _background,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(7 * s),
                                ),
                              ),
                              child: label(
                                _saving ? 'Sending…' : 'Send invitation',
                                color: _background,
                                bold: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PersonForm {
  _PersonForm({String name = ''}) : name = TextEditingController(text: name);

  final TextEditingController name;
  final contact = TextEditingController();
  String role = '';
  String? roleId;
  List<Map<String, String>> tasks = [];
  final permissions = <String, bool>{};
  bool loading = false;
  String? error;
  int request = 0;
}

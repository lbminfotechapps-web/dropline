import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/pending_invitations_bloc.dart';
import 'package:dropline/core/di/global_di.dart';
import 'package:dropline/core/secure_storage/secure_storage.dart';
import '../domain/usecase/update_admin_invitation_usecase.dart';
import 'package:go_router/go_router.dart';
import 'package:dropline/core/router/app_router.dart';
import '../domain/entities/company_admin_entity.dart';
import 'package:flutter/material.dart';

class InvitationReadyPage extends StatefulWidget {
  const InvitationReadyPage({
    super.key,
    this.admin,
    this.projectId = '',
    this.returnToMe = true,
    this.adminName = 'Rahul Sharma',
    this.companyName = 'PlasterCo',
    this.projectName = 'Laxmi Gauri',
    this.onSendInDropline,
    this.onShareWhatsApp,
    this.onShareSms,
  });

  final String projectId;
  final bool returnToMe;
  final CompanyAdminEntity? admin;
  final String adminName;
  final String companyName;
  final String projectName;
  final VoidCallback? onSendInDropline;
  final VoidCallback? onShareWhatsApp;
  final VoidCallback? onShareSms;

  @override
  State<InvitationReadyPage> createState() => _InvitationReadyPageState();
}

class _InvitationReadyPageState extends State<InvitationReadyPage> {
  void _goBack() {
    if (!widget.returnToMe && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go(AppRouter.me);
    }
  }

  late final PendingInvitationsBloc _pendingBloc;
  CompanyAdminEntity? _selectedAdmin;
  String? _loginError;

  @override
  void initState() {
    super.initState();
    _selectedAdmin = widget.admin;
    _pendingBloc = sl<PendingInvitationsBloc>();
    _loadPending();
  }

  Future<void> _loadPending() async {
    setState(() => _loginError = null);
    try {
      final userId = await sl<SecureStorage>().getUserId();
      if (!mounted) return;
      _pendingBloc.add(
        FetchPendingInvitations(
          loginUserId: userId,
          projectId: widget.projectId.isNotEmpty
              ? widget.projectId
              : widget.admin?.projectId ?? '',
        ),
      );
    } catch (error) {
      if (mounted) setState(() => _loginError = error.toString());
    }
  }

  @override
  void dispose() {
    _pendingBloc.close();
    super.dispose();
  }

  bool _updating = false;
  CompanyAdminEntity? _updatedAdmin;

  static const _background = Color(0xFF03283B);
  static const _surface = Color(0xFF0B2E44);
  static const _border = Color(0xFF264C63);
  static const _muted = Color(0xFF80B2CD);
  static const _text = Color(0xFFE9F2F8);

  Future<void> _sendInvitation(VoidCallback? action) async {
    if (_updating) return;
    setState(() => _updating = true);
    try {
      final adminId = _selectedAdmin?.fld_subcom_admin_det_id ?? '';
      final userId = await sl<SecureStorage>().getUserId();
      if (!mounted) return;
      if (adminId.isEmpty || userId.isEmpty) {
        throw Exception(
          'Missing admin owner ID or login details. Please create the admin invitation again.',
        );
      }
      final updated = await sl<UpdateAdminInvitationUsecase>()(
        loginUserId: userId,
        adminOwnerId: adminId,
      );
      if (!mounted) return;
      setState(() => _updatedAdmin = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF2E7D32),
          content: Text(
            'Invitation updated successfully.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
      action?.call();
      if (mounted) context.go(AppRouter.me);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final words = (_updatedAdmin?.name ?? _selectedAdmin?.name ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    final firstName = words.isEmpty ? 'your admin' : words.first;
    return PopScope(
      canPop: !widget.returnToMe,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _goBack();
      },
      child: Scaffold(
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
                TextAlign? align,
              }) => Text(
                value,
                textAlign: align,
                style: TextStyle(
                  color: color,
                  fontSize: size * s,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                  height: 1.4,
                ),
              );
              Widget shareAction(
                String title,
                IconData icon,
                VoidCallback? action,
              ) => Padding(
                padding: EdgeInsets.only(bottom: 6 * s),
                child: SizedBox(
                  height: 30 * s,
                  child: OutlinedButton(
                    onPressed: _updating || _selectedAdmin == null
                        ? null
                        : () => _sendInvitation(action),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 10 * s),
                      side: const BorderSide(color: Color(0xFF3D6E8B)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4 * s),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(icon, size: 15 * s, color: _muted),
                        SizedBox(width: 11 * s),
                        Expanded(child: label(title, size: 8, bold: true)),
                        Icon(Icons.chevron_right, color: _muted, size: 14 * s),
                      ],
                    ),
                  ),
                ),
              );
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(10 * s, 6 * s, 10 * s, 20 * s),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: (constraints.maxHeight - 26 * s).clamp(
                      0,
                      double.infinity,
                    ),
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 22 * s,
                              height: 22 * s,
                              child: OutlinedButton(
                                onPressed: _goBack,
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  label(
                                    'Invitation ready',
                                    size: 12,
                                    bold: true,
                                  ),
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
                        SizedBox(height: 10 * s),
                        label('Pending invitations', size: 10, bold: true),
                        SizedBox(height: 6 * s),
                        if (_loginError != null)
                          TextButton(
                            onPressed: _loadPending,
                            child: label('Unable to load invitations · Retry'),
                          ),
                        BlocConsumer<
                          PendingInvitationsBloc,
                          PendingInvitationsState
                        >(
                          bloc: _pendingBloc,
                          listener: (context, state) {
                            if (!state.loading && state.error == null) {
                              final matches = state.invitations.where(
                                (admin) =>
                                    admin.fld_subcom_admin_det_id ==
                                    _selectedAdmin?.fld_subcom_admin_det_id,
                              );
                              setState(
                                () => _selectedAdmin = matches.isNotEmpty
                                    ? matches.first
                                    : (state.invitations.isEmpty
                                          ? null
                                          : state.invitations.first),
                              );
                            }
                          },
                          builder: (context, state) {
                            if (state.loading)
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            if (state.error != null) {
                              return Column(
                                children: [
                                  label(state.error!, color: _muted),
                                  TextButton(
                                    onPressed: _loadPending,
                                    child: const Text('Retry'),
                                  ),
                                ],
                              );
                            }
                            if (state.invitations.isEmpty)
                              return label(
                                'No pending invitations',
                                color: _muted,
                              );
                            return Column(
                              children: [
                                for (final admin in state.invitations)
                                  Container(
                                    margin: EdgeInsets.only(bottom: 6 * s),
                                    decoration: BoxDecoration(
                                      color: _surface,
                                      border: Border.all(
                                        color:
                                            _selectedAdmin
                                                    ?.fld_subcom_admin_det_id ==
                                                admin.fld_subcom_admin_det_id
                                            ? _muted
                                            : _border,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        5 * s,
                                      ),
                                    ),
                                    child: ListTile(
                                      onTap: _updating
                                          ? null
                                          : () => setState(
                                              () => _selectedAdmin = admin,
                                            ),
                                      leading: Icon(
                                        _selectedAdmin
                                                    ?.fld_subcom_admin_det_id ==
                                                admin.fld_subcom_admin_det_id
                                            ? Icons.radio_button_checked
                                            : Icons.radio_button_off,
                                        color: _muted,
                                      ),
                                      title: label(
                                        admin.name,
                                        size: 8,
                                        bold: true,
                                      ),
                                      subtitle: label(
                                        '${admin.mobile} · ${admin.roleName}',
                                        size: 6.5,
                                        color: _muted,
                                      ),
                                      trailing: label(
                                        admin.status,
                                        size: 6,
                                        color: const Color(0xFFD4DA79),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        SizedBox(height: 10 * s),
                        if (_selectedAdmin != null)
                          label(
                            'Invite $firstName to join your project.',
                            size: 10,
                            bold: true,
                          ),
                        SizedBox(height: 9 * s),
                        shareAction(
                          'Send in Dropline',
                          Icons.send_outlined,
                          widget.onSendInDropline,
                        ),
                        shareAction(
                          'Share on WhatsApp',
                          Icons.chat_outlined,
                          widget.onShareWhatsApp,
                        ),
                        shareAction(
                          'Share by SMS',
                          Icons.sms_outlined,
                          widget.onShareSms,
                        ),
                        SizedBox(height: 4 * s),
                        label(
                          'Not on Dropline? The link helps them install and join.',
                          size: 6.5,
                          color: _muted,
                        ),
                        SizedBox(height: 20 * s),
                        const Spacer(),
                        Divider(color: _border, height: 16 * s),
                        label(
                          _updating
                              ? 'Updating invitation…'
                              : (_updatedAdmin?.status.isNotEmpty == true
                                    ? _updatedAdmin!.status
                                    : 'Pending until accepted'),
                          size: 6.5,
                          color: _muted,
                          align: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

import 'dart:async';
import 'dart:convert';

import 'package:dropline/core/api_constant/api_client.dart';
import 'package:flutter/material.dart';
import 'package:dropline/core/api_constant/dio_client.dart';
import 'share_invitation.dart';
import 'package:dropline/core/di/global_di.dart';
import 'package:dropline/core/secure_storage/secure_storage.dart';
import 'bloc/sub_company_bloc.dart';
import 'bloc/sub_company_event.dart';
import 'bloc/sub_company_state.dart';

class AddCompaniesPage extends StatefulWidget {
  const AddCompaniesPage({
    super.key,
    this.projectId = '',
    this.companyId = '',
    this.projectName = '',
  });

  final String projectId;
  final String companyId;
  final String projectName;
  @override
  State<AddCompaniesPage> createState() => _AddCompaniesPageState();
}

class _AddCompaniesPageState extends State<AddCompaniesPage> {
  static const _background = Color(0xFF092A3B);
  static const _surface = Color(0xFF0D3042);
  static const _border = Color(0xFF31576B);
  static const _muted = Color(0xFF8EB5C9);
  static const _text = Color(0xFFF0F4FC);
  static const _lime = Color(0xFFB5FF65);

  final _formKey = GlobalKey<FormState>();
  final _company = TextEditingController();
  late final SubCompanyBloc _submitBloc;
  StreamSubscription<SubCompanyState>? _submitSubscription;
  bool _saving = false;

  Future<void> _saveCompany() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final userId = await sl<SecureStorage>().getUserId();
      if (!mounted) return;
      if (userId.isEmpty ||
          widget.projectId.isEmpty ||
          widget.companyId.isEmpty) {
        throw Exception(
          'Missing user or project details. Reopen this project from Me.',
        );
      }
      _submitBloc.add(
        SubmitSubCompanyEvent(
          loginUserId: userId,
          companyId: widget.companyId,
          projectId: widget.projectId,
          tradeId: _trade!,
          subCompanyName: _company.text.trim(),
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

  void _onSubmitState(SubCompanyState state) {
    if (!mounted) return;
    if (state is SubCompanyError) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(state.message)));
    } else if (state is SubCompanySuccess) {
      final company = state.subCompany;
      Navigator.of(context).pushReplacement<String, String>(
        MaterialPageRoute<String>(
          builder: (_) => ShareInvitationPage(
            subCompany: company,
            companyName: company.subCompanyName,
            projectName: company.projectName,
            ownerCompanyName: company.companyName,
            companyId: company.subCompanyNo,
            trade: company.tradeName,
          ),
        ),
      );
    }
  }

  String? _trade;
  List<Map<String, String>> _trades = [];
  bool _loadingTrades = true;
  String? _tradeError;

  @override
  void initState() {
    super.initState();
    _submitBloc = sl<SubCompanyBloc>();
    _submitSubscription = _submitBloc.stream.listen(_onSubmitState);
    _loadTrades();
  }

  Future<void> _loadTrades() async {
    setState(() {
      _loadingTrades = true;
      _tradeError = null;
    });
    try {
      final response = await DioClient().client.post(ApiClient.get_trade);
      final dynamic data = response.data is String
          ? jsonDecode(response.data as String)
          : response.data;
      if (data is! Map) {
        throw const FormatException('Invalid trades response');
      }
      if (data['status'] != true) {
        throw Exception(data['message']?.toString() ?? 'Failed to load trades');
      }
      final dynamic result = data['result'];
      if (result is! List) {
        throw const FormatException('Invalid trades list');
      }
      final trades = <String, Map<String, String>>{};
      for (final item in result) {
        if (item is! Map) {
          throw const FormatException('Invalid trade entry');
        }
        final id = item['fld_trade_id']?.toString() ?? '';
        final name = item['fld_trade_name']?.toString() ?? '';
        if (id.isNotEmpty && name.isNotEmpty) {
          trades[id] = {'id': id, 'name': name};
        }
      }
      if (!mounted) return;
      setState(() {
        _trades = trades.values.toList();
        _trade = null;
        _loadingTrades = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingTrades = false;
        _tradeError = 'Unable to load trades. Please retry.';
      });
    }
  }

  @override
  void dispose() {
    _submitSubscription?.cancel();
    _submitBloc.close();
    _company.dispose();
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
                fontSize: size * s,
                color: color,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                letterSpacing: .15 * s,
              ),
            );
            OutlineInputBorder border(Color color) => OutlineInputBorder(
              borderRadius: BorderRadius.circular(6 * s),
              borderSide: BorderSide(color: color),
            );
            Widget field(String title, TextEditingController controller) =>
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: controller,
                      keyboardType: TextInputType.text,
                      textCapitalization: TextCapitalization.words,
                      style: TextStyle(color: _text, fontSize: 7 * s),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Required'
                          : null,
                      decoration: InputDecoration(
                        hintText: title,
                        hintStyle: TextStyle(color: _muted, fontSize: 7 * s),
                        isDense: true,
                        filled: true,
                        fillColor: _surface,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 6 * s,
                          vertical: 7 * s,
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
              padding: EdgeInsets.fromLTRB(10 * s, 7 * s, 10 * s, 10 * s),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - 17 * s).clamp(
                    0,
                    double.infinity,
                  ),
                ),
                child: IntrinsicHeight(
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
                                    borderRadius: BorderRadius.circular(6 * s),
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
                              child: label('Add company', size: 12, bold: true),
                            ),
                          ],
                        ),
                        SizedBox(height: 10 * s),
                        label(widget.projectName, size: 6.5, color: _muted),
                        SizedBox(height: 11 * s),
                        field('Company name or Dropline ID', _company),
                        SizedBox(height: 2 * s),
                        Padding(
                          padding: EdgeInsets.only(left: 6 * s),
                          child: label(
                            'New company · create with this invitation',
                            size: 5.5,
                            color: _lime,
                          ),
                        ),
                        SizedBox(height: 9 * s),
                        label('Trades', size: 6.5, color: _muted, bold: true),
                        SizedBox(height: 3 * s),
                        DropdownButtonFormField<String>(
                          initialValue: _trade,
                          isExpanded: true,
                          hint: Text(
                            _loadingTrades ? 'Loading trades…' : 'Select trade',
                            style: const TextStyle(color: Colors.white),
                          ),
                          validator: (value) =>
                              value == null ? 'Select a trade' : null,
                          dropdownColor: _surface,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 7 * s,
                          ),
                          icon: Icon(
                            Icons.keyboard_arrow_down,
                            color: _muted,
                            size: 13 * s,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            filled: true,
                            fillColor: _surface,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 6 * s,
                              vertical: 7 * s,
                            ),
                            enabledBorder: border(_border),
                            focusedBorder: border(_muted),
                          ),
                          items: _trades
                              .map(
                                (trade) => DropdownMenuItem(
                                  value: trade['id'],
                                  child: Text(
                                    trade['name']!,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: _loadingTrades || _trades.isEmpty
                              ? null
                              : (value) => setState(() => _trade = value),
                        ),
                        if (_tradeError != null)
                          TextButton(
                            onPressed: _loadTrades,
                            child: Text(
                              _tradeError!,
                              style: const TextStyle(color: _muted),
                            ),
                          ),
                        if (!_loadingTrades &&
                            _tradeError == null &&
                            _trades.isEmpty)
                          label('No trades available', color: _muted),
                        SizedBox(height: 20 * s),
                        const Spacer(),
                        SizedBox(
                          height: 27 * s,
                          child: FilledButton(
                            onPressed: _saving || _loadingTrades
                                ? null
                                : _saveCompany,
                            style: FilledButton.styleFrom(
                              backgroundColor: _lime,
                              foregroundColor: _background,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(7 * s),
                              ),
                            ),
                            child: label(
                              _saving ? 'Saving…' : 'Save Company',
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
            );
          },
        ),
      ),
    );
  }
}

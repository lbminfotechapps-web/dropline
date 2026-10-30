import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dropline/core/di/global_di.dart';
import 'bloc/find_company_bloc.dart';
import 'share_invitation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'invite_people.dart';

class CompaniesPeoplePage extends StatefulWidget {
  const CompaniesPeoplePage({
    super.key,
    this.projectId = '',
    this.companyId = '',
    this.projectName = 'Laxmi Gauri',
    this.companyName = 'Apex Build',
    this.onInvitePeople,
  });

  final String projectId;
  final String companyId;
  final String projectName;
  final String companyName;
  final VoidCallback? onInvitePeople;

  @override
  State<CompaniesPeoplePage> createState() => _CompaniesPeoplePageState();
}

class _CompaniesPeoplePageState extends State<CompaniesPeoplePage> {
  static const _background = Color(0xFF092A3B);
  static const _surface = Color(0xFF0D3042);
  static const _border = Color(0xFF31576B);
  static const _muted = Color(0xFF8EB5C9);
  static const _text = Color(0xFFF0F4FC);
  static const _lime = Color(0xFFB5FF65);

  bool _showCompanies = true;
  late final FindCompanyBloc _companiesBloc;

  @override
  void initState() {
    super.initState();
    _companiesBloc = sl<FindCompanyBloc>();
    _loadCompanies();
  }

  void _loadCompanies() {
    _companiesBloc.add(
      SearchSubCompanies(
        projectId: widget.projectId,
        companyId: widget.companyId,
      ),
    );
  }

  @override
  void dispose() {
    _companiesBloc.close();
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
            ButtonStyle buttonStyle({bool selected = false}) =>
                OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  backgroundColor: selected ? _lime : _surface,
                  side: BorderSide(color: selected ? _lime : _border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7 * s),
                  ),
                );

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(10 * s, 9 * s, 10 * s, 16 * s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 21 * s,
                        height: 22 * s,
                        child: OutlinedButton(
                          style: buttonStyle(),
                          onPressed: () => Navigator.of(context).maybePop(),
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
                          'Sub Companies & people',
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
                  SizedBox(height: 11 * s),
                  Row(
                    children: [true, false]
                        .map(
                          (companies) => Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: companies ? 4 * s : 0,
                              ),
                              child: SizedBox(
                                height: 20 * s,
                                child: OutlinedButton(
                                  style: buttonStyle(
                                    selected: _showCompanies == companies,
                                  ),
                                  onPressed: () => setState(
                                    () => _showCompanies = companies,
                                  ),
                                  child: label(
                                    companies
                                        ? 'Sub Companies'
                                        : 'Owner’s team',
                                    size: 6.5,
                                    bold: true,
                                    color: _showCompanies == companies
                                        ? _background
                                        : _muted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  SizedBox(height: 7 * s),
                  if (_showCompanies) ...[
                    BlocBuilder<FindCompanyBloc, FindCompanyState>(
                      bloc: _companiesBloc,
                      builder: (context, state) {
                        if (state.loading) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (state.error != null) {
                          return Column(
                            children: [
                              label(state.error!, color: _muted),
                              TextButton(
                                onPressed: _loadCompanies,
                                child: const Text('Retry'),
                              ),
                            ],
                          );
                        }
                        if (state.companies.isEmpty) {
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 10 * s),
                            child: label(
                              'No sub companies found',
                              color: _muted,
                            ),
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final company in state.companies)
                              Card(
                                color: _surface,
                                margin: EdgeInsets.only(bottom: 5 * s),
                                shape: RoundedRectangleBorder(
                                  side: const BorderSide(color: _border),
                                  borderRadius: BorderRadius.circular(7 * s),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(7 * s),
                                  onTap: () => Navigator.of(context).push(
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
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 7 * s,
                                      vertical: 6 * s,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              label(
                                                company.subCompanyName,
                                                size: 8,
                                                bold: true,
                                              ),
                                              SizedBox(height: 2 * s),
                                              label(
                                                '${company.subCompanyNo} · ${company.tradeName}',
                                                size: 6.5,
                                                color: _muted,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          Icons.chevron_right,
                                          color: _muted,
                                          size: 13 * s,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    SizedBox(
                      height: 28 * s,
                      child: OutlinedButton(
                        style: buttonStyle(),
                        onPressed: () async {
                          await context.push(
                            Uri(
                              path: '/findcompany',
                              queryParameters: {
                                'projectId': widget.projectId,
                                'companyId': widget.companyId,
                                'projectName': widget.projectName,
                              },
                            ).toString(),
                          );
                          if (mounted) _loadCompanies();
                        },
                        //_addCompany,
                        child: label('+ Add sub company', bold: true),
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 7 * s,
                        vertical: 6 * s,
                      ),
                      decoration: BoxDecoration(
                        color: _surface,
                        border: Border.all(color: _border),
                        borderRadius: BorderRadius.circular(7 * s),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          label('Suresh', size: 8, bold: true),
                          SizedBox(height: 2 * s),
                          label(
                            'Company owner · Joined',
                            size: 6.5,
                            color: _muted,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 6 * s),
                    SizedBox(
                      height: 28 * s,
                      child: OutlinedButton(
                        style: buttonStyle(),
                        onPressed:
                            widget.onInvitePeople ??
                            () => Navigator.of(context).push<void>(
                              MaterialPageRoute<void>(
                                builder: (_) => InvitePeoplePage(
                                  companyId: widget.companyId,
                                  projectId: widget.projectId,
                                  companyName: widget.companyName,
                                  projectName: widget.projectName,
                                ),
                              ),
                            ),
                        child: label('+ Invite people', size: 8, bold: true),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

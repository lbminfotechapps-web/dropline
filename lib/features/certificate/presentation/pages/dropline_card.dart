import 'package:dropline/core/theme/app_theme.dart';
import 'package:dropline/core/theme/appcolors.dart';
import 'package:dropline/core/utility/widgets/appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DroplineCardItem {
  const DroplineCardItem({
    required this.name,
    required this.designation,
    this.company = '',
    this.phone = '',
    this.email = '',
    this.companyId = '',
    this.certificates = const [],
    this.nextOfKin = '',
    this.relationship = '',
    this.nextOfKinPhone = '',
    this.supportInfo = '',
  });

  final String name;
  final String designation;
  final String company;
  final String phone;
  final String email;
  final String companyId;
  final List<DroplineCardCertificate> certificates;
  final String nextOfKin;
  final String relationship;
  final String nextOfKinPhone;
  final String supportInfo;
}

class DroplineCardCertificate {
  const DroplineCardCertificate({
    required this.name,
    this.expiry = 'No expiry',
  });

  final String name;
  final String expiry;
}

class DroplineCard extends StatelessWidget {
  const DroplineCard({
    super.key,
    this.myCards = const [
      DroplineCardItem(
        name: 'Alex Morgan',
        designation: 'Site manager',
        company: 'Apex Build',
        phone: '+44 •••••• 0101',
        email: 'alex@example.com',
        companyId: 'DL-C-6M2N8Q',
        certificates: [
          DroplineCardCertificate(name: 'Site safety training'),
          DroplineCardCertificate(
            name: 'Trade qualification',
            expiry: 'Expires 10 May 2027',
          ),
        ],
        nextOfKin: 'Taylor Morgan',
        relationship: 'Partner',
        nextOfKinPhone: '+44 •••••• 0123',
        supportInfo: 'Request a private conversation',
      ),
    ],
    this.receivedCards = const [],
    this.sentCards = const [],
  });

  final List<DroplineCardItem> myCards;
  final List<DroplineCardItem> receivedCards;
  final List<DroplineCardItem> sentCards;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: context.backgroundColor(AppColors.background),
        appBar: const CustomAppBar(title: 'Dropline Cards'),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              TabBar(
                labelColor: AppColors.primary,
                unselectedLabelColor: context.mutedColor(
                  AppColors.textSecondary,
                ),
                indicatorColor: AppColors.primary,
                dividerColor: context.borderColor(AppColors.border),
                labelStyle: TextStyle(fontWeight: FontWeight.w500),
                tabs: [
                  Tab(text: 'My Cards'),
                  Tab(text: 'Received'),
                  Tab(text: 'Sent'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    myCards.isEmpty
                        ? const _CardList(
                            cards: [],
                            emptyMessage: 'No cards yet',
                          )
                        : _MyCardTab(cards: myCards),
                    _CardList(
                      cards: receivedCards,
                      emptyMessage: 'No received cards yet',
                    ),
                    _CardList(
                      cards: sentCards,
                      emptyMessage: 'No sent cards yet',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardList extends StatelessWidget {
  const _CardList({required this.cards, required this.emptyMessage});

  final List<DroplineCardItem> cards;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.badge_outlined,
                size: 48,
                color: context.mutedColor(AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.mutedColor(AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: cards.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final card = cards[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.surfaceColor(AppColors.surface),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.borderColor(AppColors.border)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: context.backgroundColor(AppColors.background),
                child: Icon(Icons.person_outline, color: context.accentColor(AppColors.primary)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.name,
                      style: TextStyle(
                        color: context.foregroundColor(AppColors.textPrimary),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (card.designation.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        card.designation,
                        style: TextStyle(
                          color: context.mutedColor(AppColors.textSecondary),
                        ),
                      ),
                    ],
                    if (card.company.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        card.company,
                        style: TextStyle(
                          color: context.mutedColor(AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

const _previewMuted = Color(0xFFA8C6D7);
const _previewBorder = Color(0xFF35566B);
const _previewText = Color(0xFFF1F6FC);

class _MyCardTab extends StatelessWidget {
  const _MyCardTab({required this.cards});
  final List<DroplineCardItem> cards;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF1D3A4E), Color(0xFF142E3E)],
      ),
    ),
    child: DefaultTextStyle(
      style: const TextStyle(
        fontFamily: 'Georgia',
        color: _previewText,
        fontSize: 14,
      ),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
        itemCount: cards.length,
        separatorBuilder: (_, _) => const SizedBox(height: 32),
        itemBuilder: (context, index) => _MyCardPreview(card: cards[index]),
      ),
    ),
  );
}

class _MyCardPreview extends StatelessWidget {
  const _MyCardPreview({required this.card});
  final DroplineCardItem card;

  Widget _panel(Widget child, {bool identity = false}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: identity ? null : const Color(0xFF1C3A4D),
      gradient: identity
          ? const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2A5066), Color(0xFF224156)],
            )
          : null,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _previewBorder),
    ),
    child: child,
  );

  Widget _contact(IconData icon, String value) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Row(
      children: [
        Icon(icon, size: 15, color: _previewMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, color: _previewMuted),
          ),
        ),
      ],
    ),
  );

  String get _initials => card.name
      .trim()
      .split(RegExp(r'\s+'))
      .where((s) => s.isNotEmpty)
      .take(2)
      .map((s) => s.characters.first)
      .join()
      .toUpperCase();

  Future<void> _share(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.backgroundColor(Color(0xFF1C3A4D)),
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Choose how to share',
              style: TextStyle(
                color: _previewText,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose which details to copy, then paste them into your preferred app.',
              style: TextStyle(color: _previewMuted, fontSize: 13),
            ),
            for (final includeOptional in [false, true])
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.copy_outlined, color: _previewMuted),
                title: Text(
                  includeOptional
                      ? 'Copy with optional details'
                      : 'Copy contact details',
                  style: const TextStyle(color: _previewText),
                ),
                onTap: () async {
                  final details = [
                    card.name,
                    card.designation,
                    card.company,
                    card.phone,
                    card.email,
                    if (card.companyId.isNotEmpty)
                      'Company ID: ${card.companyId}',
                    if (includeOptional) ...[
                      ...card.certificates.map(
                        (c) => '${c.name} — ${c.expiry}',
                      ),
                      if (card.nextOfKin.isNotEmpty)
                        'Next of kin: ${card.nextOfKin}${card.relationship.isEmpty ? '' : ' · ${card.relationship}'}',
                      card.nextOfKinPhone,
                      card.supportInfo,
                    ],
                  ].where((s) => s.isNotEmpty).join('\n');
                  await Clipboard.setData(ClipboardData(text: details));
                  if (!sheetContext.mounted) return;
                  Navigator.pop(sheetContext);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Card details copied')),
                    );
                  }
                },
              ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Card preview',
        style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 10),
      const Text(
        'With optional details included',
        style: TextStyle(color: _previewMuted, fontSize: 12),
      ),
      const SizedBox(height: 14),
      _panel(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Dropline · Site',
                style: TextStyle(fontSize: 9, color: _previewMuted),
              ),
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF385F75),
                    border: Border.all(color: const Color(0xFF61879D)),
                  ),
                  child: Text(
                    _initials,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.name,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (card.designation.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          card.designation,
                          style: const TextStyle(
                            color: _previewMuted,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (card.company.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                card.company,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 10),
            const Divider(height: 1, color: _previewBorder),
            if (card.phone.isNotEmpty)
              _contact(Icons.phone_outlined, card.phone),
            if (card.email.isNotEmpty) _contact(Icons.mail_outline, card.email),
            if (card.companyId.isNotEmpty)
              _contact(
                Icons.business_outlined,
                'Company ID: ${card.companyId}',
              ),
          ],
        ),
        identity: true,
      ),
      if (card.certificates.isNotEmpty) ...[
        const SizedBox(height: 20),
        const Text(
          'Certificates',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        _panel(
          Column(
            children: [
              for (final entry in card.certificates.indexed) ...[
                if (entry.$1 > 0)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1, color: _previewBorder),
                  ),
                Row(
                  children: [
                    const Icon(
                      Icons.description_outlined,
                      size: 21,
                      color: _previewMuted,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.$2.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            entry.$2.expiry,
                            style: const TextStyle(
                              fontSize: 11,
                              color: _previewMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
      if (card.nextOfKin.isNotEmpty || card.supportInfo.isNotEmpty) ...[
        const SizedBox(height: 10),
        _panel(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (card.nextOfKin.isNotEmpty) ...[
                const Text(
                  'Next of kin',
                  style: TextStyle(
                    color: _previewMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${card.nextOfKin}${card.relationship.isEmpty ? '' : ' · ${card.relationship}'}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (card.nextOfKinPhone.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    card.nextOfKinPhone,
                    style: const TextStyle(fontSize: 11, color: _previewMuted),
                  ),
                ],
              ],
              if (card.nextOfKin.isNotEmpty && card.supportInfo.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: _previewBorder),
                ),
              if (card.supportInfo.isNotEmpty) ...[
                const Text(
                  'Medical / support info',
                  style: TextStyle(
                    color: _previewMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  card.supportInfo,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Saved support preference',
                  style: TextStyle(color: _previewMuted, fontSize: 11),
                ),
              ],
            ],
          ),
        ),
      ],
      const SizedBox(height: 48),
      SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: () => _share(context),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: const Color(0xFF132B3A),
            minimumSize: const Size.fromHeight(46),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(11),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Georgia',
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: const Text('Choose how to share'),
        ),
      ),
    ],
  );
}

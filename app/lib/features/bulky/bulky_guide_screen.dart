import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/services.dart';
import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import '../item/category_style.dart';
import '../today/today_screen.dart' show openSource;
import 'bulky_guide.dart';

/// The bulky waste (粗大ごみ) guide for the user's area: the steps, the
/// booking page, phone numbers and the official source. Read from the
/// stored bundle, so it works offline; only the links need a connection.
class BulkyGuideScreen extends StatefulWidget {
  const BulkyGuideScreen({super.key});

  @override
  State<BulkyGuideScreen> createState() => _BulkyGuideScreenState();
}

class _BulkyGuideScreenState extends State<BulkyGuideScreen> {
  Future<BulkyGuide?>? _guide;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final services = AppServices.of(context);
    final area = services.area.area;
    _guide ??= area == null
        ? Future.value(null)
        : bulkyGuideFor(services.db, area);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: FutureBuilder(
        future: _guide,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final guide = snapshot.data;
          return guide == null ? const _NoGuide() : _Guide(guide: guide);
        },
      ),
    );
  }
}

class _Guide extends StatelessWidget {
  const _Guide({required this.guide});

  final BulkyGuide guide;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final ja = isJapanese(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final booking = guide.booking;
    final verified = DateTime.tryParse(guide.verifiedAt);
    final others = guide.links.where((l) => l.kind != GuideLinkKind.booking);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.bulkyTitle,
                    style: text.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (!ja) Text('粗大ごみ', style: text.titleMedium),
                ],
              ),
            ),
            Image.asset(
              'assets/illustrations/sofa.png',
              width: 72,
              height: 72,
              excludeFromSemantics: true,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(guide.summary.of(japanese: ja), style: text.bodyLarge),
        const SizedBox(height: AppSpacing.md),
        for (final (i, step) in guide.steps.indexed) ...[
          _StepCard(number: i + 1, step: step, shaded: i.isOdd),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (!ja) ...[
          Text(l10n.itemTranslationNote, style: text.bodySmall),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (booking != null) ...[
          const SizedBox(height: AppSpacing.sm),
          FilledButton.icon(
            onPressed: () => openSource(context, booking.url),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(minimumTouchTarget),
            ),
            icon: const Icon(Icons.open_in_new),
            label: Text(booking.label.of(japanese: ja)),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.bulkyNoBooking,
            style: text.bodySmall?.copyWith(color: AppColors.secondaryInk),
          ),
        ],
        if (guide.contacts.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(l10n.bulkyPhone, style: text.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Card(
            child: Column(
              children: [
                for (final (i, contact) in guide.contacts.indexed) ...[
                  if (i > 0) const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.phone_outlined,
                      color: AppColors.primary,
                    ),
                    title: Text(contact.label.of(japanese: ja)),
                    subtitle: Text(
                      [
                        contact.phone,
                        if (contact.note case final note?)
                          note.of(japanese: ja),
                      ].join('\n'),
                    ),
                    isThreeLine: contact.note != null,
                    trailing: IconButton(
                      tooltip: l10n.bulkyCall(contact.phone),
                      icon: const Icon(Icons.call),
                      onPressed: () => _call(context, contact.phone),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Text(l10n.bulkyOtherLinks, style: text.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Card(
          child: Column(
            children: [
              for (final link in others) ...[
                ListTile(
                  leading: Icon(
                    link.kind == GuideLinkKind.fees
                        ? Icons.sell_outlined
                        : Icons.info_outline,
                    color: AppColors.primary,
                  ),
                  title: Text(link.label.of(japanese: ja)),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => openSource(context, link.url),
                ),
                const Divider(height: 1),
              ],
              ListTile(
                leading: const Icon(
                  Icons.account_balance_outlined,
                  color: AppColors.primary,
                ),
                title: Text(l10n.itemSource),
                subtitle: Text(
                  l10n.bulkyChecked(
                    verified == null
                        ? guide.verifiedAt
                        : DateFormat.yMMMd(locale).format(verified),
                  ),
                ),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => openSource(context, guide.sourceUrl),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _call(BuildContext context, String phone) async {
    final messenger = ScaffoldMessenger.of(context);
    final message = AppLocalizations.of(context).itemOpenFailed;
    final called = await launchUrl(
      Uri(scheme: 'tel', path: phone.replaceAll('-', '')),
    ).catchError((Object _) => false);
    if (!called) messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}

/// A numbered step, like the design's cards.
class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.number,
    required this.step,
    required this.shaded,
  });

  final int number;
  final GuideStep step;
  final bool shaded;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final ja = isJapanese(context);
    return Card(
      color: shaded ? AppColors.lavender : AppColors.peach,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.surface,
              child: Text(
                '$number',
                style: text.titleMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title.of(japanese: ja),
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(step.body.of(japanese: ja), style: text.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoGuide extends StatelessWidget {
  const _NoGuide();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        Image.asset(
          'assets/illustrations/sofa.png',
          height: 96,
          excludeFromSemantics: true,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.bulkyNone,
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

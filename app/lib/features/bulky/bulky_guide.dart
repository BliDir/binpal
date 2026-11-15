import 'dart:convert';

import '../../data/database.dart';

/// Text in Japanese and English, as bundles write it.
class GuideText {
  const GuideText(this.ja, this.en);

  GuideText.fromJson(Map<String, dynamic> json)
    : ja = json['ja'] as String,
      en = json['en'] as String;

  final String ja;
  final String en;

  String of({required bool japanese}) => japanese ? ja : en;
}

class GuideStep {
  const GuideStep(this.title, this.body);

  final GuideText title;
  final GuideText body;
}

class GuideContact {
  const GuideContact(this.label, this.phone, this.note);

  final GuideText label;

  /// As written, for example 0570-200-530.
  final String phone;
  final GuideText? note;
}

enum GuideLinkKind { booking, fees, info }

class GuideLink {
  const GuideLink(this.kind, this.label, this.url);

  final GuideLinkKind kind;
  final GuideText label;
  final String url;
}

/// How to put out bulky waste (粗大ごみ) where the user lives: what counts,
/// how to book, pay, label and put it out, and the official pages. BinPal
/// never books on the user's behalf; it opens the booking page.
class BulkyGuide {
  const BulkyGuide({
    required this.summary,
    required this.steps,
    required this.contacts,
    required this.links,
    required this.sourceUrl,
    required this.verifiedAt,
  });

  /// From the bundle's `bulky_guides` entry. Unknown link kinds are skipped,
  /// so a newer bundle can't break the guide.
  factory BulkyGuide.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> maps(Object? list) =>
        (list as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();
    GuideText text(Object? json) =>
        GuideText.fromJson(json as Map<String, dynamic>);
    return BulkyGuide(
      summary: text(json['summary']),
      steps: [
        for (final s in maps(json['steps']))
          GuideStep(text(s['title']), text(s['body'])),
      ],
      contacts: [
        for (final c in maps(json['contacts']))
          GuideContact(
            text(c['label']),
            c['phone'] as String,
            c['note'] == null ? null : text(c['note']),
          ),
      ],
      links: [
        for (final l in maps(json['links']))
          if (GuideLinkKind.values.asNameMap()[l['kind']] case final kind?)
            GuideLink(kind, text(l['label']), l['url'] as String),
      ],
      sourceUrl: json['source_url'] as String,
      verifiedAt: json['verified_at'] as String,
    );
  }

  final GuideText summary;
  final List<GuideStep> steps;
  final List<GuideContact> contacts;
  final List<GuideLink> links;
  final String sourceUrl;

  /// `YYYY-MM-DD`: when the guide was last checked against the official
  /// pages.
  final String verifiedAt;

  GuideLink? get booking =>
      links.where((l) => l.kind == GuideLinkKind.booking).firstOrNull;
}

/// The guide for [area]: its ward's own, or else the municipality's.
Future<BulkyGuide?> bulkyGuideFor(AppDatabase db, Area area) async {
  final guides = await (db.select(
    db.bulkyGuides,
  )..where((g) => g.municipalityId.equals(area.municipalityId))).get();
  BulkyGuide parse(BulkyGuideRow row) =>
      BulkyGuide.fromJson(jsonDecode(row.guide) as Map<String, dynamic>);
  for (final row in guides) {
    final wards = row.wardIds == null
        ? const <dynamic>[]
        : jsonDecode(row.wardIds!) as List<dynamic>;
    if (area.wardId != null && wards.contains(area.wardId)) return parse(row);
  }
  final wide = guides.where((g) => g.wardIds == null).firstOrNull;
  return wide == null ? null : parse(wide);
}

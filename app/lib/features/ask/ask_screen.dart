import 'package:flutter/material.dart';

import '../../app/services.dart';
import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import 'answer_screen.dart';
import 'ask_client.dart';

/// "Ask a question": a plain-language question about the area's rules.
class AskScreen extends StatefulWidget {
  const AskScreen({super.key, this.initial = ''});

  /// Text to start with, such as a search that found nothing.
  final String initial;

  @override
  State<AskScreen> createState() => _AskScreenState();
}

class _AskScreenState extends State<AskScreen> {
  late final _question = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _question.dispose();
    super.dispose();
  }

  void _ask(String question) {
    final text = question.trim();
    if (text.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => AnswerScreen(question: text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final hasArea = AppServices.of(context).area.area != null;
    final examples = [l10n.askExample1, l10n.askExample2, l10n.askExample3];

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(
            l10n.askTitle,
            style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(l10n.askSubtitle, style: text.bodyLarge),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _question,
            minLines: 4,
            maxLines: 6,
            maxLength: maxQuestionLength,
            textInputAction: TextInputAction.done,
            onSubmitted: _ask,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: l10n.askHint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.card),
                borderSide: const BorderSide(color: AppColors.outline),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Card(
            color: AppColors.lavender,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome_outlined,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(l10n.askExamplesTitle, style: text.titleMedium),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  for (final example in examples)
                    InkWell(
                      onTap: () => setState(() => _question.text = example),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xs,
                        ),
                        child: Text('• $example', style: text.bodyMedium),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: hasArea && _question.text.trim().isNotEmpty
                ? () => _ask(_question.text)
                : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(minimumTouchTarget),
            ),
            icon: const Icon(Icons.chat_bubble_outline),
            label: Text(l10n.askButton),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.askNote,
            style: text.bodySmall?.copyWith(color: AppColors.secondaryInk),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/ui/spacing.dart';
import '../../l10n/app_localizations.dart';

/// The in-app Privacy page (DESIGN_SPEC `BOTTOM_NAV_SNACKBAR_PRIVACY.md` §3).
/// Fully local, read-only: a lock hero, a lead line, five guarantee rows in one
/// card, and a footer naming the only export path. No buttons, no links out.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final rows = <_Guarantee>[
      _Guarantee(Icons.person_off_outlined, l10n.privacyNoAccountTitle,
          l10n.privacyNoAccountBody),
      _Guarantee(Icons.cloud_off_outlined, l10n.privacyOnDeviceTitle,
          l10n.privacyOnDeviceBody),
      _Guarantee(Icons.wifi_off_outlined, l10n.privacyNoNetworkTitle,
          l10n.privacyNoNetworkBody),
      _Guarantee(Icons.visibility_off_outlined, l10n.privacyNoTrackingTitle,
          l10n.privacyNoTrackingBody),
      _Guarantee(
          Icons.block, l10n.privacyNoAdsTitle, l10n.privacyNoAdsBody),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsPrivacy)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            Insets.screenH, Insets.lg, Insets.screenH, Insets.xxl),
        children: [
          // Hero lock tile — same silhouette as the app icon, not a warning.
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(Icons.lock_outline,
                  size: 44, color: scheme.onPrimaryContainer),
            ),
          ),
          const SizedBox(height: Insets.xl),
          Text(
            l10n.privacyLead,
            textAlign: TextAlign.center,
            style: text.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600, height: 1.4),
          ),
          const SizedBox(height: Insets.xl),
          Container(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: scheme.outline),
            ),
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0)
                    Divider(height: 1, thickness: 1, color: scheme.outline),
                  _GuaranteeRow(item: rows[i]),
                ],
              ],
            ),
          ),
          const SizedBox(height: Insets.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.upload_outlined,
                  size: 18, color: scheme.onSurfaceVariant),
              const SizedBox(width: Insets.sm),
              Expanded(
                child: Text(l10n.privacyFooter,
                    style: text.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant, height: 1.4)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Guarantee {
  const _Guarantee(this.icon, this.title, this.body);
  final IconData icon;
  final String title;
  final String body;
}

class _GuaranteeRow extends StatelessWidget {
  const _GuaranteeRow({required this.item});
  final _Guarantee item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(Insets.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, size: 20, color: scheme.primary),
          ),
          const SizedBox(width: Insets.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style:
                        text.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(item.body,
                    style: text.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

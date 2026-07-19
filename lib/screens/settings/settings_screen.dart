import 'package:flutter/material.dart';
import '../../services/keyboard_service.dart';
import '../../services/preferences.dart';
import '../../widgets/setting_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool startup, preview, suggestions, backspace, autocorrect;
  @override
  void initState() {
    super.initState();
    final p = PreferencesService.instance;
    startup = p.startupEnabled;
    preview = p.floatingPreview;
    suggestions = p.suggestionsEnabled;
    backspace = p.smartBackspace;
    autocorrect = p.autoCorrect;
  }

  @override
  Widget build(BuildContext context) => ListView(children: [
        Text('General',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Text('Control how Avro works outside this window.'),
        const SizedBox(height: 24),
        SettingCard(
            title: 'Enable Avro Keyboard',
            description: 'Listen for global keys and send Unicode Bangla text.',
            trailing: AnimatedBuilder(
                animation: KeyboardService.instance,
                builder: (_, __) => Switch(
                    value: KeyboardService.instance.enabled,
                    onChanged: KeyboardService.instance.setEnabled))),
        SettingCard(
            title: 'Start at login',
            description:
                'Launch the background keyboard companion after you sign in.',
            trailing: Switch(
                value: startup,
                onChanged: (v) async {
                  setState(() => startup = v);
                  await PreferencesService.instance.setStartupEnabled(v);
                })),
        SettingCard(
            title: 'Floating preview',
            description: 'Show the composition window while typing.',
            trailing: Switch(
                value: preview,
                onChanged: (v) async {
                  setState(() => preview = v);
                  await PreferencesService.instance.setFloatingPreview(v);
                })),
        SettingCard(
            title: 'Candidate suggestions',
            description: 'Offer words from your local dictionary.',
            trailing: Switch(
                value: suggestions,
                onChanged: (v) async {
                  setState(() => suggestions = v);
                  await PreferencesService.instance.setSuggestionsEnabled(v);
                })),
        SettingCard(
            title: 'Smart backspace',
            description: 'Delete composed Bangla clusters as one unit.',
            trailing: Switch(
                value: backspace,
                onChanged: (v) async {
                  setState(() => backspace = v);
                  await PreferencesService.instance.setSmartBackspace(v);
                })),
        SettingCard(
            title: 'Auto correction',
            description:
                'Apply phonetic spelling corrections before committing.',
            trailing: Switch(
                value: autocorrect,
                onChanged: (v) async {
                  setState(() => autocorrect = v);
                  await PreferencesService.instance.setAutoCorrect(v);
                }))
      ]);
}

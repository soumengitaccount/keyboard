import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_state.dart';
import '../../services/native_bridge.dart';
import '../../services/preferences.dart';
import '../../widgets/sidebar.dart';
import '../../widgets/top_bar.dart';
import '../layout/layout_viewer.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  Future<void> _setBanglaMode(bool value) async {
    await LanguageController.instance.setBanglaEnabled(value);
    await NativeBridge.instance.toggleLanguage(value);
  }

  @override
  Widget build(BuildContext context) {
    final banglaMode = ref.watch(languageControllerProvider).banglaEnabled;
    final pages = <Widget>[
      _DashboardPage(onOpenLayout: () => setState(() => _selectedIndex = 1)),
      const LayoutViewer(),
      const _DictionaryPage(),
      const _AppearancePage(),
      const _HotkeysPage(),
      const SettingsScreen(),
      const _AboutPage(),
    ];
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            TopBar(
                banglaEnabled: banglaMode, onLanguageChanged: _setBanglaMode),
            Expanded(
              child: Row(
                children: [
                  Sidebar(
                      selectedIndex: _selectedIndex,
                      onChanged: (index) =>
                          setState(() => _selectedIndex = index)),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(36, 32, 36, 24),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: KeyedSubtree(
                            key: ValueKey(_selectedIndex),
                            child: pages[_selectedIndex]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardPage extends ConsumerWidget {
  const _DashboardPage({required this.onOpenLayout});
  final VoidCallback onOpenLayout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keyboard = ref.watch(keyboardServiceProvider);
    return ListView(
      children: [
        Text('Avro Keyboard',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('A quiet, system-wide Bangla typing companion.',
            style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF155EEF), Color(0xFF5B8CFF)]),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(children: [
            const CircleAvatar(
                radius: 27,
                backgroundColor: Color(0x33FFFFFF),
                child: Icon(FluentIcons.keyboard_24_regular,
                    color: Colors.white, size: 28)),
            const SizedBox(width: 18),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(
                      keyboard.enabled
                          ? 'Bangla typing is ready'
                          : 'Keyboard is paused',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                      keyboard.enabled
                          ? 'Use Ctrl + Alt + B to switch language anywhere.'
                          : 'Turn it on below to resume global typing.',
                      style: const TextStyle(color: Color(0xDFFFFFFF))),
                ])),
            Switch(
                value: keyboard.enabled,
                activeThumbColor: Colors.white,
                activeTrackColor: const Color(0x660B3EAC),
                onChanged: keyboard.setEnabled),
          ]),
        ),
        const SizedBox(height: 22),
        Row(children: [
          _StatCard(
              icon: FluentIcons.text_field_24_regular,
              label: 'Current layout',
              value: PreferencesService.instance.layout),
          const SizedBox(width: 16),
          _StatCard(
              icon: FluentIcons.key_24_regular,
              label: 'Language switch',
              value: 'Ctrl + Alt + B'),
          const SizedBox(width: 16),
          _StatCard(
              icon: FluentIcons.shield_checkmark_24_regular,
              label: 'Unicode output',
              value: 'Enabled'),
        ]),
        const SizedBox(height: 28),
        Text('Live composition',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        _CompositionCard(
            preview: keyboard.preview, candidates: keyboard.candidates),
        const SizedBox(height: 20),
        OutlinedButton.icon(
            onPressed: onOpenLayout,
            icon: const Icon(FluentIcons.keyboard_24_regular),
            label: const Text('View keyboard layout')),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Expanded(
      child: Card(
          child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 18),
                    Text(label, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Text(value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700))
                  ]))));
}

class _CompositionCard extends StatelessWidget {
  const _CompositionCard({required this.preview, required this.candidates});
  final String preview;
  final List<String> candidates;
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                preview.isEmpty ? 'Start typing phonetic English…' : preview,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (candidates.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: candidates
                      .take(6)
                      .map((word) => Chip(label: Text(word)))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      );
}

class _DictionaryPage extends StatelessWidget {
  const _DictionaryPage();
  @override
  Widget build(BuildContext context) => const _InfoPage(
      icon: FluentIcons.book_24_regular,
      title: 'Dictionary',
      text:
          'Your local candidate dictionary is loaded and used while you compose words.');
}

class _AppearancePage extends StatelessWidget {
  const _AppearancePage();
  @override
  Widget build(BuildContext context) => const _InfoPage(
      icon: FluentIcons.color_24_regular,
      title: 'Appearance',
      text:
          'The desktop app follows your system theme and uses a compact, distraction-free control surface.');
}

class _HotkeysPage extends StatelessWidget {
  const _HotkeysPage();
  @override
  Widget build(BuildContext context) => const _InfoPage(
      icon: FluentIcons.key_24_regular,
      title: 'Hotkeys',
      text:
          'Ctrl + Alt + B toggles Bangla mode. Change it later in the platform settings when adding configurable hotkeys.');
}

class _AboutPage extends StatelessWidget {
  const _AboutPage();
  @override
  Widget build(BuildContext context) => const _InfoPage(
      icon: FluentIcons.info_24_regular,
      title: 'About Avro Keyboard',
      text:
          'Flutter desktop UI with native OS input hooks and standard Unicode Bangla output.');
}

class _InfoPage extends StatelessWidget {
  const _InfoPage(
      {required this.icon, required this.title, required this.text});
  final IconData icon;
  final String title;
  final String text;
  @override
  Widget build(BuildContext context) => Center(
      child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Card(
              child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(icon,
                        size: 38, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(title,
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 10),
                    Text(text, textAlign: TextAlign.center)
                  ])))));
}

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class TopBar extends StatefulWidget {
  const TopBar(
      {super.key,
      required this.banglaEnabled,
      required this.onLanguageChanged});
  final bool banglaEnabled;
  final ValueChanged<bool> onLanguageChanged;
  @override
  State<TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> with WindowListener {
  bool _maximized = false;
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _load();
  }

  Future<void> _load() async {
    _maximized = await windowManager.isMaximized();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowMaximize() => setState(() => _maximized = true);
  @override
  void onWindowUnmaximize() => setState(() => _maximized = false);
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border:
            Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: DragToMoveArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(8)),
                      child: const Text('অ',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 10),
                    Text('Avro Keyboard',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    _LanguagePill(
                        enabled: widget.banglaEnabled,
                        onTap: () =>
                            widget.onLanguageChanged(!widget.banglaEnabled)),
                  ],
                ),
              ),
            ),
          ),
          _CaptionButton(icon: Icons.remove, onPressed: windowManager.minimize),
          _CaptionButton(
              icon: _maximized ? Icons.filter_none : Icons.crop_square,
              onPressed: () async => _maximized
                  ? windowManager.unmaximize()
                  : windowManager.maximize()),
          _CaptionButton(
              icon: Icons.close, danger: true, onPressed: windowManager.close),
        ],
      ),
    );
  }
}

class _LanguagePill extends StatelessWidget {
  const _LanguagePill({required this.enabled, required this.onTap});
  final bool enabled;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          decoration: BoxDecoration(
              color: enabled
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20)),
          child: Text(enabled ? 'বাংলা' : 'English',
              style: TextStyle(
                  color: enabled ? Colors.white : null,
                  fontWeight: FontWeight.w700))));
}

class _CaptionButton extends StatelessWidget {
  const _CaptionButton(
      {required this.icon, required this.onPressed, this.danger = false});
  final IconData icon;
  final Future<void> Function() onPressed;
  final bool danger;
  @override
  Widget build(BuildContext context) => SizedBox(
      width: 48,
      height: 56,
      child: IconButton(
          icon: Icon(icon, size: 18),
          hoverColor: danger ? Colors.red : null,
          color: danger ? null : null,
          onPressed: onPressed));
}

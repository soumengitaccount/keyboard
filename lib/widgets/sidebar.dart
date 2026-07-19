import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

import '../app/colors.dart';

class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  static const _items = <_SidebarItem>[
    _SidebarItem(
      icon: FluentIcons.home_24_regular,
      selectedIcon: FluentIcons.home_24_filled,
      title: 'General',
    ),
    _SidebarItem(
      icon: FluentIcons.keyboard_24_regular,
      selectedIcon: FluentIcons.keyboard_24_filled,
      title: 'Layout Viewer',
    ),
    _SidebarItem(
      icon: FluentIcons.book_24_regular,
      selectedIcon: FluentIcons.book_24_filled,
      title: 'Dictionary',
    ),
    _SidebarItem(
      icon: FluentIcons.color_24_regular,
      selectedIcon: FluentIcons.color_24_filled,
      title: 'Appearance',
    ),
    _SidebarItem(
      icon: FluentIcons.key_24_regular,
      selectedIcon: FluentIcons.key_24_filled,
      title: 'Hotkeys',
    ),
    _SidebarItem(
      icon: FluentIcons.info_24_regular,
      selectedIcon: FluentIcons.info_24_filled,
      title: 'About',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: dark ? AppColors.darkSidebar : AppColors.sidebar,
        border: Border(
          right: BorderSide(
            color: dark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 24,
        ),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];

          return _SidebarTile(
            item: item,
            selected: selectedIndex == index,
            onTap: () => onChanged(index),
          );
        },
      ),
    );
  }
}

class _SidebarTile extends StatefulWidget {
  final _SidebarItem item;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_SidebarTile> createState() => _SidebarTileState();
}

class _SidebarTileState extends State<_SidebarTile> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: MouseRegion(
        onEnter: (_) => setState(() => hovering = true),
        onExit: (_) => setState(() => hovering = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            height: 52,
            decoration: BoxDecoration(
              color: widget.selected
                  ? theme.colorScheme.primary.withValues(alpha: .10)
                  : hovering
                      ? theme.hoverColor
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 4,
                  height: widget.selected ? 26 : 0,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 14),
                Icon(
                  widget.selected ? widget.item.selectedIcon : widget.item.icon,
                  size: 22,
                  color: widget.selected ? theme.colorScheme.primary : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    widget.item.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          widget.selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarItem {
  final IconData icon;
  final IconData selectedIcon;
  final String title;

  const _SidebarItem({
    required this.icon,
    required this.selectedIcon,
    required this.title,
  });
}

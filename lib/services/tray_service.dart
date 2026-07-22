import 'dart:io';

import 'package:flutter/services.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

/// Small, platform-neutral system tray controller. The keyboard hook continues
/// running when the settings window is hidden, which is the expected desktop
/// keyboard-app behaviour.
class AvroTrayService with TrayListener {
  AvroTrayService._();

  static final AvroTrayService instance = AvroTrayService._();

  bool _isInitialized = false;

  Future<void> initialize() async {
    trayManager.addListener(this);
    try {
      await trayManager.setIcon('assets/keyboard.png');

      // tray_manager's Linux implementation does not expose setToolTip.
      if (!Platform.isLinux) {
        await trayManager.setToolTip('Avro Keyboard');
      }

      await trayManager.setContextMenu(Menu(items: [
        MenuItem(key: 'open', label: 'Open Avro Keyboard'),
        MenuItem.separator(),
        MenuItem(key: 'quit', label: 'Quit'),
      ]));
      _isInitialized = true;
    } on MissingPluginException {
      // The tray is optional; the main keyboard window must still start.
      trayManager.removeListener(this);
    } on PlatformException {
      // Some Linux desktop environments do not provide a status-icon host.
      trayManager.removeListener(this);
    }
  }

  Future<void> dispose() async {
    trayManager.removeListener(this);
    if (_isInitialized) {
      await trayManager.destroy();
      _isInitialized = false;
    }
  }

  @override
  void onTrayIconMouseDown() => showWindow();

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'quit') {
      dispose().whenComplete(() => exit(0));
    } else if (menuItem.key == 'open') {
      showWindow();
    }
  }

  Future<void> showWindow() async {
    await windowManager.show();
    await windowManager.focus();
  }
}

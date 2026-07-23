import Cocoa
import FlutterMacOS
import Carbon.HIToolbox

@main
class AppDelegate: FlutterAppDelegate {
  private var eventTap: CFMachPort?
  private var eventSource: CFRunLoopSource?
  private var banglaMode = true
  private var eventSink: FlutterEventSink?
  private let injectedEventMarker: Int64 = 0x4156524F
  private var liveComposition = ""
  private var liveCompositionTarget: pid_t?

  override func applicationDidFinishLaunching(_ notification: Notification) {
    guard let controller = mainFlutterWindow?.contentViewController as? FlutterViewController else { return }
    let methods = FlutterMethodChannel(name: "avro/native", binaryMessenger: controller.engine.binaryMessenger)
    methods.setMethodCallHandler { [weak self] call, result in
      guard let self else { result(FlutterError(code: "unavailable", message: "App delegate is unavailable", details: nil)); return }
      switch call.method {
      case "enableKeyboard": result(self.startTap())
      case "disableKeyboard":
        self.clearLiveComposition()
        self.stopTap()
        result(true)
      case "toggleLanguage":
        self.banglaMode = (call.arguments as? [String: Any])?["bangla"] as? Bool ?? true
        if !self.banglaMode { self.clearLiveComposition() }
        result(true)
      case "sendText":
        guard let text = (call.arguments as? [String: Any])?["text"] as? String else {
          result(FlutterError(code: "invalid_arguments", message: "sendText expects a UTF-8 string named 'text'.", details: nil))
          return
        }
        result(self.sendUnicode(text))
      case "updateComposition":
        guard let text = (call.arguments as? [String: Any])?["text"] as? String else {
          result(FlutterError(code: "invalid_arguments", message: "updateComposition expects a UTF-8 string named 'text'.", details: nil))
          return
        }
        result(self.updateLiveComposition(text))
      case "commitComposition":
        guard let text = (call.arguments as? [String: Any])?["text"] as? String else {
          result(FlutterError(code: "invalid_arguments", message: "commitComposition expects a UTF-8 string named 'text'.", details: nil))
          return
        }
        result(self.commitLiveComposition(text))
      case "cancelComposition":
        result(self.cancelLiveComposition())
      case "sendBackspace":
        result(self.sendKey(keyCode: 51))
      case "sendKey":
        guard let key = (call.arguments as? [String: Any])?["key"] as? String else {
          result(FlutterError(code: "invalid_arguments", message: "sendKey expects a key name named 'key'.", details: nil))
          return
        }
        let keyCodes: [String: CGKeyCode] = [
          "space": 49,
          "enter": 36,
          "tab": 48,
          "backspace": 51,
        ]
        guard let keyCode = keyCodes[key] else {
          result(FlutterError(code: "invalid_arguments", message: "Unsupported key: \(key)", details: nil))
          return
        }
        result(self.sendKey(keyCode: keyCode))
      case "status": result(true)
      default: result(FlutterMethodNotImplemented)
      }
    }
    let events = FlutterEventChannel(name: "avro/key_events", binaryMessenger: controller.engine.binaryMessenger)
    events.setStreamHandler(AvroStreamHandler { [weak self] sink in self?.eventSink = sink })
    super.applicationDidFinishLaunching(notification)
  }

  private func startTap() -> Bool {
    if eventTap != nil { return true }
    // macOS requires the user to grant Input Monitoring permission to this app.
    let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)
    eventTap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap, eventsOfInterest: mask, callback: { _, type, event, userInfo in
      guard type == .keyDown, let userInfo else { return Unmanaged.passUnretained(event) }
      let app = Unmanaged<AppDelegate>.fromOpaque(userInfo).takeUnretainedValue()
      if event.getIntegerValueField(.eventSourceUserData) == app.injectedEventMarker {
        return Unmanaged.passUnretained(event)
      }
      if let key = app.character(for: event) {
        guard app.banglaMode else { return Unmanaged.passUnretained(event) }
        DispatchQueue.main.async { app.eventSink?( ["key": key] ) }
        return nil
      }
      return Unmanaged.passUnretained(event)
    }, userInfo: Unmanaged.passUnretained(self).toOpaque())
    guard let eventTap else { return false }
    eventSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
    CFRunLoopAddSource(CFRunLoopGetCurrent(), eventSource, .commonModes)
    CGEvent.tapEnable(tap: eventTap, enable: true)
    return true
  }

  private func stopTap() { if let eventSource { CFRunLoopRemoveSource(CFRunLoopGetCurrent(), eventSource, .commonModes) }; eventTap = nil; eventSource = nil }

  private func character(for event: CGEvent) -> String? {
    let code = event.getIntegerValueField(.keyboardEventKeycode)
    if code == 49 { return " " }; if code == 51 { return "\u{08}" }; if code == 36 { return "\n" }; if code == 53 { return "__cancel_composition__" }
    let map: [Int64: String] = [0:"a", 1:"s", 2:"d", 3:"f", 4:"h", 5:"g", 6:"z", 7:"x", 8:"c", 9:"v", 11:"b", 12:"q", 13:"w", 14:"e", 15:"r", 16:"y", 17:"t", 31:"o", 32:"u", 34:"i", 35:"p", 37:"l", 38:"j", 40:"k", 45:"n", 46:"m"]
    return map[code]
  }

  private func foregroundProcessIdentifier() -> pid_t? {
    NSWorkspace.shared.frontmostApplication?.processIdentifier
  }

  private func updateLiveComposition(_ text: String) -> Bool {
    if !removeLiveComposition() { return false }
    guard !text.isEmpty else { return true }
    guard sendUnicode(text) else { return false }
    liveComposition = text
    liveCompositionTarget = foregroundProcessIdentifier()
    return true
  }

  private func commitLiveComposition(_ text: String) -> Bool {
    if liveComposition == text,
       liveCompositionTarget == foregroundProcessIdentifier() {
      clearLiveComposition()
      return true
    }
    guard updateLiveComposition(text) else { return false }
    clearLiveComposition()
    return true
  }

  private func cancelLiveComposition() -> Bool {
    removeLiveComposition()
  }

  private func removeLiveComposition() -> Bool {
    guard !liveComposition.isEmpty else { return true }
    guard let target = liveCompositionTarget,
          target == foregroundProcessIdentifier() else {
      clearLiveComposition()
      return true
    }
    for _ in liveComposition {
      guard sendKey(keyCode: 51) else { return false }
    }
    clearLiveComposition()
    return true
  }

  private func clearLiveComposition() {
    liveComposition = ""
    liveCompositionTarget = nil
  }

  private func sendUnicode(_ text: String) -> Bool {
    guard let event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true) else { return false }
    event.setIntegerValueField(.eventSourceUserData, value: injectedEventMarker)
    event.keyboardSetUnicodeString(stringLength: text.utf16.count, unicodeString: Array(text.utf16))
    event.post(tap: .cghidEventTap)
    return true
  }

  private func sendKey(keyCode: CGKeyCode) -> Bool {
    guard let down = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true),
          let up = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false) else { return false }
    down.setIntegerValueField(.eventSourceUserData, value: injectedEventMarker)
    up.setIntegerValueField(.eventSourceUserData, value: injectedEventMarker)
    down.post(tap: .cghidEventTap)
    up.post(tap: .cghidEventTap)
    return true
  }
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}

private final class AvroStreamHandler: NSObject, FlutterStreamHandler {
  let onListen: (FlutterEventSink?) -> Void
  init(_ onListen: @escaping (FlutterEventSink?) -> Void) { self.onListen = onListen }
  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? { onListen(events); return nil }
  func onCancel(withArguments arguments: Any?) -> FlutterError? { onListen(nil); return nil }
}

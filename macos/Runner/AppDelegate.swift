import Cocoa
import FlutterMacOS
import Carbon.HIToolbox

@main
class AppDelegate: FlutterAppDelegate {
  private var eventTap: CFMachPort?
  private var eventSource: CFRunLoopSource?
  private var banglaMode = true
  private var eventSink: FlutterEventSink?

  override func applicationDidFinishLaunching(_ notification: Notification) {
    guard let controller = mainFlutterWindow?.contentViewController as? FlutterViewController else { return }
    let methods = FlutterMethodChannel(name: "avro/native", binaryMessenger: controller.engine.binaryMessenger)
    methods.setMethodCallHandler { [weak self] call, result in
      guard let self else { result(FlutterError(code: "unavailable", message: "App delegate is unavailable", details: nil)); return }
      switch call.method {
      case "enableKeyboard": result(self.startTap())
      case "disableKeyboard": self.stopTap(); result(true)
      case "toggleLanguage":
        self.banglaMode = (call.arguments as? [String: Any])?["bangla"] as? Bool ?? true
        result(true)
      case "sendText":
        if let text = (call.arguments as? [String: Any])?["text"] as? String { self.sendUnicode(text) }
        result(true)
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
      if let key = app.character(for: event) {
        DispatchQueue.main.async { app.eventSink?( ["key": key] ) }
        return app.banglaMode ? nil : Unmanaged.passUnretained(event)
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
    if code == 49 { return " " }; if code == 51 { return "\\b" }; if code == 36 { return "\\n" }
    let map: [Int64: String] = [0:"a", 1:"s", 2:"d", 3:"f", 4:"h", 5:"g", 6:"z", 7:"x", 8:"c", 9:"v", 11:"b", 12:"q", 13:"w", 14:"e", 15:"r", 16:"y", 17:"t", 31:"o", 32:"u", 34:"i", 35:"p", 37:"l", 38:"j", 40:"k", 45:"n", 46:"m"]
    return map[code]
  }

  private func sendUnicode(_ text: String) {
    guard let event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true) else { return }
    event.keyboardSetUnicodeString(stringLength: text.utf16.count, unicodeString: Array(text.utf16))
    event.post(tap: .cghidEventTap)
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

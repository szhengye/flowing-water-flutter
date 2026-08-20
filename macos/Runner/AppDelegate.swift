import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  // 10 桌面常驻:关最后窗口**不**终止进程(隐到托盘,由 tray_manager 显隐)。
  // Flutter 默认 true 会让关窗即退出,与「关窗不死」冲突。
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false
  }

  // 托盘隐窗后点 Dock 图标 → 恢复窗口(与托盘点击同效)。
  override func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    if !flag {
      for window in sender.windows {
        window.makeKeyAndOrderFront(nil)
      }
    }
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}

import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    self.minSize = NSSize(width: 430, height: 700)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()

    self.isReleasedWhenClosed = false
  }

  override func close() {
    super.close()
    NSApplication.shared.terminate(self)
  }
}

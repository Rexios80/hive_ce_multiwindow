// AppDelegate.swift
import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
    private var statusItem: NSStatusItem?
    private var menubarPanel: NSPanel?
    private var mainWindow: NSWindow?
    private var menubarFlutterViewController: FlutterViewController?
    private var mainFlutterViewController: FlutterViewController?

    override func applicationDidFinishLaunching(_ notification: Notification) {
        launchNewWindow(initialRoute: nil, customEntryPoint: nil)
        super.applicationDidFinishLaunching(notification)
    }
    
    func launchNewWindow(initialRoute: String?, customEntryPoint: String?) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        
        let controller = FlutterViewController(
            nibName: nil,
            bundle: nil
        )
        
        // Lets setup channels
        let mainChannel = FlutterMethodChannel(
            name: "com.example.app/main",
            binaryMessenger: controller.engine.binaryMessenger
        )

        mainChannel.setMethodCallHandler { [weak self] call, result in
            // Handle main window method calls
            switch call.method {
            case "addWindow":
                if let args = call.arguments as? Dictionary<String, Any> {
                    let initialRoute = args["initialRoute"] as? String
                    let customEntryPoint = args["customEntryPoint"] as? String
                    self!.launchNewWindow(initialRoute: initialRoute, customEntryPoint: customEntryPoint)
                } else {
                    self!.launchNewWindow(initialRoute: nil, customEntryPoint: nil)
                }
                
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        
        
        window.contentViewController = controller
        window.center()  // Center the window
        window.title = "My App"
        window.makeKeyAndOrderFront(nil)
        RegisterGeneratedPlugins(registry: controller)
        
        controller.engine.run(withEntrypoint: customEntryPoint)
    }
}

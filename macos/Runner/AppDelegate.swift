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
        // Create status item in menu bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(named: NSImage.infoName)
            button.target = self
            button.action = #selector(self.toggleMenubar)
        }

        // Initialize menubar Flutter controller
        menubarFlutterViewController = FlutterViewController(
            nibName: nil,
            bundle: nil
        )

        // Create and configure menubar window
        let panelRect = NSRect(x: 0, y: 0, width: 300, height: 400)
        menubarPanel = NSPanel(
            contentRect: panelRect,
            styleMask: [.nonactivatingPanel, .borderless],  // Important for menu-like behavior
            backing: .buffered,
            defer: false
        )

        if let menubarPanel = menubarPanel {
            menubarPanel.contentViewController = menubarFlutterViewController
            menubarPanel.isReleasedWhenClosed = false
            menubarPanel.level = .popUpMenu
            menubarPanel.backgroundColor = .white
            menubarPanel.isOpaque = false
            menubarPanel.hasShadow = true

            // Panel-specific properties for menu-like behavior
            menubarPanel.isFloatingPanel = true
            menubarPanel.becomesKeyOnlyIfNeeded = true
            menubarPanel.hidesOnDeactivate = true

            // This makes it behave more like a native menu
            menubarPanel.worksWhenModal = true
        }

        if let menubarController = menubarFlutterViewController {
            let menubarChannel = FlutterMethodChannel(
                name: "com.example.app/system_tray",
                binaryMessenger: menubarController.engine.binaryMessenger
            )

            menubarChannel.setMethodCallHandler { [weak self] call, result in
                switch call.method {
                case "showMainWindow":
                    self?.mainWindow?.makeKeyAndOrderFront(nil)
                    NSApp.activate(ignoringOtherApps: true)
                    result(nil)
                default:
                    result(FlutterMethodNotImplemented)
                }
            }

            // Run menubar Flutter engine with different entry point
            menubarController.engine.run(withEntrypoint: "menubarMain")
        }
        launchNewWindow(initialRoute: nil, customEntryPoint: nil)
        RegisterGeneratedPlugins(registry: menubarFlutterViewController!)


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

    @objc func toggleMenubar(_ sender: NSButton) {
        guard let button = statusItem?.button,
            let menubarPanel = menubarPanel else {
            print("Error: Missing button or menubar window")
            return
        }

        if menubarPanel.isVisible {
            menubarPanel.orderOut(nil)  // Changed from close() to orderOut()
        } else {
            // Get the status item's frame in screen coordinates
            guard let buttonFrame = button.window?.convertToScreen(button.frame) else {
                print("Error: Could not get button frame")
                return
            }

            let w = CGFloat(300)
            let h = CGFloat(400)
            // Calculate the window position(mid of button called it)
            let windowRect = NSRect(
                x: buttonFrame.midX - w/2,
                y: buttonFrame.minY - h,
                width: w,
                height: h
            )

            menubarPanel.setFrame(windowRect, display: true)
            menubarPanel.orderFrontRegardless()

            
        

            // Make sure the window is the key window and app is active
            menubarPanel.makeKey()
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

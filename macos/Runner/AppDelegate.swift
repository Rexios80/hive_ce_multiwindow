// AppDelegate.swift
import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
    private var statusItem: NSStatusItem?
    private var menubarPanel: NSPanel?
    private var popover: NSPopover?
    private var mainWindow: NSWindow?
    private var menubarFlutterViewController: FlutterViewController?
    private var mainFlutterViewController: FlutterViewController?

    override func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize main window Flutter controller
        mainFlutterViewController = FlutterViewController(
            nibName: nil,
            bundle: nil
        )

        // Create and configure main window
        mainWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        if let mainWindow = mainWindow {
            mainWindow.contentViewController = mainFlutterViewController
            mainWindow.center()  // Center the window
            mainWindow.title = "My App"
            mainWindow.makeKeyAndOrderFront(nil)
        }

        // Create status item in menu bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(named: NSImage.infoName)
            button.target = self
            button.action = #selector(self.toggleMenubar)
        }

        let menubarProject = FlutterDartProject()
        // Initialize menubar Flutter controller with separate engine
        menubarFlutterViewController = FlutterViewController(
            engine: FlutterEngine(name: "menubar", project: menubarProject),
            initialRoute: "/test",
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

        let popover = NSPopover()
        popover.contentSize = NSSize(width: 350, height: 350)
        popover.behavior = .transient
        popover.contentViewController = menubarFlutterViewController
        self.popover = popover

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

        // Setup method channels for both controllers
        if let mainController = mainFlutterViewController {
            let mainChannel = FlutterMethodChannel(
                name: "com.example.app/main",
                binaryMessenger: mainController.engine.binaryMessenger
            )

            mainChannel.setMethodCallHandler { [weak self] call, result in
                // Handle main window method calls
                result(FlutterMethodNotImplemented)
            }
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

        RegisterGeneratedPlugins(registry: mainFlutterViewController!)
        RegisterGeneratedPlugins(registry: menubarFlutterViewController!)
        

        super.applicationDidFinishLaunching(notification)
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

                    let w = CGFloat(250)
                    let h = CGFloat(250)
                    // Calculate the window position(mid of button called it)
                    let windowRect = NSRect(
                        x: buttonFrame.midX - w/2,
                        y: buttonFrame.minY - h,
                        width: w,
                        height: h
                    )

                    menubarPanel.setFrame(windowRect, display: true)
                    menubarPanel.orderFrontRegardless()

                    // Set the window frame and show it
                    menubarPanel.setFrame(windowRect, display: true)
                    menubarPanel.makeKeyAndOrderFront(nil)
                    menubarPanel.orderFront(nil)

                    // Make sure the window is the key window and app is active
                    menubarPanel.makeKey()
                    NSApp.activate(ignoringOtherApps: true)
                }
    }
}

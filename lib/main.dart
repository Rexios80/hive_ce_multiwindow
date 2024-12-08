import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize window manager
  await windowManager.ensureInitialized();

  // Setup window options
  WindowOptions windowOptions = const WindowOptions(
    size: Size(800, 600),
    center: true,
    title: "My MacOS App",
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // Create platform channel for communicating with native code
  const platform = MethodChannel('com.example.app/system_tray');

  // Initialize both the main window and menubar window
  runApp(const MainApp());

  // Setup method call handler for platform channel
  platform.setMethodCallHandler((call) async {
    if (call.method == 'showMainWindow') {
      await windowManager.show();
      await windowManager.focus();
    }
  });
}

@pragma('vm:entry-point')
void menubarMain() {
  // Menu bar entry point
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MenuBarWindow());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Main Window'),
        ),
        body: Center(
          child: Column(
            children: [
              const Text('Hello from the main window!'),
              MaterialButton(
                  onPressed: () {
                    // Call the platform channel to show the main window
                    const platform = MethodChannel('com.example.app/main');
                    platform.invokeMethod('addWindow', {"initialRoute": "/test123"});
                  },
                  child: Text("Launch new window"))
            ],
          ),
        ),
      ),
    );
  }
}

// menubar_window.dart

class MenuBarWindow extends StatelessWidget {
  const MenuBarWindow({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Container(width: 300, color: Colors.white, child: Text("Hello from topbar menu")),
    );
  }
}

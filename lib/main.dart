import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  await IsolatedHive.initFlutter();
  final box = await IsolatedHive.openBox('counter');

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

  final count = await box.get(0, defaultValue: 0);

  // Initialize both the main window and menubar window
  runApp(MainApp(initialCount: count));

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
  final box = IsolatedHive.box('counter');
  final int initialCount;

  MainApp({super.key, required this.initialCount});

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
                  platform
                      .invokeMethod('addWindow', {"initialRoute": "/test123"});
                },
                child: Text("Launch new window"),
              ),
              StreamBuilder<int>(
                initialData: initialCount,
                stream: box.watch().map((event) => event.value),
                builder: (context, snap) => Text('${snap.data}'),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final current = await box.get(0, defaultValue: 0);
            await box.put(0, current + 1);
          },
          child: const Icon(Icons.add),
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
      home: Container(
          width: 300,
          color: Colors.white,
          child: Text("Hello from topbar menu")),
    );
  }
}

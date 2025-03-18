import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await IsolatedHive.initFlutter();
  final box = await IsolatedHive.openBox('counter');

  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(800, 600),
    center: true,
    title: 'My MacOS App',
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  final count = await box.get(0, defaultValue: 0);
  runApp(MainApp(initialCount: count));

  const platform = MethodChannel('com.example.app/system_tray');
  platform.setMethodCallHandler((call) async {
    if (call.method == 'showMainWindow') {
      await windowManager.show();
      await windowManager.focus();
    }
  });
}

class MainApp extends StatelessWidget {
  final box = IsolatedHive.box('counter');
  final int initialCount;

  MainApp({super.key, required this.initialCount});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Main Window')),
        body: Center(
          child: Column(
            children: [
              const Text('Hello from the main window!'),
              MaterialButton(
                onPressed: () {
                  // Call the platform channel to show the main window
                  const platform = MethodChannel('com.example.app/main');
                  platform.invokeMethod('addWindow', {
                    'initialRoute': '/test123',
                  });
                },
                child: const Text('Launch new window'),
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

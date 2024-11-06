import 'package:flutter/material.dart';
import 'package:flutter_fitness/model.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final PedometerService pedometerService = PedometerService();

  @override
  void initState() {
    super.initState();
    pedometerService.initializePedometer();
  }

  @override
  void dispose() {
    pedometerService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text("Step Counter App")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Steps since last reset:",
                  style: TextStyle(fontSize: 20)),
              const SizedBox(height: 10),
              ValueListenableBuilder<int>(
                valueListenable: pedometerService.stepsSinceLastReset,
                builder: (context, steps, child) {
                  return Text(
                    steps.toString(),
                    style: const TextStyle(
                        fontSize: 36, fontWeight: FontWeight.bold),
                  );
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => pedometerService.resetStepCounter(),
                child: const Text("Manual Reset"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

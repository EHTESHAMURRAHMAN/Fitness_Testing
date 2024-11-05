import 'package:flutter/material.dart';
import 'dart:async';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Stream<StepCount> _stepCountStream;
  int _currentSteps = 0;
  String _steps = '0';
  String _lastSavedDate = '';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  void onStepCount(StepCount event) {
    _currentSteps = event.steps;
    _updateStepsData();
  }

  Future<void> _updateStepsData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String today = DateTime.now().toIso8601String().substring(0, 10);
    String? lastDate = prefs.getString('lastSavedDate');

    if (lastDate == null || lastDate != today) {
      if (lastDate != null) {
        await prefs.setInt('steps_$lastDate', _currentSteps);
      }
      await prefs.setString('lastSavedDate', today);
      _currentSteps = 0;
    }

    await prefs.setInt('steps_$today', _currentSteps);
    setState(() {
      _steps = _currentSteps.toString();
    });
  }

  Future<int> getStepsFromSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String today = DateTime.now().toIso8601String().substring(0, 10);
    int steps = prefs.getInt('steps_$today') ?? 0;
    return steps;
  }

  Future<void> initPlatformState() async {
    bool granted = await _checkActivityRecognitionPermission();
    if (!granted) {
      return;
    }

    _stepCountStream = Pedometer.stepCountStream;
    _stepCountStream.listen(onStepCount);
  }

  Future<bool> _checkActivityRecognitionPermission() async {
    bool granted = await Permission.activityRecognition.isGranted;
    if (!granted) {
      granted = await Permission.activityRecognition.request() ==
          PermissionStatus.granted;
    }
    return granted;
  }

  Future<void> _refreshData() async {
    setState(() {
      _currentSteps = 0;
      _steps = '0';
    });
    await getStepsFromSharedPreferences();
  }

  Future<void> _deleteData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String today = DateTime.now().toIso8601String().substring(0, 10);

    await prefs.remove('steps_$today'); // Remove today's steps
    await prefs.remove('lastSavedDate'); // Remove last saved date
    setState(() {
      _steps = '0'; // Reset displayed steps
    });
    print('Data deleted for today: $today');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
            appBar: AppBar(title: const Text('Pedometer Example')),
            body: Center(
                child: FutureBuilder<int>(
                    future: getStepsFromSharedPreferences(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else {
                        return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              const Text('Steps Today',
                                  style: TextStyle(fontSize: 30)),
                              Text(snapshot.data.toString(),
                                  style: const TextStyle(fontSize: 60)),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                  onPressed: _refreshData,
                                  child: const Text('Refresh Steps')),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                  onPressed: _deleteData,
                                  child: const Text('Delete Data'),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red))
                            ]);
                      }
                    }))));
  }
}

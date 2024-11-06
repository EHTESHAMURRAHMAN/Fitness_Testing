import 'package:flutter/material.dart';
import 'package:flutter_fitness/model.dart';

class PedometerPage extends StatefulWidget {
  @override
  _PedometerPageState createState() => _PedometerPageState();
}

class _PedometerPageState extends State<PedometerPage> {
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
    return Scaffold(
      appBar: AppBar(title: Text('Pedometer Service')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          ValueListenableBuilder<int>(
            valueListenable: pedometerService.stepsSinceLastReset,
            builder: (context, steps, _) {
              return Text('Steps: $steps');
            },
          ),
          ValueListenableBuilder<double>(
            valueListenable: pedometerService.caloriesSinceLastReset,
            builder: (context, calories, _) {
              return Text('Calories: $calories');
            },
          ),
          ValueListenableBuilder<int>(
            valueListenable: pedometerService.walkTimeInMinutes,
            builder: (context, time, _) {
              return Text('Walk Time: $time minutes');
            },
          ),
          ElevatedButton(
            onPressed: () async {
              await pedometerService.saveDataAndReset();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Data reset successfully')),
              );
            },
            child: Text('Reset Data'),
          ),
        ],
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: PedometerPage(),
  ));
}

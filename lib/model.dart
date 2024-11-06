import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PedometerService {
  int baselineStepCount = 0;
  int currentStepCount = 0;
  Timer? resetTimer;

  ValueNotifier<int> stepsSinceLastReset = ValueNotifier(0);

  Future<void> initializePedometer() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    baselineStepCount = prefs.getInt('baselineStepCount') ?? 0;

    Pedometer.stepCountStream.listen(
      (StepCount stepCount) {
        currentStepCount = stepCount.steps;
        stepsSinceLastReset.value = currentStepCount - baselineStepCount;
      },
      onError: (error) {
        print("Pedometer error: $error");
      },
    );

    startResetTimer();
  }

  void startResetTimer() {
    resetTimer?.cancel();
    resetTimer = Timer.periodic(Duration(minutes: 5), (timer) async {
      await resetStepCounter();
    });
  }

  // Manual reset function to reset the baseline step count
  Future<void> resetStepCounter() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    baselineStepCount = currentStepCount;
    await prefs.setInt('baselineStepCount', baselineStepCount);
    stepsSinceLastReset.value = 0; // Reset the displayed steps
    print("5-minute reset. New baseline: $baselineStepCount");
  }

  // Call this method when you want to stop the timer, e.g., on app exit
  void dispose() {
    resetTimer?.cancel();
    stepsSinceLastReset.dispose();
  }
}

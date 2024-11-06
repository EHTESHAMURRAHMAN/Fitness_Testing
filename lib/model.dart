import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class PedometerService {
  int baselineStepCount = 0;
  int currentStepCount = 0;
  ValueNotifier<int> stepsSinceLastReset = ValueNotifier(0);
  ValueNotifier<double> caloriesSinceLastReset = ValueNotifier(0.0);
  ValueNotifier<int> walkTimeInMinutes = ValueNotifier(0);
  String? todayDate;

  final double kcalPerStep = 0.04;
  final int stepsPerMinute = 100;

  Future<void> initializePedometer() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    baselineStepCount = prefs.getInt('baselineStepCount') ?? 0;
    todayDate = prefs.getString('lastResetDate') ?? getCurrentDate();

    if (todayDate != getCurrentDate()) {
      await saveDataAndReset();
    }

    Pedometer.stepCountStream.listen(
      (StepCount stepCount) {
        currentStepCount = stepCount.steps;
        stepsSinceLastReset.value = currentStepCount - baselineStepCount;

        caloriesSinceLastReset.value = stepsSinceLastReset.value * kcalPerStep;
        walkTimeInMinutes.value = stepsSinceLastReset.value ~/ stepsPerMinute;

        if (todayDate != getCurrentDate()) {
          saveDataAndReset();
        }
      },
      onError: (error) {
        print("Pedometer error: $error");
      },
    );
  }

  String getCurrentDate() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  Future<void> saveDataAndReset() async {
    int stepsToSave = stepsSinceLastReset.value;
    double caloriesToSave = caloriesSinceLastReset.value;
    int walkTimeToSave = walkTimeInMinutes.value;

    bool isSaved =
        await saveDataToApi(stepsToSave, caloriesToSave, walkTimeToSave);

    if (isSaved) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      baselineStepCount = currentStepCount;
      stepsSinceLastReset.value = 0;
      caloriesSinceLastReset.value = 0.0;
      walkTimeInMinutes.value = 0;

      await prefs.setInt('baselineStepCount', baselineStepCount);
      todayDate = getCurrentDate();
      await prefs.setString('lastResetDate', todayDate!);

      print("Data saved for yesterday and reset for the new day.");
    } else {
      print("Failed to save data to API.");
    }
  }

  Future<bool> saveDataToApi(int steps, double calories, int walkTime) async {
    try {
      final response = await http.post(
        Uri.parse('https://health.tixcash.org/api/account/updatestepdata'),
        headers: {'Content-Type': 'application/json'},
        body: '{"steps": $steps, "kcal": $calories, "min": $walkTime}',
      );

      if (response.statusCode == 200) {
        print("Data saved to API successfully.");
        return true;
      } else {
        print(
            "Failed to save data to API. Status code: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("Error saving data to API: $e");
      return false;
    }
  }

  void dispose() {
    stepsSinceLastReset.dispose();
    caloriesSinceLastReset.dispose();
    walkTimeInMinutes.dispose();
  }
}

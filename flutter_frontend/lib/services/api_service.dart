import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/models.dart';

class ApiService {
  // --- 1. ÜBUNGEN ---
  static Future<List<Exercise>> getExercises() async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/exercises'),
    );
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => Exercise.fromJson(json)).toList();
    }
    throw Exception('Fehler beim Laden der Übungen');
  }

  static Future<void> createCustomExercise(String name, String muscleGroup) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/exercises'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'name': name,
        'muscle_group': muscleGroup,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Fehler beim Erstellen der Übung');
    }
  }

  // --- 2. WORKOUTS ---
  static Future<void> saveWorkoutSet({
    required int exerciseId,
    required double weightKg,
    required int reps,
    String setType = 'normal',
    String notes = '',
  }) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/workouts'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'exercise_id': exerciseId,
        'weight_kg': weightKg,
        'reps': reps,
        'set_type': setType,
        'notes': notes,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Fehler beim Speichern des Sets');
    }
  }

  // --- 3. STATISTIKEN ---
  static Future<List<dynamic>> getWeeklyDashboard() async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/dashboard/weekly'),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Fehler beim Laden des Dashboards');
  }

  static Future<RankingStats> getRanking(int exerciseId) async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/stats/ranking/$exerciseId'),
    );
    if (response.statusCode == 200) {
      return RankingStats.fromJson(json.decode(response.body));
    }
    throw Exception('Fehler beim Laden des Rankings');
  }

  static Future<Map<String, dynamic>?> getPersonalRecord(int exerciseId) async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/stats/pr/$exerciseId'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['max_weight'] == null) return null;
      return data;
    }
    throw Exception('Fehler beim Laden des PRs');
  }

  static Future<List<dynamic>> getExerciseHistory(int exerciseId) async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/history/$exerciseId'),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Fehler beim Laden der Historie');
  }

  static Future<List<dynamic>> getMuscleDistribution() async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/stats/distribution'),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Fehler beim Laden der Verteilung');
  }

  // --- 4. KÖRPERDATEN ---
  static Future<void> saveMeasurement(String type, double value) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/measurements'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'type': type,
        'value': value,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Fehler beim Speichern der Körperdaten');
    }
  }

  static Future<List<Measurement>> getMeasurements(String type) async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/measurements/$type'),
    );
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => Measurement.fromJson(json)).toList();
    }
    throw Exception('Fehler beim Laden der Körperdaten');
  }
}
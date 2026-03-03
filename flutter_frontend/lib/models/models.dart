class Exercise {
  final int id;
  final String name;
  final String muscleGroup;
  final int defaultRestSeconds;
  final String description;
  final String tips;
  final String imageUrl;

  Exercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    required this.defaultRestSeconds,
    this.description = '',
    this.tips = '',
    this.imageUrl = '',
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'],
      name: json['name'],
      muscleGroup: json['muscle_group'],
      defaultRestSeconds: json['default_rest_seconds'] ?? 90,
      description: json['description'] ?? 'Keine Beschreibung verfügbar.',
      tips: json['tips'] ?? 'Keine Tipps hinterlegt.',
      imageUrl: json['image_url'] ?? '',
    );
  }
}

class Workout {
  final int id;
  final int exerciseId;
  final double weightKg;
  final int reps;
  final String setType;
  final String date;
  final String notes;

  Workout({
    required this.id,
    required this.exerciseId,
    required this.weightKg,
    required this.reps,
    required this.setType,
    required this.date,
    required this.notes,
  });

  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      id: json['id'],
      exerciseId: json['exercise_id'],
      weightKg: (json['weight_kg'] as num).toDouble(),
      reps: json['reps'],
      setType: json['set_type'] ?? 'normal',
      date: json['date'],
      notes: json['notes'] ?? '',
    );
  }
}

class Routine {
  final int id;
  final String name;

  Routine({required this.id, required this.name});

  factory Routine.fromJson(Map<String, dynamic> json) {
    return Routine(id: json['id'], name: json['name']);
  }
}

class Measurement {
  final int id;
  final String type;
  final double value;
  final String date;

  Measurement({
    required this.id,
    required this.type,
    required this.value,
    required this.date,
  });

  factory Measurement.fromJson(Map<String, dynamic> json) {
    return Measurement(
      id: json['id'],
      type: json['type'],
      value: (json['value'] as num).toDouble(),
      date: json['date'],
    );
  }
}

class RankingStats {
  final String rank;
  final String percentile;
  final String icon;

  RankingStats({
    required this.rank,
    required this.percentile,
    required this.icon,
  });

  factory RankingStats.fromJson(Map<String, dynamic> json) {
    return RankingStats(
      rank: json['rank'] ?? 'Unrated',
      percentile: json['percentile'] ?? '-',
      icon: json['icon'] ?? 'grey_circle',
    );
  }
}
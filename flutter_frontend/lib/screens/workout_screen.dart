import 'dart:async';
import 'package:flutter/material.dart';
import '../core/settings_manager.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class ActiveSet {
  final TextEditingController weightController;
  final TextEditingController repsController;
  bool isCompleted;

  ActiveSet({
    required this.weightController,
    required this.repsController,
    this.isCompleted = false,
  });
}

class ActiveExerciseTracker {
  final Exercise exercise;
  final List<ActiveSet> sets;

  ActiveExerciseTracker({required this.exercise, required this.sets});
}

class WorkoutScreen extends StatefulWidget {
  final VoidCallback? onRestTimerDone;

  const WorkoutScreen({super.key, this.onRestTimerDone});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  Timer? _timer;
  int _secondsElapsed = 0;

  // Rest Timer
  Timer? _restTimer;
  int _restSecondsLeft = 0;
  int _restTotalSeconds = 0;
  bool _restTimerActive = false;

  List<Exercise> _allExercises = [];
  bool _isLoading = true;
  final List<ActiveExerciseTracker> _activeWorkout = [];

  @override
  void initState() {
    super.initState();
    _loadLibrary();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _restTimer?.cancel();
    _disposeAllControllers();
    super.dispose();
  }

  void _disposeAllControllers() {
    for (var tracker in _activeWorkout) {
      for (var set in tracker.sets) {
        set.weightController.dispose();
        set.repsController.dispose();
      }
    }
  }

  void _startRestTimer(int durationSeconds) {
    _restTimer?.cancel();
    setState(() {
      _restTotalSeconds = durationSeconds;
      _restSecondsLeft = durationSeconds;
      _restTimerActive = true;
    });
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restSecondsLeft <= 1) {
        timer.cancel();
        setState(() {
          _restTimerActive = false;
          _restSecondsLeft = 0;
        });
        widget.onRestTimerDone?.call();
      } else {
        setState(() {
          _restSecondsLeft--;
        });
      }
    });
  }

  void _skipRestTimer() {
    _restTimer?.cancel();
    setState(() {
      _restTimerActive = false;
      _restSecondsLeft = 0;
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsElapsed++;
      });
    });
  }

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _loadLibrary() async {
    try {
      final exercises = await ApiService.getExercises();
      setState(() {
        _allExercises = exercises;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addExerciseToWorkout(Exercise exercise) {
    if (_timer == null || !_timer!.isActive) {
      _startTimer();
    }

    setState(() {
      _activeWorkout.add(
        ActiveExerciseTracker(
          exercise: exercise,
          sets: [
            ActiveSet(
              weightController: TextEditingController(),
              repsController: TextEditingController(),
            ),
          ],
        ),
      );
    });
    Navigator.pop(context);
  }

  void _addSetToExercise(int exerciseIndex) {
    setState(() {
      _activeWorkout[exerciseIndex].sets.add(
        ActiveSet(
          weightController: TextEditingController(),
          repsController: TextEditingController(),
        ),
      );
    });
  }

  Future<void> _completeSet(int exerciseIndex, int setIndex) async {
    final activeSet = _activeWorkout[exerciseIndex].sets[setIndex];
    if (activeSet.isCompleted) return;

    final weightText = activeSet.weightController.text;
    final repsText = activeSet.repsController.text;

    if (weightText.isEmpty || repsText.isEmpty) return;

    final weight = double.tryParse(weightText) ?? 0.0;
    final reps = int.tryParse(repsText) ?? 0;

    // Wenn Pfund eingestellt, vor dem Speichern in kg umrechnen
    final weightKg = settingsManager.useKg ? weight : weight * 0.45359237;

    try {
      await ApiService.saveWorkoutSet(
        exerciseId: _activeWorkout[exerciseIndex].exercise.id,
        weightKg: weightKg,
        reps: reps,
      );

      setState(() {
        activeSet.isCompleted = true;
      });
      _startRestTimer(
        _activeWorkout[exerciseIndex].exercise.defaultRestSeconds,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fehler beim Speichern des Satzes'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddExerciseSheet() {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final cardColor = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;
    final subtitleColor = theme.textTheme.bodySmall?.color ?? Colors.grey;
    final fillColor = theme.inputDecorationTheme.fillColor ?? cardColor;

    final TextEditingController searchController = TextEditingController();
    List<Exercise> filteredExercises = List.from(_allExercises);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.8,
              maxChildSize: 0.9,
              minChildSize: 0.5,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: theme.dividerColor),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Übung auswählen',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Übung suchen...',
                          prefixIcon: Icon(Icons.search, color: subtitleColor),
                          filled: true,
                          fillColor: fillColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) {
                          setSheetState(() {
                            filteredExercises = _allExercises
                                .where(
                                  (ex) => ex.name.toLowerCase().contains(
                                    value.toLowerCase(),
                                  ),
                                )
                                .toList();
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: filteredExercises.length,
                        itemBuilder: (context, index) {
                          final ex = filteredExercises[index];
                          return ListTile(
                            leading: Icon(
                              Icons.fitness_center,
                              color: primaryColor,
                            ),
                            title: Text(
                              ex.name,
                              style: TextStyle(color: textColor),
                            ),
                            subtitle: Text(
                              ex.muscleGroup,
                              style: TextStyle(color: subtitleColor),
                            ),
                            onTap: () => _addExerciseToWorkout(ex),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _finishWorkout() {
    _timer?.cancel();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Workout gespeichert!'),
        backgroundColor: Colors.green,
      ),
    );
    setState(() {
      _secondsElapsed = 0;
      _disposeAllControllers();
      _activeWorkout.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settingsManager,
      builder: (context, _) {
        final theme = Theme.of(context);
        final primaryColor = theme.colorScheme.primary;
        final cardColor = theme.colorScheme.surface;
        final textColor = theme.colorScheme.onSurface;
        final subtitleColor = theme.textTheme.bodySmall?.color ?? Colors.grey;
        final fillColor = theme.inputDecorationTheme.fillColor ?? cardColor;

        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: Column(
              children: [
                Text(
                  'Aktives Workout',
                  style: TextStyle(fontSize: 14, color: subtitleColor),
                ),
                Text(
                  _formatTime(_secondsElapsed),
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 10.0,
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _activeWorkout.isEmpty ? null : _finishWorkout,
                  child: const Text(
                    'Workout speichern',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: _isLoading
              ? Center(child: CircularProgressIndicator(color: primaryColor))
              : Stack(
                  children: [
                    ListView(
                      padding: const EdgeInsets.all(16.0),
                      children: [
                        ..._activeWorkout.asMap().entries.map((entry) {
                          int exIndex = entry.key;
                          ActiveExerciseTracker tracker = entry.value;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 24),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Exercise Header
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${exIndex + 1}. ${tracker.exercise.name}',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      icon: Icon(
                                        Icons.more_vert,
                                        color: subtitleColor,
                                      ),
                                      color: theme.scaffoldBackgroundColor,
                                      onSelected: (value) {
                                        if (value == 'remove') {
                                          setState(() {
                                            _activeWorkout.removeAt(exIndex);
                                          });
                                        }
                                      },
                                      itemBuilder: (BuildContext context) =>
                                          <PopupMenuEntry<String>>[
                                            const PopupMenuItem<String>(
                                              value: 'remove',
                                              child: Text(
                                                'Übung entfernen',
                                                style: TextStyle(
                                                  color: Colors.redAccent,
                                                ),
                                              ),
                                            ),
                                          ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Table Header
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 40,
                                      child: Center(
                                        child: Text(
                                          'Satz',
                                          style: TextStyle(
                                            color: subtitleColor,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Center(
                                        child: Text(
                                          settingsManager.useKg ? 'kg' : 'lbs',
                                          style: TextStyle(
                                            color: subtitleColor,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Center(
                                        child: Text(
                                          'Wdh',
                                          style: TextStyle(
                                            color: subtitleColor,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 50),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Sets List
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: tracker.sets.length,
                                  itemBuilder: (context, setIndex) {
                                    final activeSet = tracker.sets[setIndex];
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      decoration: BoxDecoration(
                                        color: activeSet.isCompleted
                                            ? Colors.green.withValues(
                                                alpha: 0.1,
                                              )
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 40,
                                            child: Center(
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: fillColor,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  '${setIndex + 1}',
                                                  style: TextStyle(
                                                    color: textColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8.0,
                                                  ),
                                              child: TextField(
                                                controller:
                                                    activeSet.weightController,
                                                keyboardType:
                                                    TextInputType.number,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: textColor,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                enabled: !activeSet.isCompleted,
                                                decoration: InputDecoration(
                                                  filled: true,
                                                  fillColor:
                                                      activeSet.isCompleted
                                                      ? Colors.transparent
                                                      : fillColor,
                                                  contentPadding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 10,
                                                      ),
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    borderSide: BorderSide.none,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8.0,
                                                  ),
                                              child: TextField(
                                                controller:
                                                    activeSet.repsController,
                                                keyboardType:
                                                    TextInputType.number,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: textColor,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                enabled: !activeSet.isCompleted,
                                                decoration: InputDecoration(
                                                  filled: true,
                                                  fillColor:
                                                      activeSet.isCompleted
                                                      ? Colors.transparent
                                                      : fillColor,
                                                  contentPadding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 10,
                                                      ),
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    borderSide: BorderSide.none,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 50,
                                            child: Center(
                                              child: IconButton(
                                                icon: Icon(
                                                  Icons.check_box,
                                                  color: activeSet.isCompleted
                                                      ? Colors.green
                                                      : subtitleColor,
                                                  size: 32,
                                                ),
                                                onPressed: () => _completeSet(
                                                  exIndex,
                                                  setIndex,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),

                                // Add Set Button
                                TextButton.icon(
                                  onPressed: () => _addSetToExercise(exIndex),
                                  icon: Icon(
                                    Icons.add,
                                    color: subtitleColor,
                                    size: 20,
                                  ),
                                  label: Text(
                                    'Satz hinzufügen',
                                    style: TextStyle(
                                      color: subtitleColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                        // Add Exercise Button (Global)
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: primaryColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _showAddExerciseSheet,
                          icon: Icon(Icons.add, color: primaryColor),
                          label: Text(
                            'Übung hinzufügen',
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),

                    // Rest Timer Overlay
                    if (_restTimerActive)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: _RestTimerBanner(
                          secondsLeft: _restSecondsLeft,
                          totalSeconds: _restTotalSeconds,
                          primaryColor: primaryColor,
                          onSkip: _skipRestTimer,
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }
}

class _RestTimerBanner extends StatelessWidget {
  final int secondsLeft;
  final int totalSeconds;
  final Color primaryColor;
  final VoidCallback onSkip;

  const _RestTimerBanner({
    required this.secondsLeft,
    required this.totalSeconds,
    required this.primaryColor,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalSeconds > 0 ? secondsLeft / totalSeconds : 0.0;
    final minutes = secondsLeft ~/ 60;
    final seconds = secondsLeft % 60;
    final timeStr =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.timer, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Satzpause',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                timeStr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: onSkip,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Überspringen',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import '../core/constants.dart';
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

  ActiveExerciseTracker({
    required this.exercise,
    required this.sets,
  });
}

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  Timer? _timer;
  int _secondsElapsed = 0;
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
            )
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

    try {
      await ApiService.saveWorkoutSet(
        exerciseId: _activeWorkout[exerciseIndex].exercise.id,
        weightKg: weight,
        reps: reps,
      );

      setState(() {
        activeSet.isCompleted = true;
      });
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
    final TextEditingController searchController = TextEditingController();
    List<Exercise> filteredExercises = List.from(_allExercises);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.backgroundDark,
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
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.white10)),
                      ),
                      child: const Center(
                        child: Text(
                          'Übung auswählen',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        controller: searchController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Übung suchen...',
                          hintStyle: const TextStyle(color: Colors.grey),
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          filled: true,
                          fillColor: AppConstants.cardDark,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) {
                          setSheetState(() {
                            filteredExercises = _allExercises
                                .where((ex) => ex.name.toLowerCase().contains(value.toLowerCase()))
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
                            leading: const Icon(Icons.fitness_center, color: AppConstants.primaryOrange),
                            title: Text(ex.name, style: const TextStyle(color: Colors.white)),
                            subtitle: Text(ex.muscleGroup, style: const TextStyle(color: Colors.grey)),
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppConstants.backgroundDark,
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            const Text(
              'Aktives Workout',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            Text(
              _formatTime(_secondsElapsed),
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppConstants.primaryOrange),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryOrange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _activeWorkout.isEmpty ? null : _finishWorkout,
              child: const Text('Workout speichern', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppConstants.primaryOrange))
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                ..._activeWorkout.asMap().entries.map((entry) {
                  int exIndex = entry.key;
                  ActiveExerciseTracker tracker = entry.value;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppConstants.cardDark,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Exercise Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${exIndex + 1}. ${tracker.exercise.name}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppConstants.primaryOrange),
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, color: Colors.grey),
                              color: AppConstants.backgroundDark,
                              onSelected: (value) {
                                if (value == 'remove') {
                                  setState(() {
                                    _activeWorkout.removeAt(exIndex);
                                  });
                                }
                              },
                              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                const PopupMenuItem<String>(
                                  value: 'remove',
                                  child: Text('Übung entfernen', style: TextStyle(color: Colors.redAccent)),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Table Header
                        const Row(
                          children: [
                            SizedBox(width: 40, child: Center(child: Text('Satz', style: TextStyle(color: Colors.grey, fontSize: 14)))),
                            Expanded(child: Center(child: Text('kg', style: TextStyle(color: Colors.grey, fontSize: 14)))),
                            Expanded(child: Center(child: Text('Wdh', style: TextStyle(color: Colors.grey, fontSize: 14)))),
                            SizedBox(width: 50),
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
                                color: activeSet.isCompleted ? Colors.green.withOpacity(0.1) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 40,
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[800],
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '${setIndex + 1}',
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                      child: TextField(
                                        controller: activeSet.weightController,
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                        enabled: !activeSet.isCompleted,
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: activeSet.isCompleted ? Colors.transparent : Colors.grey[850],
                                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                      child: TextField(
                                        controller: activeSet.repsController,
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                        enabled: !activeSet.isCompleted,
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: activeSet.isCompleted ? Colors.transparent : Colors.grey[850],
                                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
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
                                          color: activeSet.isCompleted ? Colors.green : Colors.grey[600],
                                          size: 32,
                                        ),
                                        onPressed: () => _completeSet(exIndex, setIndex),
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
                          icon: const Icon(Icons.add, color: Colors.grey, size: 20),
                          label: const Text('Satz hinzufügen', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                }),

                // Add Exercise Button (Global)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppConstants.primaryOrange),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _showAddExerciseSheet,
                  icon: const Icon(Icons.add, color: AppConstants.primaryOrange),
                  label: const Text(
                    'Übung hinzufügen',
                    style: TextStyle(color: AppConstants.primaryOrange, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
    );
  }
}
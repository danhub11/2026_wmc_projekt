import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<Exercise> _allExercises = [];
  List<Exercise> _filteredExercises = [];
  List<String> _backendMuscleGroups = [];
  String _selectedMuscleGroup = 'All';
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  final Map<String, String> _muscleTranslations = {
    'All': 'Alle',
    'Chest': 'Brust',
    'Back': 'Rücken',
    'Legs': 'Beine',
    'Shoulders': 'Schultern',
    'Arms': 'Arme',
    'Core': 'Bauch',
    'Cardio': 'Cardio',
    'Full Body': 'Ganzkörper',
  };

  @override
  void initState() {
    super.initState();
    _loadExercises();
    _searchController.addListener(_filterExercises);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _translateMuscle(String backendGroup) {
    return _muscleTranslations[backendGroup] ?? backendGroup;
  }

  Future<void> _loadExercises() async {
    try {
      final exercises = await ApiService.getExercises();
      final groups = exercises.map((e) => e.muscleGroup).toSet().toList();
      groups.sort();
      groups.insert(0, 'All');

      setState(() {
        _allExercises = exercises;
        _filteredExercises = exercises;
        _backendMuscleGroups = groups;
        _isLoading = false;
      });
      _filterExercises();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _filterExercises() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredExercises = _allExercises.where((exercise) {
        final matchesSearch = exercise.name.toLowerCase().contains(query);
        final matchesGroup =
            _selectedMuscleGroup == 'All' ||
            exercise.muscleGroup == _selectedMuscleGroup;
        return matchesSearch && matchesGroup;
      }).toList();
    });
  }

  void _showExerciseDetails(Exercise exercise) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final cardColor = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;
    final subtitleColor = theme.textTheme.bodySmall?.color ?? Colors.grey;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.4,
          maxChildSize: 0.8,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.dividerColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    exercise.name,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _translateMuscle(exercise.muscleGroup),
                    style: TextStyle(
                      fontSize: 16,
                      color: primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Beschreibung',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    exercise.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: subtitleColor,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Tipps zur Ausführung',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      exercise.tips,
                      style: TextStyle(
                        fontSize: 16,
                        color: textColor,
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showAddExerciseDialog() async {
    final nameController = TextEditingController();
    String selectedGroup = 'Chest';
    final List<String> availableGroups = [
      'Arms',
      'Back',
      'Cardio',
      'Chest',
      'Core',
      'Full Body',
      'Legs',
      'Shoulders',
    ];

    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final cardColor = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;
    final subtitleColor = theme.textTheme.bodySmall?.color ?? Colors.grey;
    final bgColor = theme.scaffoldBackgroundColor;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Neue Übung',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: 'Name der Übung',
                labelStyle: TextStyle(color: subtitleColor),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: primaryColor),
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedGroup,
              dropdownColor: bgColor,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: 'Muskelgruppe',
                labelStyle: TextStyle(color: subtitleColor),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
              ),
              items: availableGroups
                  .map(
                    (g) => DropdownMenuItem(
                      value: g,
                      child: Text(_translateMuscle(g)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) selectedGroup = value;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Abbrechen', style: TextStyle(color: subtitleColor)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                Navigator.pop(context);
                setState(() => _isLoading = true);
                await ApiService.createCustomExercise(
                  nameController.text,
                  selectedGroup,
                );
                await _loadExercises();
              }
            },
            child: const Text(
              'Speichern',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final cardColor = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;
    final subtitleColor = theme.textTheme.bodySmall?.color ?? Colors.grey;
    final fillColor = theme.inputDecorationTheme.fillColor ?? cardColor;

    return Scaffold(
      appBar: AppBar(title: const Text('Übungen')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Übung suchen...',
                      prefixIcon: Icon(Icons.search, color: subtitleColor),
                      filled: true,
                      fillColor: fillColor,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: _backendMuscleGroups.length,
                    itemBuilder: (context, index) {
                      final group = _backendMuscleGroups[index];
                      final isSelected = group == _selectedMuscleGroup;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(_translateMuscle(group)),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedMuscleGroup = group);
                              _filterExercises();
                            }
                          },
                          selectedColor: primaryColor.withValues(alpha: 0.2),
                          backgroundColor: cardColor,
                          labelStyle: TextStyle(
                            color: isSelected ? primaryColor : subtitleColor,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected
                                  ? primaryColor
                                  : Colors.transparent,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: _filteredExercises.length,
                    separatorBuilder: (context, index) =>
                        Divider(color: theme.dividerColor, height: 1),
                    itemBuilder: (context, index) {
                      final exercise = _filteredExercises[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                        leading: CircleAvatar(
                          backgroundColor: fillColor,
                          child: Icon(
                            Icons.fitness_center,
                            color: subtitleColor,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          exercise.name,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          _translateMuscle(exercise.muscleGroup),
                          style: TextStyle(color: subtitleColor, fontSize: 13),
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: subtitleColor,
                        ),
                        onTap: () => _showExerciseDetails(exercise),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddExerciseDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

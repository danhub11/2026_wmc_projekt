import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/settings_manager.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  bool _isLoading = true;

  // Muskel-Verteilung
  List<dynamic> _muscleDistribution = [];

  // Übungs-Statistiken
  List<Exercise> _allExercises = [];
  Exercise? _selectedExercise;
  List<dynamic> _exerciseHistory = [];
  Map<String, dynamic>? _personalRecord;
  RankingStats? _ranking;

  // Körperdaten (Gewicht)
  List<Measurement> _weightMeasurements = [];
  final TextEditingController _weightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final exercises = await ApiService.getExercises();
      final distribution = await ApiService.getMuscleDistribution();
      final weights = await ApiService.getMeasurements('weight');

      setState(() {
        _allExercises = exercises;
        _muscleDistribution = distribution;
        _weightMeasurements = weights;
        if (exercises.isNotEmpty) {
          _selectedExercise = exercises.firstWhere(
            (e) => e.name.contains('Bench Press'),
            orElse: () => exercises.first,
          );
        }
      });

      if (_selectedExercise != null) {
        await _loadExerciseStats(_selectedExercise!.id);
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadExerciseStats(int exerciseId) async {
    setState(() => _isLoading = true);
    try {
      final history = await ApiService.getExerciseHistory(exerciseId);
      final pr = await ApiService.getPersonalRecord(exerciseId);
      final ranking = await ApiService.getRanking(exerciseId);

      setState(() {
        _exerciseHistory = history;
        _personalRecord = pr;
        _ranking = ranking;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveWeight() async {
    final weightText = _weightController.text;
    if (weightText.isEmpty) return;

    final inputValue = double.tryParse(weightText.replaceAll(',', '.'));
    if (inputValue == null) return;

    // Immer in kg speichern
    final weightKg = settingsManager.useKg
        ? inputValue
        : inputValue * 0.45359237;

    setState(() => _isLoading = true);
    try {
      await ApiService.saveMeasurement('weight', weightKg);
      final weights = await ApiService.getMeasurements('weight');
      setState(() {
        _weightMeasurements = weights;
        _weightController.clear();
        _isLoading = false;
      });
      FocusScope.of(context).unfocus();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<PieChartSectionData> _generatePieSections(Color primaryColor) {
    if (_muscleDistribution.isEmpty) return [];

    final List<Color> colors = [
      primaryColor,
      Colors.blueAccent,
      Colors.greenAccent,
      Colors.purpleAccent,
      Colors.redAccent,
      Colors.yellowAccent,
    ];

    return _muscleDistribution.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      return PieChartSectionData(
        color: colors[index % colors.length],
        value: data['set_count'].toDouble(),
        title: '${data['muscle_group']}\n(${data['set_count']})',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  List<FlSpot> _generateHistorySpots() {
    if (_exerciseHistory.isEmpty) return [];

    // Gruppiere nach Datum und finde das Max-Gewicht pro Tag für den Chart
    Map<String, double> dailyMax = {};
    for (var set in _exerciseHistory) {
      String date = set['date'].toString().substring(0, 10);
      double weightKg = (set['weight_kg'] as num).toDouble();
      // Für den Chart in der gewünschten Einheit anzeigen
      double displayWeight = settingsManager.useKg
          ? weightKg
          : weightKg / 0.45359237;
      if (!dailyMax.containsKey(date) || displayWeight > dailyMax[date]!) {
        dailyMax[date] = displayWeight;
      }
    }

    final sortedDates = dailyMax.keys.toList()..sort();
    return sortedDates.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), dailyMax[entry.value]!);
    }).toList();
  }

  String _formatWeight(double kg) {
    if (settingsManager.useKg) {
      final v = kg == kg.truncateToDouble()
          ? kg.toInt().toString()
          : kg.toStringAsFixed(1);
      return '$v kg';
    } else {
      final lbs = kg / 0.45359237;
      final v = lbs == lbs.truncateToDouble()
          ? lbs.toInt().toString()
          : lbs.toStringAsFixed(1);
      return '$v lbs';
    }
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
        final gridLineColor = theme.dividerColor;

        return Scaffold(
          appBar: AppBar(title: const Text('Fortschritt')),
          body: _isLoading && _allExercises.isEmpty
              ? Center(child: CircularProgressIndicator(color: primaryColor))
              : RefreshIndicator(
                  color: primaryColor,
                  onRefresh: _loadInitialData,
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      // --- KÖRPERGEWICHT ---
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.scale, color: primaryColor),
                                const SizedBox(width: 8),
                                Text(
                                  'Körpergewicht',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (_weightMeasurements.isNotEmpty)
                              Text(
                                'Aktuell: ${_formatWeight(_weightMeasurements.last.value)}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _weightController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    decoration: InputDecoration(
                                      hintText: settingsManager.useKg
                                          ? 'Gewicht eintragen (kg)'
                                          : 'Gewicht eintragen (lbs)',
                                      filled: true,
                                      fillColor: fillColor,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                      horizontal: 20,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: _saveWeight,
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
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // --- ÜBUNGS-ANALYSE ---
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.trending_up, color: primaryColor),
                                const SizedBox(width: 8),
                                Text(
                                  'Übungs-Analyse',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Dropdown
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: fillColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<Exercise>(
                                  isExpanded: true,
                                  dropdownColor: theme.scaffoldBackgroundColor,
                                  value: _selectedExercise,
                                  icon: Icon(
                                    Icons.keyboard_arrow_down,
                                    color: textColor,
                                  ),
                                  items: _allExercises.map((Exercise exercise) {
                                    return DropdownMenuItem<Exercise>(
                                      value: exercise,
                                      child: Text(
                                        exercise.name,
                                        style: TextStyle(color: textColor),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (Exercise? newValue) {
                                    if (newValue != null) {
                                      setState(
                                        () => _selectedExercise = newValue,
                                      );
                                      _loadExerciseStats(newValue.id);
                                    }
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            if (_isLoading)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: CircularProgressIndicator(
                                    color: primaryColor,
                                  ),
                                ),
                              )
                            else ...[
                              // PR & Ranking Row
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: fillColor,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Personal Record',
                                            style: TextStyle(
                                              color: subtitleColor,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _personalRecord != null
                                                ? _formatWeight(
                                                    (_personalRecord!['max_weight']
                                                            as num)
                                                        .toDouble(),
                                                  )
                                                : '-',
                                            style: TextStyle(
                                              color: textColor,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: fillColor,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Global Ranking',
                                            style: TextStyle(
                                              color: subtitleColor,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _ranking?.rank ?? 'Unrated',
                                            style: TextStyle(
                                              color: _ranking?.rank != 'Unrated'
                                                  ? primaryColor
                                                  : textColor,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Line Chart
                              if (_generateHistorySpots().isNotEmpty) ...[
                                Text(
                                  'Gewichtsverlauf (Max pro Tag)',
                                  style: TextStyle(
                                    color: subtitleColor,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 200,
                                  child: LineChart(
                                    LineChartData(
                                      gridData: FlGridData(
                                        show: true,
                                        drawVerticalLine: false,
                                        getDrawingHorizontalLine: (value) =>
                                            FlLine(
                                              color: gridLineColor,
                                              strokeWidth: 1,
                                            ),
                                      ),
                                      titlesData: FlTitlesData(
                                        topTitles: const AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: false,
                                          ),
                                        ),
                                        rightTitles: const AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: false,
                                          ),
                                        ),
                                        bottomTitles: const AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: false,
                                          ),
                                        ),
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 40,
                                            getTitlesWidget: (value, meta) =>
                                                Text(
                                                  meta.formattedValue,
                                                  style: TextStyle(
                                                    color: subtitleColor,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                          ),
                                        ),
                                      ),
                                      borderData: FlBorderData(show: false),
                                      lineBarsData: [
                                        LineChartBarData(
                                          spots: _generateHistorySpots(),
                                          isCurved: true,
                                          color: primaryColor,
                                          barWidth: 3,
                                          isStrokeCapRound: true,
                                          dotData: const FlDotData(show: true),
                                          belowBarData: BarAreaData(
                                            show: true,
                                            color: primaryColor.withValues(
                                              alpha: 0.1,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ] else
                                Center(
                                  child: Text(
                                    'Noch keine Daten für diese Übung.',
                                    style: TextStyle(color: subtitleColor),
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // --- MUSKEL-VERTEILUNG (PIE CHART) ---
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.pie_chart, color: primaryColor),
                                const SizedBox(width: 8),
                                Text(
                                  'Muskel-Fokus (All Time)',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            if (_muscleDistribution.isEmpty)
                              Center(
                                child: Text(
                                  'Keine Daten verfügbar.',
                                  style: TextStyle(color: subtitleColor),
                                ),
                              )
                            else
                              SizedBox(
                                height: 200,
                                child: PieChart(
                                  PieChartData(
                                    sectionsSpace: 2,
                                    centerSpaceRadius: 40,
                                    sections: _generatePieSections(
                                      primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

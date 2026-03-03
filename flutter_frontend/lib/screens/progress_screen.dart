import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/constants.dart';
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

    final weight = double.tryParse(weightText.replaceAll(',', '.'));
    if (weight == null) return;

    setState(() => _isLoading = true);
    try {
      await ApiService.saveMeasurement('weight', weight);
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

  List<PieChartSectionData> _generatePieSections() {
    if (_muscleDistribution.isEmpty) return [];

    final List<Color> colors = [
      AppConstants.primaryOrange,
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
        titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }

  List<FlSpot> _generateHistorySpots() {
    if (_exerciseHistory.isEmpty) return [];
    
    // Gruppiere nach Datum und finde das Max-Gewicht pro Tag für den Chart
    Map<String, double> dailyMax = {};
    for (var set in _exerciseHistory) {
      String date = set['date'].toString().substring(0, 10);
      double weight = (set['weight_kg'] as num).toDouble();
      if (!dailyMax.containsKey(date) || weight > dailyMax[date]!) {
        dailyMax[date] = weight;
      }
    }

    final sortedDates = dailyMax.keys.toList()..sort();
    return sortedDates.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), dailyMax[entry.value]!);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppConstants.backgroundDark,
        elevation: 0,
        title: const Text(
          'Fortschritt',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: _isLoading && _allExercises.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppConstants.primaryOrange))
          : RefreshIndicator(
              color: AppConstants.primaryOrange,
              onRefresh: _loadInitialData,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // --- KÖRPERGEWICHT ---
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppConstants.cardDark, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.scale, color: AppConstants.primaryOrange),
                            SizedBox(width: 8),
                            Text('Körpergewicht', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_weightMeasurements.isNotEmpty)
                          Text(
                            'Aktuell: ${_weightMeasurements.last.value} kg',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _weightController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'Gewicht eintragen (kg)',
                                  hintStyle: const TextStyle(color: Colors.grey),
                                  filled: true,
                                  fillColor: Colors.grey[850],
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppConstants.primaryOrange,
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: _saveWeight,
                              child: const Text('Speichern', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- ÜBUNGS-ANALYSE (HEVY STYLE) ---
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppConstants.cardDark, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.trending_up, color: AppConstants.primaryOrange),
                            SizedBox(width: 8),
                            Text('Übungs-Analyse', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Dropdown
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(color: Colors.grey[850], borderRadius: BorderRadius.circular(8)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<Exercise>(
                              isExpanded: true,
                              dropdownColor: AppConstants.backgroundDark,
                              value: _selectedExercise,
                              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                              items: _allExercises.map((Exercise exercise) {
                                return DropdownMenuItem<Exercise>(
                                  value: exercise,
                                  child: Text(exercise.name, style: const TextStyle(color: Colors.white)),
                                );
                              }).toList(),
                              onChanged: (Exercise? newValue) {
                                if (newValue != null) {
                                  setState(() => _selectedExercise = newValue);
                                  _loadExerciseStats(newValue.id);
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        if (_isLoading)
                          const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator(color: AppConstants.primaryOrange)))
                        else ...[
                          // PR & Ranking Row
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(8)),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Personal Record', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                      const SizedBox(height: 4),
                                      Text(
                                        _personalRecord != null ? '${_personalRecord!['max_weight']} kg' : '-',
                                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(8)),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Global Ranking', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                      const SizedBox(height: 4),
                                      Text(
                                        _ranking?.rank ?? 'Unrated',
                                        style: TextStyle(color: _ranking?.rank != 'Unrated' ? AppConstants.primaryOrange : Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
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
                            const Text('Gewichtsverlauf (Max pro Tag)', style: TextStyle(color: Colors.grey, fontSize: 14)),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 200,
                              child: LineChart(
                                LineChartData(
                                  gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey[800], strokeWidth: 1)),
                                  titlesData: const FlTitlesData(
                                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), // X-Achse vereinfacht
                                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: _generateHistorySpots(),
                                      isCurved: true,
                                      color: AppConstants.primaryOrange,
                                      barWidth: 3,
                                      isStrokeCapRound: true,
                                      dotData: const FlDotData(show: true),
                                      belowBarData: BarAreaData(show: true, color: AppConstants.primaryOrange.withOpacity(0.1)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ] else
                            const Center(child: Text('Noch keine Daten für diese Übung.', style: TextStyle(color: Colors.grey))),
                        ]
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- MUSKEL-VERTEILUNG (PIE CHART) ---
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppConstants.cardDark, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.pie_chart, color: AppConstants.primaryOrange),
                            SizedBox(width: 8),
                            Text('Muskel-Fokus (All Time)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        if (_muscleDistribution.isEmpty)
                          const Center(child: Text('Keine Daten verfügbar.', style: TextStyle(color: Colors.grey)))
                        else
                          SizedBox(
                            height: 200,
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 40,
                                sections: _generatePieSections(),
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
  }
}
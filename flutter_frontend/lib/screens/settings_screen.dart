import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/settings_manager.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _showRestTimerSheet() {
    final List<int> timerOptions = [30, 60, 90, 120, 150, 180, 240];
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final cardColor = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: theme.dividerColor)),
                ),
                child: Center(
                  child: Text(
                    'Standard-Pausenzeit',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: timerOptions.length,
                  itemBuilder: (context, index) {
                    final seconds = timerOptions[index];
                    final isSelected =
                        settingsManager.restTimerSeconds == seconds;

                    return ListTile(
                      title: Text(
                        '$seconds Sekunden',
                        style: TextStyle(color: textColor, fontSize: 16),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check, color: primaryColor)
                          : null,
                      onTap: () {
                        settingsManager.setRestTimer(seconds);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final cardColor = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;
    final subtitleColor = theme.textTheme.bodySmall?.color ?? Colors.grey;

    return AnimatedBuilder(
      animation: settingsManager,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(title: const Text('Einstellungen')),
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Design-Sektion
              _buildSectionHeader(context, 'Design'),
              _buildCard(
                context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      title: Text(
                        'Dunkelmodus',
                        style: TextStyle(color: textColor),
                      ),
                      secondary: Icon(Icons.dark_mode, color: primaryColor),
                      activeColor: primaryColor,
                      value: settingsManager.isDarkMode,
                      onChanged: (bool value) =>
                          settingsManager.toggleDarkMode(value),
                    ),
                    Divider(color: theme.dividerColor, height: 1),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Farbthema',
                            style: TextStyle(color: textColor, fontSize: 16),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(
                              AppConstants.themeColors.length,
                              (index) {
                                final color = AppConstants.themeColors[index];
                                final isSelected =
                                    settingsManager.themeColorIndex == index;
                                return GestureDetector(
                                  onTap: () =>
                                      settingsManager.setThemeColor(index),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 56,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? color.withValues(alpha: 0.15)
                                          : theme
                                                    .inputDecorationTheme
                                                    .fillColor ??
                                                cardColor,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? color
                                            : theme.dividerColor,
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          AppConstants.themeIcons[index],
                                          color: color,
                                          size: 22,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          AppConstants.themeNames[index],
                                          style: TextStyle(
                                            color: isSelected
                                                ? color
                                                : subtitleColor,
                                            fontSize: 10,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Training-Sektion
              _buildSectionHeader(context, 'Training'),
              _buildCard(
                context,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.fitness_center, color: primaryColor),
                              const SizedBox(width: 12),
                              Text(
                                'Gewichtseinheit',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => settingsManager.setUnit(true),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: settingsManager.useKg
                                          ? primaryColor
                                          : (theme
                                                    .inputDecorationTheme
                                                    .fillColor ??
                                                cardColor),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: settingsManager.useKg
                                            ? primaryColor
                                            : theme.dividerColor,
                                        width: settingsManager.useKg ? 2 : 1,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          'kg',
                                          style: TextStyle(
                                            color: settingsManager.useKg
                                                ? Colors.white
                                                : subtitleColor,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Kilogramm',
                                          style: TextStyle(
                                            color: settingsManager.useKg
                                                ? Colors.white70
                                                : subtitleColor,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => settingsManager.setUnit(false),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: !settingsManager.useKg
                                          ? primaryColor
                                          : (theme
                                                    .inputDecorationTheme
                                                    .fillColor ??
                                                cardColor),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: !settingsManager.useKg
                                            ? primaryColor
                                            : theme.dividerColor,
                                        width: !settingsManager.useKg ? 2 : 1,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          'lbs',
                                          style: TextStyle(
                                            color: !settingsManager.useKg
                                                ? Colors.white
                                                : subtitleColor,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Pfund',
                                          style: TextStyle(
                                            color: !settingsManager.useKg
                                                ? Colors.white70
                                                : subtitleColor,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Divider(color: theme.dividerColor, height: 1),
                    ListTile(
                      leading: Icon(Icons.timer, color: primaryColor),
                      title: Text(
                        'Standard-Pausenzeit',
                        style: TextStyle(color: textColor),
                      ),
                      subtitle: Text(
                        '${settingsManager.restTimerSeconds} Sekunden',
                        style: TextStyle(color: subtitleColor),
                      ),
                      trailing: Icon(Icons.chevron_right, color: subtitleColor),
                      onTap: _showRestTimerSheet,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // System-Sektion
              _buildSectionHeader(context, 'System'),
              _buildCard(
                context,
                child: SwitchListTile(
                  title: Text(
                    'Benachrichtigungen',
                    style: TextStyle(color: textColor),
                  ),
                  secondary: Icon(Icons.notifications, color: primaryColor),
                  activeColor: primaryColor,
                  value: settingsManager.notificationsEnabled,
                  onChanged: (bool value) =>
                      settingsManager.toggleNotifications(value),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final subtitleColor =
        Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: subtitleColor,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, {required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

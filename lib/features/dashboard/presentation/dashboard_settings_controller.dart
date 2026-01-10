import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'dashboard_settings_controller.g.dart';

// Widget identifiers
enum DashboardWidget {
  dailyGoals,
  streak,
  overdueTasks,
  notes,
  deadlines,
  aiInsights,
  focusTimer,
  projects,
}

extension DashboardWidgetExtension on DashboardWidget {
  String get displayName {
    switch (this) {
      case DashboardWidget.dailyGoals:
        return 'Daily Goals';
      case DashboardWidget.streak:
        return 'Streak';
      case DashboardWidget.overdueTasks:
        return 'Overdue Tasks';
      case DashboardWidget.notes:
        return 'Notes';
      case DashboardWidget.deadlines:
        return 'Deadlines';
      case DashboardWidget.aiInsights:
        return 'AI Insights';
      case DashboardWidget.focusTimer:
        return 'Focus Timer';
      case DashboardWidget.projects:
        return 'Projects';
    }
  }

  String get icon {
    switch (this) {
      case DashboardWidget.dailyGoals:
        return 'trending_up';
      case DashboardWidget.streak:
        return 'local_fire_department';
      case DashboardWidget.overdueTasks:
        return 'warning_amber';
      case DashboardWidget.notes:
        return 'edit_note';
      case DashboardWidget.deadlines:
        return 'alarm';
      case DashboardWidget.aiInsights:
        return 'auto_awesome';
      case DashboardWidget.focusTimer:
        return 'timer';
      case DashboardWidget.projects:
        return 'folder';
    }
  }
}

class DashboardSettings {
  final List<DashboardWidget> widgetOrder;
  final Set<DashboardWidget> hiddenWidgets;

  DashboardSettings({
    required this.widgetOrder,
    required this.hiddenWidgets,
  });

  DashboardSettings copyWith({
    List<DashboardWidget>? widgetOrder,
    Set<DashboardWidget>? hiddenWidgets,
  }) {
    return DashboardSettings(
      widgetOrder: widgetOrder ?? this.widgetOrder,
      hiddenWidgets: hiddenWidgets ?? this.hiddenWidgets,
    );
  }

  // Default settings
  factory DashboardSettings.defaults() {
    return DashboardSettings(
      widgetOrder: DashboardWidget.values.toList(),
      hiddenWidgets: {},
    );
  }
}

@riverpod
class DashboardSettingsController extends _$DashboardSettingsController {
  static const String _orderKey = 'dashboard_widget_order';
  static const String _hiddenKey = 'dashboard_hidden_widgets';

  @override
  Future<DashboardSettings> build() async {
    return _loadSettings();
  }

  Future<DashboardSettings> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Load order
    final orderStrings = prefs.getStringList(_orderKey);
    List<DashboardWidget> order;
    if (orderStrings != null) {
      order = orderStrings
          .map((s) => DashboardWidget.values.firstWhere(
                (w) => w.name == s,
                orElse: () => DashboardWidget.dailyGoals,
              ))
          .toList();
      // Add any missing widgets
      for (final widget in DashboardWidget.values) {
        if (!order.contains(widget)) {
          order.add(widget);
        }
      }
    } else {
      order = DashboardWidget.values.toList();
    }

    // Load hidden widgets
    final hiddenStrings = prefs.getStringList(_hiddenKey) ?? [];
    final hidden = hiddenStrings
        .map((s) => DashboardWidget.values.firstWhere(
              (w) => w.name == s,
              orElse: () => DashboardWidget.dailyGoals,
            ))
        .toSet();

    return DashboardSettings(
      widgetOrder: order,
      hiddenWidgets: hidden,
    );
  }

  Future<void> _saveSettings(DashboardSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _orderKey,
      settings.widgetOrder.map((w) => w.name).toList(),
    );
    await prefs.setStringList(
      _hiddenKey,
      settings.hiddenWidgets.map((w) => w.name).toList(),
    );
  }

  Future<void> toggleWidgetVisibility(DashboardWidget widget) async {
    final current = state.valueOrNull ?? DashboardSettings.defaults();
    final newHidden = Set<DashboardWidget>.from(current.hiddenWidgets);

    if (newHidden.contains(widget)) {
      newHidden.remove(widget);
    } else {
      newHidden.add(widget);
    }

    final newSettings = current.copyWith(hiddenWidgets: newHidden);
    state = AsyncValue.data(newSettings);
    await _saveSettings(newSettings);
  }

  Future<void> reorderWidgets(int oldIndex, int newIndex) async {
    final current = state.valueOrNull ?? DashboardSettings.defaults();
    final newOrder = List<DashboardWidget>.from(current.widgetOrder);

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = newOrder.removeAt(oldIndex);
    newOrder.insert(newIndex, item);

    final newSettings = current.copyWith(widgetOrder: newOrder);
    state = AsyncValue.data(newSettings);
    await _saveSettings(newSettings);
  }

  Future<void> resetToDefaults() async {
    final defaultSettings = DashboardSettings.defaults();
    state = AsyncValue.data(defaultSettings);
    await _saveSettings(defaultSettings);
  }

  bool isWidgetVisible(DashboardWidget widget) {
    final current = state.valueOrNull ?? DashboardSettings.defaults();
    return !current.hiddenWidgets.contains(widget);
  }
}

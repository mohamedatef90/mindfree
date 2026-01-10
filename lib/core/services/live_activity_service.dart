import 'dart:async';
import 'dart:io';
import 'package:live_activities/live_activities.dart';

/// Service to manage iOS Live Activities for timer functionality
class LiveActivityService {
  static final LiveActivityService _instance = LiveActivityService._internal();
  factory LiveActivityService() => _instance;
  LiveActivityService._internal();

  final _liveActivities = LiveActivities();
  String? _currentActivityId;
  Timer? _updateTimer;

  /// Initialize the live activity service
  Future<void> init() async {
    if (!Platform.isIOS) return;

    // Initialize live activities
    _liveActivities.init(appGroupId: 'group.com.mindfree.app');
  }

  /// Start a timer live activity
  Future<void> startTimerActivity({
    required Duration totalDuration,
    required DateTime endTime,
  }) async {
    if (!Platform.isIOS) return;

    try {
      // Create activity data
      final activityData = <String, dynamic>{
        'timerName': 'Focus Timer',
        'endTime': endTime.millisecondsSinceEpoch,
        'totalSeconds': totalDuration.inSeconds,
        'remainingSeconds': totalDuration.inSeconds,
        'isRunning': true,
      };

      // Start the live activity with unique ID
      final uniqueId = DateTime.now().millisecondsSinceEpoch.toString();
      final activityId = await _liveActivities.createActivity(uniqueId, activityData);
      _currentActivityId = activityId;

      // Start periodic updates
      _startUpdates(endTime);
    } catch (e) {
      // Live activity not available - silently fail
    }
  }

  void _startUpdates(DateTime endTime) {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final now = DateTime.now();
      final remaining = endTime.difference(now);

      if (remaining.isNegative || _currentActivityId == null) {
        await endTimerActivity();
        timer.cancel();
        return;
      }

      await updateTimerActivity(
        remainingSeconds: remaining.inSeconds,
        isRunning: true,
      );
    });
  }

  /// Update the timer live activity
  Future<void> updateTimerActivity({
    required int remainingSeconds,
    required bool isRunning,
  }) async {
    if (!Platform.isIOS || _currentActivityId == null) return;

    try {
      final activityData = <String, dynamic>{
        'remainingSeconds': remainingSeconds,
        'isRunning': isRunning,
      };

      await _liveActivities.updateActivity(_currentActivityId!, activityData);
    } catch (e) {
      // Live activity update failed - silently fail
    }
  }

  /// Pause the timer live activity
  Future<void> pauseTimerActivity({required int remainingSeconds}) async {
    _updateTimer?.cancel();
    await updateTimerActivity(
      remainingSeconds: remainingSeconds,
      isRunning: false,
    );
  }

  /// Resume the timer live activity
  Future<void> resumeTimerActivity({
    required int remainingSeconds,
    required DateTime newEndTime,
  }) async {
    _startUpdates(newEndTime);
    await updateTimerActivity(
      remainingSeconds: remainingSeconds,
      isRunning: true,
    );
  }

  /// End the timer live activity
  Future<void> endTimerActivity() async {
    _updateTimer?.cancel();

    if (!Platform.isIOS || _currentActivityId == null) return;

    try {
      await _liveActivities.endActivity(_currentActivityId!);
      _currentActivityId = null;
    } catch (e) {
      // Live activity end failed - silently fail
      _currentActivityId = null;
    }
  }

  /// Check if live activities are supported
  Future<bool> areActivitiesEnabled() async {
    if (!Platform.isIOS) return false;

    try {
      return await _liveActivities.areActivitiesEnabled();
    } catch (e) {
      return false;
    }
  }

  /// Dispose the service
  void dispose() {
    _updateTimer?.cancel();
  }
}

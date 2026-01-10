import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mindfree/core/theme/app_colors.dart';
import 'package:mindfree/core/widgets/glass_card.dart';
import 'package:mindfree/data/models/task.dart';

const Map<int, Color> priorityColors = {
  0: AppColors.accentBlue,
  1: AppColors.secondary,
  2: AppColors.accentPink,
};

const Map<int, String> priorityLabels = {
  0: 'Low',
  1: 'Medium',
  2: 'High',
};

class TaskCard extends StatefulWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Function(int subtaskIndex)? onSubtaskToggle;
  final String? projectName;
  final Color? projectColor;
  final bool initiallyExpanded;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    this.onLongPress,
    this.onSubtaskToggle,
    this.projectName,
    this.projectColor,
    this.initiallyExpanded = false,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    if (_isExpanded) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final subtaskItems = widget.task.subtaskItems;
    final completedCount = widget.task.completedSubtaskCount;
    final totalSubtasks = subtaskItems.length;
    final hasSubtasks = totalSubtasks > 0;

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress != null
          ? () {
              // Haptic feedback on iOS
              if (Platform.isIOS) {
                HapticFeedback.mediumImpact();
              }
              widget.onLongPress!();
            }
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: priorityColors[widget.task.priority] ?? AppColors.secondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (widget.task.emoji != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Text(widget.task.emoji!),
                            ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.task.title,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: widget.task.isCompleted
                                            ? AppColors.textSecondary
                                            : AppColors.textPrimary,
                                        decoration: widget.task.isCompleted
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                ),
                                if (widget.projectName != null) ...[
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: widget.projectColor ?? AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        widget.projectName!,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: widget.projectColor?.withValues(alpha: 0.8) ?? AppColors.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Icon(
                            widget.task.isCompleted
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color: widget.task.isCompleted
                                ? AppColors.accentGreen
                                : AppColors.textSecondary,
                            size: 20,
                          ),
                        ],
                      ),
                      if (widget.task.description != null &&
                          widget.task.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            widget.task.description!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      // Collapsible Subtasks section
                      if (hasSubtasks) ...[
                        const SizedBox(height: 12),
                        // Progress indicator with expand/collapse toggle
                        GestureDetector(
                          onTap: _toggleExpanded,
                          behavior: HitTestBehavior.opaque,
                          child: Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: totalSubtasks > 0
                                        ? completedCount / totalSubtasks
                                        : 0,
                                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      completedCount == totalSubtasks
                                          ? AppColors.accentGreen
                                          : AppColors.primary,
                                    ),
                                    minHeight: 4,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$completedCount/$totalSubtasks',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: completedCount == totalSubtasks
                                      ? AppColors.accentGreen
                                      : AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              AnimatedRotation(
                                turns: _isExpanded ? 0.5 : 0,
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 18,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Animated subtasks list
                        SizeTransition(
                          sizeFactor: _expandAnimation,
                          child: Column(
                            children: [
                              const SizedBox(height: 8),
                              ...subtaskItems.asMap().entries.map(
                                (entry) {
                                  final index = entry.key;
                                  final subtask = entry.value;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: GestureDetector(
                                      onTap: widget.onSubtaskToggle != null
                                          ? () => widget.onSubtaskToggle!(index)
                                          : null,
                                      behavior: HitTestBehavior.opaque,
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 20,
                                            height: 20,
                                            decoration: BoxDecoration(
                                              color: subtask.isCompleted
                                                  ? AppColors.accentGreen.withValues(alpha: 0.2)
                                                  : Colors.white.withValues(alpha: 0.05),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(
                                                color: subtask.isCompleted
                                                    ? AppColors.accentGreen
                                                    : Colors.white24,
                                                width: 1.5,
                                              ),
                                            ),
                                            child: subtask.isCompleted
                                                ? const Icon(
                                                    Icons.check_rounded,
                                                    size: 14,
                                                    color: AppColors.accentGreen,
                                                  )
                                                : null,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              subtask.title,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: subtask.isCompleted
                                                    ? Colors.white38
                                                    : Colors.white70,
                                                decoration: subtask.isCompleted
                                                    ? TextDecoration.lineThrough
                                                    : null,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          // Priority badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: (priorityColors[widget.task.priority] ??
                                      AppColors.secondary)
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              priorityLabels[widget.task.priority] ?? 'Medium',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: priorityColors[widget.task.priority] ??
                                    AppColors.secondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Time
                          const Icon(
                            Icons.access_time,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.task.dueDate != null
                                ? DateFormat('MMM d, HH:mm').format(widget.task.dueDate!)
                                : 'No date',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                          // Reminder indicator
                          if (widget.task.reminderTime != null) ...[
                            const SizedBox(width: 12),
                            Icon(
                              Icons.notifications_active_rounded,
                              size: 14,
                              color: AppColors.accentPink.withValues(alpha: 0.7),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

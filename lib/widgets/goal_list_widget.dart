import 'package:flutter/material.dart';
import 'package:myfc_app/models/match.dart';

class GoalListWidget extends StatelessWidget {
  final List<Goal> goals;
  final bool isEditable;
  final Function(String?)? onDeleteGoal;
  final int? maxDisplay;
  final String emptyMessage;

  const GoalListWidget({
    Key? key,
    required this.goals,
    this.isEditable = false,
    this.onDeleteGoal,
    this.maxDisplay,
    this.emptyMessage = '득점 기록이 없습니다.',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (goals.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            emptyMessage,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    final displayGoals = maxDisplay != null && maxDisplay! < goals.length
        ? goals.sublist(0, maxDisplay)
        : goals;
    
    final hasMore = maxDisplay != null && maxDisplay! < goals.length;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...displayGoals.map((goal) => _buildGoalItem(context, goal)),
          
          if (hasMore)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                '외 ${goals.length - maxDisplay!}건의 추가 득점',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGoalItem(BuildContext context, Goal goal) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          const Icon(
            Icons.sports_soccer,
            size: 16,
            color: Colors.black87,
          ),
          const SizedBox(width: 8),
          
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                ),
                children: [
                  const TextSpan(
                    text: 'GOAL ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: goal.player?.name ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (goal.assistPlayer?.name != null)
                    TextSpan(
                      text: ' (${goal.assistPlayer!.name})',
                      style: TextStyle(
                        color: Colors.grey[700],
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Quarter indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${goal.quarter}Q',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          ),
          
          // Delete button
          if (isEditable && onDeleteGoal != null)
            IconButton(
              icon: const Icon(
                Icons.delete,
                color: Colors.red,
                size: 18,
              ),
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.only(left: 8),
              onPressed: () => onDeleteGoal!(goal.id.toString()),
            ),
        ],
      ),
    );
  }
} 
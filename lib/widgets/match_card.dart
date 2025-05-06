import 'package:flutter/material.dart';
import 'package:myfc_app/models/match.dart';
import 'package:intl/intl.dart';

class MatchCard extends StatelessWidget {
  final int id;
  final String date;
  final String opponent;
  final String score;
  final MatchResult? result;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const MatchCard({
    super.key,
    required this.id,
    required this.date,
    required this.opponent,
    required this.score,
    this.result,
    this.onTap,
    this.onDelete,
  });

  Color _getResultColor() {
    if (result == null) return Colors.grey;
    switch (result!) {
      case MatchResult.win:
        return Colors.green;
      case MatchResult.lose:
        return Colors.red;
      case MatchResult.draw:
        return Colors.grey;
    }
  }

  String _getResultText() {
    if (result == null) return '무';
    switch (result!) {
      case MatchResult.win:
        return '승';
      case MatchResult.lose:
        return '패';
      case MatchResult.draw:
        return '무';
    }
  }

  @override
  Widget build(BuildContext context) {
    final scoreArray = score.split(':');
    final ourScore = int.tryParse(scoreArray[0]) ?? 0;
    final opponentScore = int.tryParse(scoreArray[1]) ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      elevation: 2.0,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    date,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14.0,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: _getResultColor(),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Text(
                          _getResultText(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (onDelete != null)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          color: Colors.red,
                          onPressed: onDelete,
                          padding: const EdgeInsets.only(left: 8.0),
                          constraints: const BoxConstraints(),
                          tooltip: '매치 삭제',
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12.0),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'FC C++',
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          '우리 팀',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$ourScore : $opponentScore',
                    style: const TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          opponent,
                          style: const TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.end,
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          '상대 팀',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12.0,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 
import 'package:flutter/material.dart';
import 'package:myfc_app/utils/helpers.dart';

enum MatchResult {
  win,
  lose,
  draw,
}

class MatchCard extends StatelessWidget {
  final String opponent;
  final DateTime date;
  final int ourScore;
  final int opponentScore;
  final MatchResult? result;
  final bool showControls;
  final VoidCallback? onTap;
  final VoidCallback? onEditTap;
  final VoidCallback? onDeleteTap;
  final bool isCompleted;

  const MatchCard({
    Key? key,
    required this.opponent,
    required this.date,
    required this.ourScore,
    required this.opponentScore,
    this.result,
    this.showControls = true,
    this.onTap,
    this.onEditTap,
    this.onDeleteTap,
    this.isCompleted = true,
  }) : super(key: key);

  MatchResult _getResult() {
    if (!isCompleted) return MatchResult.draw;
    
    if (result != null) return result!;
    
    if (ourScore > opponentScore) {
      return MatchResult.win;
    } else if (ourScore < opponentScore) {
      return MatchResult.lose;
    } else {
      return MatchResult.draw;
    }
  }

  String _getResultText(MatchResult result) {
    switch (result) {
      case MatchResult.win: return '승';
      case MatchResult.lose: return '패';
      case MatchResult.draw: return '무';
    }
  }

  Color _getResultColor(MatchResult result) {
    switch (result) {
      case MatchResult.win: return Colors.blue;
      case MatchResult.lose: return Colors.red;
      case MatchResult.draw: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentResult = _getResult();
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Match actions
            if (showControls)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: onEditTap,
                    child: const Text('수정'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  TextButton(
                    onPressed: onDeleteTap,
                    child: const Text('삭제'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            
            // Match info
            Container(
              width: double.infinity,
              child: InkWell(
                onTap: onTap,
                child: Row(
                  children: [
                    // Result circle
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getResultColor(currentResult),
                      ),
                      child: Center(
                        child: Text(
                          _getResultText(currentResult),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Match info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            opponent,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            Helpers.formatDateKorean(date),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Score
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        isCompleted ? '$ourScore : $opponentScore' : '아직등록',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
                    // Detail button
                    Container(
                      width: 40,
                      child: IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: onTap,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
import 'package:flutter/material.dart';
import 'package:myfc_app/models/match.dart';

class QuarterScoreWidget extends StatelessWidget {
  final Map<int, QuarterScore> quarterScores;
  final int selectedQuarter;
  final Function(int)? onQuarterSelected;
  final bool isEditable;
  final int maxQuarters;

  const QuarterScoreWidget({
    Key? key,
    required this.quarterScores,
    required this.selectedQuarter,
    this.onQuarterSelected,
    this.isEditable = false,
    this.maxQuarters = 4,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get available quarters
    final quarters = quarterScores.keys.toList()..sort();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Quarter tabs
          Row(
            children: List.generate(maxQuarters, (index) {
              final quarter = index + 1;
              final isAvailable = quarters.contains(quarter);
              final isSelected = quarter == selectedQuarter;
              
              return Expanded(
                child: GestureDetector(
                  onTap: isAvailable && onQuarterSelected != null
                      ? () => onQuarterSelected!(quarter)
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      border: isSelected
                          ? Border.all(color: Colors.black, width: 1)
                          : null,
                    ),
                    child: Text(
                      '${quarter}쿼터',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isAvailable ? Colors.black : Colors.grey,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          
          const SizedBox(height: 16),
          
          // Scores grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: maxQuarters,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
            childAspectRatio: 1.2,
            children: List.generate(maxQuarters, (index) {
              final quarter = index + 1;
              final isAvailable = quarters.contains(quarter);
              final quarterScore = isAvailable ? quarterScores[quarter] : null;
              
              return Container(
                decoration: BoxDecoration(
                  color: quarter == selectedQuarter ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: quarter == selectedQuarter
                      ? Border.all(color: Colors.black, width: 1)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Quarter label
                    Text(
                      '${quarter}Q',
                      style: TextStyle(
                        fontWeight: quarter == selectedQuarter ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                        color: isAvailable ? Colors.black : Colors.grey,
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Quarter score
                    if (isAvailable && quarterScore != null)
                      Text(
                        '${quarterScore.ourScore} : ${quarterScore.opponentScore}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: quarter == selectedQuarter ? Colors.black : Colors.grey[700],
                        ),
                      )
                    else
                      Text(
                        '-',
                        style: TextStyle(
                          color: Colors.grey[400],
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
          
          // Editable controls
          if (isEditable) ...[
            const SizedBox(height: 16),
            Text(
              '쿼터를 탭하여 스코어를 수정할 수 있습니다',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
} 
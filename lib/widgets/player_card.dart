import 'package:flutter/material.dart';

class PlayerCard extends StatelessWidget {
  final String name;
  final int number;
  final bool isSelected;
  final bool isSelectable;
  final VoidCallback? onTap;

  const PlayerCard({
    Key? key,
    required this.name,
    required this.number,
    this.isSelected = false,
    this.isSelectable = true,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isSelectable ? onTap : null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 100,
          minHeight: 120,
          maxWidth: 100,
          maxHeight: 120,
        ),
        child: Card(
          elevation: isSelected ? 4 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isSelected ? Colors.black : Colors.transparent,
              width: 2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Player number
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? Colors.black : Colors.grey[300],
                  ),
                  child: Center(
                    child: Text(
                      '$number',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Player name
                Flexible(
                  child: Text(
                    name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                // Selected indicator
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: Colors.black,
                    size: 16,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 
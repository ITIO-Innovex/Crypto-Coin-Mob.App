import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';

class ThemeToggleButton extends StatelessWidget {
  final bool showLabel;
  final double iconSize;

  const ThemeToggleButton({
    Key? key,
    this.showLabel = true,
    this.iconSize = 24.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return GestureDetector(
          onTap: () => themeProvider.toggleTheme(),
          child: Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              color: themeProvider.isDarkMode 
                  ? Colors.grey[800] 
                  : Colors.grey[200],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  themeProvider.isDarkMode 
                      ? Icons.light_mode 
                      : Icons.dark_mode,
                  size: iconSize,
                  color: themeProvider.isDarkMode 
                      ? Colors.yellow 
                      : Colors.grey[700],
                ),
                if (showLabel) ...[
                  const SizedBox(width: 8.0),
                  Text(
                    themeProvider.isDarkMode ? 'Light' : 'Dark',
                    style: TextStyle(
                      color: themeProvider.isDarkMode 
                          ? Colors.white 
                          : Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
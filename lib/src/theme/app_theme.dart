import 'package:flutter/material.dart';

class AppTheme {
  // Colors
  static const Color primaryColor = Color(0xFF0D47A1); // Deep Blue
  static const Color secondaryColor = Color(0xFF1976D2);
  static const Color errorColor = Color(0xFFB00020);
  static const Color backgroundColor = Colors.white;

  // Text Styles
  static const TextStyle headingStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );

  static const TextStyle subheadingStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: Colors.black87,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 16,
    color: Colors.black87,
  );

  static const TextStyle labelStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Colors.black87,
  );

  // Input Decoration
  static const InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
    border: OutlineInputBorder(),
    filled: true,
    fillColor: Colors.white,
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );

  static InputDecoration get formFieldDecoration => const InputDecoration(
    border: OutlineInputBorder(),
    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
    filled: true,
    fillColor: Colors.white,
  );

  static InputDecoration formFieldDecorationWithLabel(String label, [String? hint]) {
    return formFieldDecoration.copyWith(
      labelText: label,
      hintText: hint,
    );
  }

  // Button Styles - Simplified to a single base style
  static final ButtonStyle baseButtonStyle = FilledButton.styleFrom(
    minimumSize: const Size(double.infinity, 48),
    padding: const EdgeInsets.symmetric(vertical: 16.0),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(25),
    ),
  );

  // Filled button style
  static ButtonStyle get filledButtonStyle => baseButtonStyle;

  // Variant for outlined buttons
  static final ButtonStyle outlinedButtonStyle = OutlinedButton.styleFrom(
    minimumSize: const Size(double.infinity, 48),
    padding: const EdgeInsets.symmetric(vertical: 16.0),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );

  // Variant for selected/unselected state
  static ButtonStyle getButtonStyle({bool isSelected = true}) {
    return baseButtonStyle.copyWith(
      backgroundColor: WidgetStateProperty.resolveWith((states) => 
        isSelected ? primaryColor : Colors.white
      ),
      foregroundColor: WidgetStateProperty.resolveWith((states) => 
        isSelected ? Colors.white : primaryColor
      ),
      elevation: WidgetStateProperty.resolveWith((states) => 
        isSelected ? 2.0 : 6.0
      ),
      shadowColor: WidgetStateProperty.resolveWith((states) => 
        primaryColor.withAlpha(128)
      ),
      surfaceTintColor: WidgetStateProperty.resolveWith((states) => 
        isSelected ? Colors.white.withAlpha(26) : primaryColor.withAlpha(13)
      ),
      side: WidgetStateProperty.resolveWith((states) => 
        BorderSide(
          color: isSelected ? Colors.transparent : primaryColor.withAlpha(77),
          width: 1.5,
        )
      ),
    );
  }

  // Spacing
  static const double spacing = 16.0;
  static const double smallSpacing = 8.0;
  static const double largeSpacing = 24.0;

  // Toggle Button Constraints
  static const double toggleMaxWidth = 400.0;
  static const double toggleButtonMinWidth = 160.0;

  // Standard Layout Patterns
  static const EdgeInsets screenPadding = EdgeInsets.all(spacing);

  static Widget screenContent({required Widget child}) {
    return Padding(
      padding: screenPadding,
      child: child,
    );
  }

  // Card Style
  static final CardTheme cardTheme = CardTheme(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    margin: const EdgeInsets.all(spacing),
  );

  static final EdgeInsets cardPadding = EdgeInsets.all(spacing);

  // Dropdown Style
  static final dropdownTheme = DropdownMenuThemeData(
    menuStyle: MenuStyle(
      elevation: WidgetStateProperty.resolveWith((states) => 2.0),
      shape: WidgetStateProperty.resolveWith((states) => 
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        )
      ),
      padding: WidgetStateProperty.resolveWith((states) => 
        const EdgeInsets.symmetric(horizontal: 12)
      ),
    ),
  );

  // Chip Style
  static final ChipThemeData chipTheme = ChipThemeData(
    backgroundColor: Color.fromARGB(26, primaryColor.r.toInt(), primaryColor.g.toInt(), primaryColor.b.toInt()),
    selectedColor: primaryColor,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    labelStyle: const TextStyle(fontSize: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  );

  // Main Theme Data
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      inputDecorationTheme: inputDecorationTheme,
      cardTheme: cardTheme,
      dropdownMenuTheme: dropdownTheme,
      filledButtonTheme: FilledButtonThemeData(style: baseButtonStyle),
      outlinedButtonTheme: OutlinedButtonThemeData(style: outlinedButtonStyle),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        titleLarge: headingStyle,
        titleMedium: subheadingStyle,
        bodyLarge: bodyStyle,
        labelLarge: labelStyle,
      ),
    );
  }
} 
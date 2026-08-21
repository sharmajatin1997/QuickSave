import 'package:flutter/material.dart';
import '../screens/settings_screen.dart';
import 'neubrutal.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget child;

  const ResponsiveLayout({super.key, required this.child});

  static bool isTablet(BuildContext context) => MediaQuery.of(context).size.width >= 900;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color borderColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 900) {
            return child;
          }

          // Tablet Layout
          return Row(
            children: [
              // Main App Content
              Expanded(
                flex: 3,
                child: child,
              ),
              
              // Vertical Divider (Neubrutal Style)
              Container(
                width: 3,
                color: borderColor,
              ),

              // Persistent Sidebar (Settings)
              SizedBox(
                width: 420,
                child: Scaffold(
                  backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  appBar: NeuAppBar(
                    title: "Settings",
                    fontSize: 24,
                    centerTitle: false, // Left align sidebar title for better professional look
                    leading: const SizedBox.shrink(),
                    actions: const [],
                  ),
                  body: const SettingsBody(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

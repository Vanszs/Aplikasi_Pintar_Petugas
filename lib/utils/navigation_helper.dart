import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Helper class to handle navigation and back button behavior
class NavigationHelper {
  /// This will ensure proper back navigation either within the app or to home screen
  /// If navigation stack is empty, it will minimize the app instead of closing
  static Future<bool> handleBackPress(BuildContext context) async {
    // Get the current navigation state
    final GoRouter router = GoRouter.of(context);
    
    // Check if we can pop the current route
    if (router.canPop()) {
      // We have routes in our stack, so go back
      router.pop();
      return false; // Don't exit the app
    } else {
      // We're at the root route, minimize app instead of exiting
      // Use moveTaskToBack technique via a platform channel
      try {
        const platform = MethodChannel('com.example.petugas_pintar/app_control');
        await platform.invokeMethod('moveTaskToBack');
      } catch (e) {
        debugPrint('Could not minimize app: $e');
      }
      return false; // Prevent closing the app
    }
  }
}

/// Widget to wrap any screen for proper back button handling
class BackButtonHandler extends StatelessWidget {
  final Widget child;
  
  const BackButtonHandler({Key? key, required this.child}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        
        final navigator = GoRouter.of(context);
        if (navigator.canPop()) {
          navigator.pop();
        } else {
          // We're at root, minimize app
          try {
            const platform = MethodChannel('com.example.petugas_pintar/app_control');
            await platform.invokeMethod('moveTaskToBack');
          } catch (e) {
            debugPrint('Could not minimize app: $e');
          }
        }
      },
      child: child,
    );
  }
}

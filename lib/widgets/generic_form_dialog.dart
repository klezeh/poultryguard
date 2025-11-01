// lib/widgets/generic_form_dialog.dart
import 'package:flutter/material.dart';

class GenericFormDialog extends StatelessWidget {
  final Widget child;

  const GenericFormDialog({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Determine screen dimensions to size the dialog dynamically
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Dialog(
      backgroundColor: Colors.transparent, // Make dialog background transparent
      insetPadding: EdgeInsets.zero, // Control padding purely with the container below
      child: Center( // Center the content within the dialog area
        child: ClipRRect( // Clip the content to the rounded corners of the dialog
          borderRadius: BorderRadius.circular(20),
          child: ConstrainedBox( // Constrain the size to be dialog-like
            constraints: BoxConstraints(
              maxWidth: screenWidth * 0.9, // Max 90% of screen width
              maxHeight: screenHeight * 0.8, // Max 80% of screen height
              minHeight: screenHeight * 0.5, // Minimum height to avoid very small dialogs
            ),
            child: Material( // Wrap the Scaffold in Material to get proper theming and interactions
              color: Theme.of(context).scaffoldBackgroundColor, // Use scaffold background color
              child: child, // This child is expected to be a Scaffold (e.g., AddFeedUsedScreen)
            ),
          ),
        ),
      ),
    );
  }
}

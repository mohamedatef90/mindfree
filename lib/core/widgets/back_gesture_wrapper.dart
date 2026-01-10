import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A wrapper widget that enables iOS-style swipe from left edge to go back
class BackGestureWrapper extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final double edgeWidth;

  const BackGestureWrapper({
    super.key,
    required this.child,
    this.enabled = true,
    this.edgeWidth = 40,
  });

  @override
  State<BackGestureWrapper> createState() => _BackGestureWrapperState();
}

class _BackGestureWrapperState extends State<BackGestureWrapper> {
  double _dragOffset = 0;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || !context.canPop()) {
      return widget.child;
    }

    return GestureDetector(
      onHorizontalDragStart: (details) {
        // Only start if drag starts from left edge
        if (details.localPosition.dx < widget.edgeWidth) {
          setState(() {
            _isDragging = true;
            _dragOffset = 0;
          });
        }
      },
      onHorizontalDragUpdate: (details) {
        if (_isDragging) {
          setState(() {
            _dragOffset = (_dragOffset + details.delta.dx).clamp(0.0, MediaQuery.of(context).size.width);
          });
        }
      },
      onHorizontalDragEnd: (details) {
        if (_isDragging) {
          final screenWidth = MediaQuery.of(context).size.width;
          final velocity = details.primaryVelocity ?? 0;

          // Pop if dragged more than 30% or velocity is high enough
          if (_dragOffset > screenWidth * 0.3 || velocity > 500) {
            context.pop();
          }

          setState(() {
            _isDragging = false;
            _dragOffset = 0;
          });
        }
      },
      onHorizontalDragCancel: () {
        setState(() {
          _isDragging = false;
          _dragOffset = 0;
        });
      },
      child: Stack(
        children: [
          // Shadow overlay
          if (_isDragging && _dragOffset > 0)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(
                  alpha: 0.3 * (1 - _dragOffset / MediaQuery.of(context).size.width),
                ),
              ),
            ),
          // Main content with transform
          Transform.translate(
            offset: Offset(_dragOffset, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

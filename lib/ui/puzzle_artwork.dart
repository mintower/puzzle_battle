import 'package:flutter/material.dart';

/// A simple procedurally-drawn picture (a gradient sky, sun, and two
/// mountain ranges) used for "picture mode" tiles. Generated in code
/// instead of bundling an image asset, so board_view can slice it per
/// tile purely from size math.
class PuzzleArtworkPainter extends CustomPainter {
  const PuzzleArtworkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4F46E5), Color(0xFFFDE68A)],
        ).createShader(rect),
    );

    canvas.drawCircle(
      Offset(size.width * 0.78, size.height * 0.22),
      size.width * 0.14,
      Paint()..color = const Color(0xFFF97316),
    );

    final farMountains = Path()
      ..moveTo(0, size.height * 0.62)
      ..lineTo(size.width * 0.25, size.height * 0.42)
      ..lineTo(size.width * 0.5, size.height * 0.62)
      ..lineTo(size.width * 0.75, size.height * 0.38)
      ..lineTo(size.width, size.height * 0.6)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(farMountains, Paint()..color = const Color(0xFF6D28D9));

    final nearMountains = Path()
      ..moveTo(0, size.height * 0.8)
      ..lineTo(size.width * 0.2, size.height * 0.6)
      ..lineTo(size.width * 0.42, size.height * 0.78)
      ..lineTo(size.width * 0.68, size.height * 0.55)
      ..lineTo(size.width * 0.9, size.height * 0.78)
      ..lineTo(size.width, size.height * 0.7)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(nearMountains, Paint()..color = const Color(0xFF312E81));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Small reference thumbnail of the complete picture, shown alongside the
/// board in picture mode so players have something to solve toward —
/// without it, a shuffled picture gives no clue which piece goes where.
class PuzzlePreviewThumbnail extends StatelessWidget {
  final double size;

  const PuzzlePreviewThumbnail({super.key, this.size = 72});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: size,
        height: size,
        child: const CustomPaint(painter: PuzzleArtworkPainter()),
      ),
    );
  }
}

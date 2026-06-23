import 'package:flutter/material.dart';

import 'package:aquarela_watercolor_sketch/theme/tokens/paper.dart';
import 'package:aquarela_watercolor_sketch/theme/tokens/pigment.dart';

/// Slide 3: Suas obras, guardadas.
/// A 3x2 gallery grid with one artwork highlighted (saved) and a clear share icon.
class Slide3GalleryIllustration extends StatelessWidget {
  const Slide3GalleryIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(320, 320),
      painter: _Slide3Painter(),
    );
  }
}

class _Slide3Painter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // === 3x2 grid of small artworks ===
    const cols = 3;
    const rows = 2;
    const cellSize = 60.0;
    const gap = 12.0;
    final totalW = cols * cellSize + (cols - 1) * gap;
    final startX = (w - totalW) / 2;
    final startY = h * 0.40;

    // The "saved" card is the middle-right one (row 0, col 2)
    const savedRow = 0;
    const savedCol = 2;

    // Different pigment blobs in non-saved cards (more variety than before)
    final blobColors = [
      [Pigment.ultramar, Pigment.cadmiumYellow],
      [Pigment.burntSienna, Pigment.ultramar],
      [Pigment.ultramar, Pigment.burntSienna],
      [Pigment.cadmiumYellow, Pigment.burntSienna],
      [Pigment.burntSienna, Pigment.ultramar],
    ];
    var blobIdx = 0;

    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final x = startX + c * (cellSize + gap);
        final y = startY + r * (cellSize + gap);

        final isSaved = r == savedRow && c == savedCol;

        // Card background
        final cardPaint = Paint()
          ..color = isSaved ? Paper.white : Paper.cream;
        final card = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, cellSize, cellSize),
          const Radius.circular(8),
        );
        canvas.drawRRect(card, cardPaint);

        // Subtle border
        final borderPaint = Paint()
          ..color = Paper.mist.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5;
        canvas.drawRRect(card, borderPaint);

        if (isSaved) {
          // The saved card: vibrant cadmium yellow with a brush stroke
          final savedBg = Paint()..color = Pigment.cadmiumYellow;
          canvas.drawRRect(card, savedBg);

          // A brush stroke in burnt sienna inside
          final strokePaint = Paint()
            ..color = Pigment.burntSienna.withValues(alpha: 0.7)
            ..style = PaintingStyle.fill
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
          final strokePath = Path();
          strokePath.moveTo(x + 12, y + cellSize - 14);
          strokePath.quadraticBezierTo(
            x + cellSize / 2,
            y + 16,
            x + cellSize - 12,
            y + cellSize - 18,
          );
          strokePath.quadraticBezierTo(
            x + cellSize / 2,
            y + cellSize - 24,
            x + 12,
            y + cellSize - 14,
          );
          strokePath.close();
          canvas.drawPath(strokePath, strokePaint);

          // Small check in corner
          final checkPaint = Paint()
            ..color = Paper.ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..strokeCap = StrokeCap.round;
          final checkPath = Path();
          final cx = x + cellSize - 14;
          final cy = y + 14;
          checkPath.moveTo(cx - 5, cy);
          checkPath.lineTo(cx - 1, cy + 4);
          checkPath.lineTo(cx + 5, cy - 4);
          canvas.drawPath(checkPath, checkPaint);
        } else {
          // Other cards: a soft pigment blob preview
          final colors = blobColors[blobIdx % blobColors.length];
          blobIdx++;
          final blobPaint = Paint()
            ..shader = RadialGradient(
              colors: [
                colors[0].withValues(alpha: 0.4),
                colors[1].withValues(alpha: 0.25),
              ],
            ).createShader(Rect.fromLTWH(x, y, cellSize, cellSize))
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
          canvas.drawCircle(
            Offset(x + cellSize / 2, y + cellSize / 2),
            18,
            blobPaint,
          );
        }
      }
    }

    // === Share icon — BOX WITH UPWARD ARROW (universal) ===
    // Positioned above-right of the grid, clearly visible
    final shareCenterX = w * 0.85;
    final shareCenterY = startY - 20;

    // Box outline
    final boxSize = 32.0;
    final boxRect = Rect.fromCenter(
      center: Offset(shareCenterX, shareCenterY),
      width: boxSize,
      height: boxSize,
    );
    final boxPaint = Paint()
      ..color = Pigment.ultramar
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round;
    final boxRRect = RRect.fromRectAndRadius(boxRect, const Radius.circular(6));
    canvas.drawRRect(boxRRect, boxPaint);

    // Arrow pointing up (from inside the box, exiting through the top)
    final arrowPaint = Paint()
      ..color = Pigment.ultramar
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final arrowPath = Path();
    final ax = shareCenterX;
    final ay = shareCenterY;
    // Vertical line going up
    arrowPath.moveTo(ax, ay - 16); // tip
    arrowPath.lineTo(ax, ay + 4);  // base
    // Arrow head
    arrowPath.moveTo(ax - 5, ay - 11);
    arrowPath.lineTo(ax, ay - 16);
    arrowPath.lineTo(ax + 5, ay - 11);
    canvas.drawPath(arrowPath, arrowPaint);

    // Subtle dotted line connecting the share icon to the saved card
    final linePaint = Paint()
      ..color = Pigment.ultramar.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    final savedX = startX + savedCol * (cellSize + gap) + cellSize / 2;
    final savedY = startY + savedRow * (cellSize + gap);
    // Draw 3 small dots forming an arc
    for (var i = 0; i < 3; i++) {
      final px = savedX + (shareCenterX - savedX) * (0.3 + i * 0.25);
      final py = savedY - 10 - (i * 4.0);
      canvas.drawCircle(Offset(px, py), 1.5, linePaint);
    }
  }

  @override
  bool shouldRepaint(_Slide3Painter oldDelegate) => false;
}

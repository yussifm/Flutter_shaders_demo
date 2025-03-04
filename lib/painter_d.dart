import 'package:flutter/material.dart';
import "dart:math";

class LinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.teal
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.fill;

    canvas.drawLine(Offset(0, size.height * 0.3),
        Offset(size.width, size.height * 0.3), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class CirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;

    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5), 30, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class StarPainter extends CustomPainter {
   double angle = -pi / 2;
 


  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    Path path = Path();

      double radius = size.width / 2;
    double innerRadius = radius / 2.5;

    for (int i = 0; i < 5; i++) {
      path.moveTo(radius * cos(angle) + size.width / 2,
          radius * cos(angle) + size.height / 2);

      angle += pi / 5;
      path.lineTo(innerRadius * cos(angle) + size.width / 2,
          innerRadius * cos(angle) + size.height / 2);
      angle += pi / 5;
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(StarPainter oldDelegate) {
    return angle != oldDelegate.angle;
  }
}


class RotatingStarPainter extends CustomPainter {
  final double rotation;

  RotatingStarPainter({required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(rotation);
    canvas.translate(-size.width / 2, -size.height / 2);

    Paint paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    Path path = Path();
    double angle = -pi / 2;
    double radius = size.width / 2;
    double innerRadius = radius / 2.5;

    for (int i = 0; i < 5; i++) {
      path.moveTo(
        radius * cos(angle),
        radius * sin(angle),
      );
      angle += pi / 5;
      path.lineTo(
        innerRadius * cos(angle),
        innerRadius * sin(angle),
      );
      angle += pi / 5;
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(RotatingStarPainter oldDelegate) {
    return  rotation != oldDelegate.rotation;
  }
}
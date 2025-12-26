import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

void main() => runApp(const MainApp());

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: ShaderScreen(),
  );
}

class ShaderScreen extends StatefulWidget {
  const ShaderScreen({super.key});

  @override
  State<ShaderScreen> createState() => _ShaderScreenState();
}

class _ShaderScreenState extends State<ShaderScreen>
    with SingleTickerProviderStateMixin {
  late Ticker ticker;
  double time = 0;

  @override
  void initState() {
    super.initState();

    ticker = createTicker(
      (elapsed) => setState(() => time = elapsed.inMilliseconds / 1000.0),
    )..start();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: Center(
      child: CustomPaint(
        painter: ShaderPainter(time: time),
        size: const Size(200, 200),
      ),
    ),
  );

  @override
  void dispose() {
    ticker.dispose();

    super.dispose();
  }
}

class ShaderPainter extends CustomPainter {
  final double time;

  ShaderPainter({required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    final points = <Offset>[];
    final colors = <Color>[];

    final step = 1.0;

    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        final color = computeShader(x, y, size.width, size.height, time);
        points.add(Offset(x, y));
        colors.add(color);
      }
    }

    for (int i = 0; i < points.length; i++) {
      final paint = Paint()
        ..color = colors[i]
        ..strokeWidth = step
        ..strokeCap = StrokeCap.square;
      final pointData = Float32List.fromList([points[i].dx, points[i].dy]);

      canvas.drawRawPoints(ui.PointMode.points, pointData, paint);
    }
  }

  Color computeShader(
    double x,
    double y,
    double width,
    double height,
    double t,
  ) {
    final canvasSize = Vector2(width, height);

    var positionVector = Vector2(
      (x * 2.0 - canvasSize.x) / canvasSize.y,
      (y * 2.0 - canvasSize.y) / canvasSize.y,
    );
    var originPoint = Vector2(0.0, 0.0);
    var initialPosition = Vector2(0.0, 0.0);

    final positionDotProduct = positionVector.dot(positionVector);
    final lightAdjustment = 4.0 - 4.0 * (0.7 - positionDotProduct).abs();

    originPoint = originPoint + Vector2(lightAdjustment, lightAdjustment);

    var transformedPosition = positionVector * originPoint;
    var output = Vector4(0.0, 0.0, 0.0, 0.0);

    for (
      initialPosition.y = 1.0;
      initialPosition.y <= 8.0;
      initialPosition.y++
    ) {
      final s = Vector4(
        math.sin(transformedPosition.x) + 1.0,
        math.sin(transformedPosition.y) + 1.0,
        math.sin(transformedPosition.y) + 1.0,
        math.sin(transformedPosition.x) + 1.0,
      );

      final positionDifference = (transformedPosition.x - transformedPosition.y)
          .abs();
      output = output + s * positionDifference;

      final cosVec =
          (transformedPosition.yx * initialPosition.y +
                      initialPosition +
                      Vector2(t, t))
                  .cos() /
              initialPosition.y +
          Vector2(0.7, 0.7);

      transformedPosition = transformedPosition + cosVec;
    }

    final expBase = originPoint.x - 4.0;
    final e = Vector4(
      math.exp(expBase - positionVector.y * -1.0),
      math.exp(expBase - positionVector.y * 1.0),
      math.exp(expBase - positionVector.y * 2.0),
      math.exp(expBase - positionVector.y * 0.0),
    );

    output = Vector4(
      output.x != 0 ? Vector4._tanh(5.0 * e.x / output.x) : 0.0,
      output.y != 0 ? Vector4._tanh(5.0 * e.y / output.y) : 0.0,
      output.z != 0 ? Vector4._tanh(5.0 * e.z / output.z) : 0.0,
      output.w != 0 ? Vector4._tanh(5.0 * e.w / output.w) : 0.0,
    );

    return output.clamp(0.0, 1.0).toColor();
  }

  @override
  bool shouldRepaint(ShaderPainter oldDelegate) => true;
}

class Vector2 {
  double x;
  double y;

  Vector2(this.x, this.y);

  Vector2 operator +(Vector2 other) => Vector2(x + other.x, y + other.y);

  Vector2 operator -(Vector2 other) => Vector2(x - other.x, y - other.y);

  Vector2 operator *(dynamic other) {
    if (other is Vector2) return Vector2(x * other.x, y * other.y);

    return Vector2(x * other, y * other);
  }

  Vector2 operator /(dynamic other) {
    if (other is Vector2) return Vector2(x / other.x, y / other.y);

    return Vector2(x / other, y / other);
  }

  double dot(Vector2 other) => x * other.x + y * other.y;

  double get length => math.sqrt(x * x + y * y);

  Vector2 abs() => Vector2(x.abs(), y.abs());

  Vector2 clamp(double min, double max) =>
      Vector2(x.clamp(min, max), y.clamp(min, max));

  Vector2 sin() => Vector2(math.sin(x), math.sin(y));

  Vector2 cos() => Vector2(math.cos(x), math.cos(y));

  Vector2 get yx => Vector2(y, x);
}

class Vector4 {
  double x;
  double y;
  double z;
  double w;

  Vector4(this.x, this.y, this.z, this.w);

  Vector4 operator +(Vector4 other) =>
      Vector4(x + other.x, y + other.y, z + other.z, w + other.w);

  Vector4 operator -(Vector4 other) =>
      Vector4(x - other.x, y - other.y, z - other.z, w - other.w);

  Vector4 operator *(dynamic other) {
    if (other is Vector4) {
      return Vector4(x * other.x, y * other.y, z * other.z, w * other.w);
    }

    return Vector4(x * other, y * other, z * other, w * other);
  }

  Vector4 operator /(Vector4 other) =>
      Vector4(x / other.x, y / other.y, z / other.z, w / other.w);

  Vector4 abs() => Vector4(x.abs(), y.abs(), z.abs(), w.abs());

  Vector4 clamp(double min, double max) => Vector4(
    x.clamp(min, max),
    y.clamp(min, max),
    z.clamp(min, max),
    w.clamp(min, max),
  );

  Vector4 sin() => Vector4(math.sin(x), math.sin(y), math.sin(z), math.sin(w));

  Vector4 exp() => Vector4(math.exp(x), math.exp(y), math.exp(z), math.exp(w));

  Vector4 tanh() => Vector4(_tanh(x), _tanh(y), _tanh(z), _tanh(w));

  static double _tanh(double x) {
    final e2x = math.exp(2 * x);
    return (e2x - 1) / (e2x + 1);
  }

  Color toColor() => Color.fromARGB(
    255,
    (x.clamp(0.0, 1.0) * 255).toInt(),
    (y.clamp(0.0, 1.0) * 255).toInt(),
    (z.clamp(0.0, 1.0) * 255).toInt(),
  );
}

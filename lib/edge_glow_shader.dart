import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class EdgeGlowShaderExample extends StatefulWidget {
  const EdgeGlowShaderExample({super.key});

  @override
  State<EdgeGlowShaderExample> createState() => _EdgeGlowShaderExampleState();
}

class _EdgeGlowShaderExampleState extends State<EdgeGlowShaderExample> with SingleTickerProviderStateMixin {
  ui.FragmentShader? shader;
  late Ticker _ticker;
  double _time = 0.0;
  Color _glowColor = Colors.blue;
  double _glowWidth = 0.15;

  @override
  void initState() {
    super.initState();
    _loadShader();
    _ticker = createTicker((elapsed) {
      setState(() {
        _time = elapsed.inMilliseconds / 1000.0; // Convert to seconds
      });
    });
    _ticker.start();
  }

  Future<void> _loadShader() async {
    final program = await ui.FragmentProgram.fromAsset('assets/shaders/edge_glow.frag');
    setState(() {
      shader = program.fragmentShader();
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edge Glow Shader'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (shader != null)
              Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: CustomPaint(
                  painter: EdgeGlowPainter(
                    shader: shader!,
                    time: _time,
                    color: _glowColor,
                    glowWidth: _glowWidth,
                  ),
                ),
              )
            else
              const CircularProgressIndicator(),
            
            const SizedBox(height: 40),
            
            // Color controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Glow Color: '),
                const SizedBox(width: 10),
                ...Colors.primaries.take(5).map((color) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => setState(() => _glowColor = color),
                      child: CircleAvatar(
                        radius: 15,
                        backgroundColor: color,
                        child: _glowColor == color 
                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                            : null,
                      ),
                    ),
                  );
                }),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Width control
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                children: [
                  const Text('Glow Width:'),
                  Expanded(
                    child: Slider(
                      value: _glowWidth,
                      min: 0.05,
                      max: 0.3,
                      onChanged: (value) => setState(() => _glowWidth = value),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EdgeGlowPainter extends CustomPainter {
  final ui.FragmentShader shader;
  final double time;
  final Color color;
  final double glowWidth;

  EdgeGlowPainter({
    required this.shader,
    required this.time,
    required this.color,
    required this.glowWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Set uniforms
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    
    // Set color
    shader.setFloat(2, color.red / 255.0);
    shader.setFloat(3, color.green / 255.0);
    shader.setFloat(4, color.blue / 255.0);
    shader.setFloat(5, color.alpha / 255.0);
    
    // Set time for animation
    shader.setFloat(6, time);
    
    // Set glow width
    shader.setFloat(7, glowWidth);

    // Draw the rectangle
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = shader,
    );
  }

  @override
  bool shouldRepaint(covariant EdgeGlowPainter oldDelegate) {
    return oldDelegate.time != time ||
           oldDelegate.color != color ||
           oldDelegate.glowWidth != glowWidth;
  }
}
import 'dart:ui';

import 'package:flutter/material.dart';

class ShaderExample extends StatefulWidget {
  final FragmentProgram programShader;
  
  const ShaderExample({super.key, required this.programShader});

  @override
  State<ShaderExample> createState() => _ShaderExampleState();
}

class _ShaderExampleState extends State<ShaderExample> {
  late FragmentShader shader;
  
  @override
  void initState() {
    super.initState();
    // Create the shader from the program
    shader = widget.programShader.fragmentShader();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shader Example'),
      ),
      body: Center(
        child: CustomPaint(
          painter: ShaderPainter(shader: shader, color: Colors.blue),
          child: const SizedBox(
            width: 300,
            height: 300,
          ),
        ),
      ),
    );
  }
}

class ShaderPainter extends CustomPainter {
  final FragmentShader shader;
  final Color color;

  ShaderPainter({required this.shader, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Set shader uniforms
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    
    shader.setFloat(2, color.red / 255.0);
    shader.setFloat(3, color.green / 255.0);
    shader.setFloat(4, color.blue / 255.0);
    shader.setFloat(5, color.alpha / 255.0);

    // Draw the rectangle using the shader
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = shader,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
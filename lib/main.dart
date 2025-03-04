import 'dart:math';
import 'dart:ui';

import 'package:demo_one/edge_glow_shader.dart';
import 'package:demo_one/modern_voice.dart';
import 'package:demo_one/painter_d.dart';
import 'package:demo_one/shaders_to.dart';
import 'package:flutter/material.dart';

late FragmentProgram fprogram;

Future<void> main() async {
  fprogram = await FragmentProgram.fromAsset("assets/shaders/myshader.frag");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // home: ShaderExample(
      //   programShader: fprogram,
      // ),
      // home: EdgeGlowShaderExample(),
      home: ModernVoiceUI(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  late Animation<double> _rotationAnimation;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 2 * pi).animate(
      _controller,
    );

    _controller.repeat();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("Painters and Shaders in Flutter"),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            CustomPaint(
              painter: LinePainter(),
              child: SizedBox(
                width: double.infinity,
                height: 200,
              ),
            ),
            CustomPaint(
              painter: CirclePainter(),
              child: SizedBox(
                width: double.infinity,
                height: 200,
              ),
            ),
            AnimatedBuilder(
                animation: _rotationAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    painter:
                        RotatingStarPainter(rotation: _rotationAnimation.value),
                    child: SizedBox(
                      width: 200,
                      height: 200,
                    ),
                  );
                }),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.stop();
    _controller.dispose();
    super.dispose();
  }
}

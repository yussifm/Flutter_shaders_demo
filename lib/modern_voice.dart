import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class ModernVoiceUI extends StatefulWidget {
  const ModernVoiceUI({super.key});

  @override
  State<ModernVoiceUI> createState() => _ModernVoiceUIState();
}

class _ModernVoiceUIState extends State<ModernVoiceUI> with SingleTickerProviderStateMixin {
  ui.FragmentShader? shader;
  late Ticker _ticker;
  double _time = 0.0;
  Color _primaryColor = const Color(0xFF6C63FF);   // Purple-ish
  Color _secondaryColor = const Color(0xFF00BFA6); // Teal-ish
  double _intensity = 0.18;
  double _frequency = 0.5;
  bool _isListening = false;
  String _transcribedText = '';
  List<String> _savedMessages = [
    "How can I help you today?",
    "Weather looks great for the weekend.",
    "Your meeting has been scheduled for 3 PM."
  ];

  @override
  void initState() {
    super.initState();
    _loadShader();
    _ticker = createTicker((elapsed) {
      setState(() {
        _time = elapsed.inMilliseconds / 1000.0;
      });
    });
    _ticker.start();
  }

  Future<void> _loadShader() async {
    final program = await ui.FragmentProgram.fromAsset('assets/shaders/breathing_edge.frag');
    setState(() {
      shader = program.fragmentShader();
    });
  }

  void _toggleListening() {
    setState(() {
      _isListening = !_isListening;
      if (_isListening) {
        _transcribedText = 'Listening...';
        // In a real app, you would start ASR service here
      } else {
        if (_transcribedText == 'Listening...') {
          _transcribedText = 'Tap the mic to start speaking';
        } else {
          // Add the transcribed text to saved messages
          _savedMessages.insert(0, _transcribedText);
          _transcribedText = '';
        }
      }
    });
  }

  void _simulateTranscription() {
    if (_isListening) {
      setState(() {
        _transcribedText = 'Can you tell me about the weather forecast for tomorrow?';
      });
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    return Scaffold(
      body: Stack(
        children: [
          // Background with shader
          if (shader != null)
            Positioned.fill(
              child: CustomPaint(
                painter: BreathingEdgePainter(
                  shader: shader!,
                  time: _time,
                  primaryColor: _primaryColor,
                  secondaryColor: _secondaryColor,
                  intensity: _intensity,
                  frequency: _frequency,
                ),
              ),
            ),
            
          // Main content
          SafeArea(
            child: Column(
              children: [
                // App bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      const Text('VoiceAssist', 
                        style: TextStyle(
                          fontSize: 22, 
                          fontWeight: FontWeight.bold,
                          color: Colors.white
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.settings, color: Colors.white),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                
                // Chat/transcript area
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: ListView(
                        padding: const EdgeInsets.all(20),
                        reverse: true,
                        children: [
                          if (_transcribedText.isNotEmpty)
                            MessageBubble(
                              message: _transcribedText,
                              isUser: true,
                              isTyping: _isListening && _transcribedText == 'Listening...',
                            ),
                          const SizedBox(height: 12),
                          ..._savedMessages.map((message) => 
                            MessageBubble(
                              message: message,
                              isUser: _savedMessages.indexOf(message) % 2 == 0 ? false : true,
                            )
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Voice controls
                Container(
                  height: 120,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: GestureDetector(
                      onTap: _toggleListening,
                      onLongPress: _simulateTranscription, // For demo purposes
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: _isListening ? 80 : 70,
                        height: _isListening ? 80 : 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isListening 
                              ? _primaryColor.withOpacity(0.9) 
                              : Colors.white.withOpacity(0.2),
                          border: Border.all(
                            color: _isListening ? _secondaryColor : Colors.white.withOpacity(0.5),
                            width: 2,
                          ),
                          boxShadow: _isListening 
                              ? [
                                  BoxShadow(
                                    color: _primaryColor.withOpacity(0.5),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  )
                                ] 
                              : [],
                        ),
                        child: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          color: _isListening ? Colors.white : Colors.white.withOpacity(0.7),
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BreathingEdgePainter extends CustomPainter {
  final ui.FragmentShader shader;
  final double time;
  final Color primaryColor;
  final Color secondaryColor;
  final double intensity;
  final double frequency;

  BreathingEdgePainter({
    required this.shader,
    required this.time,
    required this.primaryColor,
    required this.secondaryColor,
    required this.intensity,
    required this.frequency,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Set uniforms
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    
    // Set primary color
    shader.setFloat(2, primaryColor.red / 255.0);
    shader.setFloat(3, primaryColor.green / 255.0);
    shader.setFloat(4, primaryColor.blue / 255.0);
    shader.setFloat(5, primaryColor.alpha / 255.0);
    
    // Set secondary color
    shader.setFloat(6, secondaryColor.red / 255.0);
    shader.setFloat(7, secondaryColor.green / 255.0);
    shader.setFloat(8, secondaryColor.blue / 255.0);
    shader.setFloat(9, secondaryColor.alpha / 255.0);
    
    // Set time for animation
    shader.setFloat(10, time);
    
    // Set edge intensity
    shader.setFloat(11, intensity);
    
    // Set breathing frequency
    shader.setFloat(12, frequency);

    // Draw the rectangle covering the entire canvas
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = shader,
    );
  }

  @override
  bool shouldRepaint(covariant BreathingEdgePainter oldDelegate) {
    return oldDelegate.time != time ||
           oldDelegate.primaryColor != primaryColor ||
           oldDelegate.secondaryColor != secondaryColor ||
           oldDelegate.intensity != intensity ||
           oldDelegate.frequency != frequency;
  }
}

class MessageBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final bool isTyping;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isUser,
    this.isTyping = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser)
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6C63FF).withOpacity(0.7),
              ),
              child: const Icon(
                Icons.assistant,
                color: Colors.white,
                size: 20,
              ),
            ),
            
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser 
                    ? const Color(0xFF3D3D3D)
                    : const Color(0xFF6C63FF).withOpacity(0.7),
                borderRadius: BorderRadius.circular(18),
              ),
              child: isTyping
                ? _buildTypingIndicator()
                : Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
            ),
          ),
          
          if (isUser)
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF3D3D3D),
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildTypingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}
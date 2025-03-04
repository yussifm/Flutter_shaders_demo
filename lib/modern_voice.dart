import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:flutter_tts/flutter_tts.dart';

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
  double _voiceAmplitude = 0.0;
  Timer? _amplitudeDecayTimer;

  // Speech recognition
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _transcribedText = '';
  Timer? _listeningTimer;
  double _lastAmplitude = 0.0;

  // Text to speech
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;

  List<ChatMessage> _messages = [
    ChatMessage(
        text: "How can I help you today?",
        isUser: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5))),
  ];

  @override
  void initState() {
    super.initState();
    _loadShader();
    _initSpeech();
    _initTts();
    
    _ticker = createTicker((elapsed) {
      setState(() {
        _time = elapsed.inMilliseconds / 1000.0;
        
        // Decay voice amplitude over time for smooth transitions
        if (!_isListening && _voiceAmplitude > 0) {
          _voiceAmplitude = max(0, _voiceAmplitude - 0.02);
        }
      });
    });
    _ticker.start();
    
    // Set up amplitude decay timer
    _amplitudeDecayTimer =
        Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (mounted && _voiceAmplitude > 0 && !_isListening) {
        setState(() {
          _voiceAmplitude = max(0, _voiceAmplitude - 0.05);
        });
      }
    });
  }

  Future<void> _initSpeech() async {
    await _requestMicPermission();
    var available = await _speech.initialize(
      onStatus: _onSpeechStatus,
      onError: (error) => print('Speech error: $error'),
    );
    if (available) {
      _speech.statusListener = (status) {
        if (status == 'done' && _isListening) {
          setState(() {
            _isListening = false;
          });
        }
      };
    } else {
      print('Speech recognition not available on this device');
    }
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setStartHandler(() {
      setState(() {
        _isSpeaking = true;
      });
    });

    _flutterTts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
      });
    });

    _flutterTts.setErrorHandler((error) {
      setState(() {
        _isSpeaking = false;
      });
    });
  }

  Future<void> _requestMicPermission() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      await Permission.microphone.request();
    }
  }

  Future<void> _loadShader() async {
    final program = await ui.FragmentProgram.fromAsset('assets/shaders/breathing_edge.frag');
    setState(() {
      shader = program.fragmentShader();
    });
  }
  
  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _transcribedText = result.recognizedWords;

      // Simulate voice amplitude based on new words
      if (result.finalResult) {
        _voiceAmplitude = 0.0;
      } else {
        // Calculate approximate change in text to estimate amplitude
        double textLengthDiff =
            (result.recognizedWords.length - _lastAmplitude).abs() / 10;
        _voiceAmplitude = min(1.0, max(_voiceAmplitude, textLengthDiff));
        _lastAmplitude = result.recognizedWords.length.toDouble();
      }
    });
  }

  void _onSpeechStatus(String status) {
    if (status == 'listening') {
      setState(() {
        _isListening = true;
      });
    } else if (status == 'notListening' || status == 'done') {
      if (_isListening) {
        // Small delay to ensure final results are processed
        Future.delayed(const Duration(milliseconds: 500), () {
          setState(() {
            _isListening = false;
            if (_transcribedText.isNotEmpty &&
                _transcribedText != 'Listening...') {
              _processUserInput(_transcribedText);
            }
          });
        });
      }
    }
  }

  Future<void> _processUserInput(String text) async {
    if (text.trim().isEmpty) return;

    // Add user message
    setState(() {
      _messages.insert(
          0, ChatMessage(text: text, isUser: true, timestamp: DateTime.now()));
      _transcribedText = '';
    });

    // Generate a response (in a real app, this would call an API)
    String response = await _generateResponse(text);

    // Add assistant message
    setState(() {
      _messages.insert(
          0,
          ChatMessage(
              text: response, isUser: false, timestamp: DateTime.now()));
    });

    // Speak the response
    _speakResponse(response);
  }

  Future<String> _generateResponse(String text) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Simple response generator - in a real app, this would call an AI API
    final text = "";

    if (text.contains('hello') || text.contains('hi ')) {
      return "Hello! How can I help you today?";
    } else if (text.contains('weather')) {
      return "Currently it's partly cloudy with a temperature of 72°F. No rain is expected today.";
    } else if (text.contains('time')) {
      return "It's currently ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}.";
    } else if (text.contains('name')) {
      return "I'm your voice assistant. You can call me Ripple.";
    } else if (text.contains('thank')) {
      return "You're welcome! Is there anything else you'd like help with?";
    } else {
      return "I understand you said: '$text'. How can I help with that?";
    }
  }

  Future<void> _speakResponse(String text) async {
    // Simulate voice amplitude changes while speaking
    final words = text.split(' ');
    final durationPerWord = const Duration(milliseconds: 300);

    await _flutterTts.speak(text);

    // Simulate amplitude changes for visualization
    int wordIndex = 0;
    Timer.periodic(durationPerWord, (timer) {
      if (wordIndex < words.length && mounted) {
        setState(() {
          // Create a wave-like pattern for speaking animation
          _voiceAmplitude = 0.2 + 0.3 * sin(wordIndex * 0.5);

          // Add random variations for more natural feel
          _voiceAmplitude += 0.2 * Random().nextDouble();

          // Clamp to reasonable range
          _voiceAmplitude = _voiceAmplitude.clamp(0.1, 0.8);
        });
        wordIndex++;
      } else {
        timer.cancel();
        if (mounted) {
          setState(() {
            _voiceAmplitude = 0.0;
          });
        }
      }
    });
  }

  void _toggleListening() async {
    if (!_isListening) {
      var available = await _speech.initialize();
      if (available) {
        setState(() {
          _transcribedText = 'Listening...';
          _voiceAmplitude = 0.2; // Initial amplitude for "listening" state
        });

        await _speech.listen(
          onResult: _onSpeechResult,
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
          partialResults: true,
          localeId: 'en_US',
          cancelOnError: true,
          listenMode: stt.ListenMode.confirmation,
        );

        // Simulate amplitude changes for visualization
        _listeningTimer =
            Timer.periodic(const Duration(milliseconds: 100), (timer) {
          if (_isListening && mounted) {
            setState(() {
              // Create a breathing pattern with some randomness
              _voiceAmplitude =
                  0.2 + 0.1 * sin(_time * 5) + 0.1 * Random().nextDouble();
            });
          } else {
            timer.cancel();
          }
        });
      }
    } else {
      _listeningTimer?.cancel();
      await _speech.stop();
      setState(() {
        _isListening = false;
      });
    }
  }
  
  @override
  void dispose() {
    _ticker.dispose();
    _amplitudeDecayTimer?.cancel();
    _listeningTimer?.cancel();
    _speech.cancel();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  voiceAmplitude: _voiceAmplitude,
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
                      const Text(
                        'Ripple Voice', 
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
                      child: ListView.builder(
                        padding: const EdgeInsets.all(20),
                        reverse: true,
                        itemCount: _messages.length +
                            (_transcribedText.isNotEmpty ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == 0 && _transcribedText.isNotEmpty) {
                            return MessageBubble(
                              message: _transcribedText,
                              isUser: true,
                              isTyping: _isListening && _transcribedText == 'Listening...',
                            );
                          }

                          final actualIndex =
                              _transcribedText.isNotEmpty ? index - 1 : index;
                          return MessageBubble(
                            message: _messages[actualIndex].text,
                            isUser: _messages[actualIndex].isUser,
                            isActivelyResponding:
                                !_messages[actualIndex].isUser &&
                                    _isSpeaking &&
                                    actualIndex == 0,
                          );
                        },
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
  final double voiceAmplitude;

  BreathingEdgePainter({
    required this.shader,
    required this.time,
    required this.primaryColor,
    required this.secondaryColor,
    required this.intensity,
    required this.frequency,
    required this.voiceAmplitude,
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
    
    // Set voice amplitude
    shader.setFloat(13, voiceAmplitude);

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
        oldDelegate.frequency != frequency ||
        oldDelegate.voiceAmplitude != voiceAmplitude;
  }
}

class MessageBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final bool isTyping;
  final bool isActivelyResponding;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isUser,
    this.isTyping = false,
    this.isActivelyResponding = false,
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
                boxShadow: isActivelyResponding
                    ? [
                        BoxShadow(
                          color: const Color(0xFF6C63FF).withOpacity(0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        )
                      ]
                    : null,
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
                    : const Color(0xFF6C63FF)
                        .withOpacity(isActivelyResponding ? 0.9 : 0.7),
                borderRadius: BorderRadius.circular(18),
                boxShadow: isActivelyResponding
                    ? [
                        BoxShadow(
                          color: const Color(0xFF6C63FF).withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        )
                      ]
                    : null,
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
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 400 + index * 200),
          curve: Curves.easeInOut,
          builder: (context, value, child) {
            return Container(
              width: 8,
              height: 8 * (0.5 + value * 0.5),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

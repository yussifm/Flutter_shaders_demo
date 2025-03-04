#version 460 core

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;           // Canvas size
uniform vec4 uPrimaryColor;   // Primary glow color
uniform vec4 uSecondaryColor; // Secondary glow color
uniform float uTime;          // For animation
uniform float uIntensity;     // Edge intensity
uniform float uFrequency;     // Breathing frequency
uniform float uVoiceAmplitude; // Current voice amplitude

out vec4 FragColor;

// Function to create a smooth pulse effect
float pulse(float value, float intensity) {
    return (sin(value * 3.14159 * 2.0) * 0.5 + 0.5) * intensity;
}

void main() {
    // Get normalized coordinates
    vec2 uv = FlutterFragCoord() / uSize;

    // Center coordinates (from -1 to 1)
    vec2 centered = (uv - 0.5) * 2.0;

    // Calculate distance from the edge - using a rounded rectangle shape
    float distFromEdgeX = 1.0 - abs(centered.x);
    float distFromEdgeY = 1.0 - abs(centered.y);
    float distFromEdge = min(distFromEdgeX, distFromEdgeY);

    // Create a smoother edge with an exponent
    float edgeFactor = pow(1.0 - smoothstep(0.0, uIntensity * 0.5 * (1.0 + uVoiceAmplitude), distFromEdge), 2.0);

    // Create a breathing effect modulated by voice amplitude
    float breathingEffect = pulse(uTime * uFrequency, 0.3) + 0.7;
    // Increase the breathing effect based on voice amplitude
    breathingEffect *= (1.0 + uVoiceAmplitude * 1.5);
    edgeFactor *= breathingEffect;

    // Add enhanced wave effects along the edge - made more intense with voice amplitude
    float waveSpeed = 2.0 + uVoiceAmplitude * 4.0; // Wave speed increases with voice
    float waveFreq = 15.0 + uVoiceAmplitude * 20.0; // Wave frequency increases with voice
    float waveAmp = 0.05 + uVoiceAmplitude * 0.15; // Wave amplitude increases with voice

    float waveEffect = sin(uv.x * waveFreq + uTime * waveSpeed) * 
    sin(uv.y * waveFreq + uTime * waveSpeed) * waveAmp;

    // Add additional reactive waves based on voice amplitude
    float voiceWaves = sin(uv.x * 30.0 + uTime * 3.0 + uVoiceAmplitude * 10.0) * 
    sin(uv.y * 30.0 + uTime * 3.0) * uVoiceAmplitude * 0.2;

    edgeFactor += waveEffect * edgeFactor + voiceWaves;

    // Mix the two colors based on time and voice amplitude for a reactive shifting effect
    float colorMix = sin(uTime * 0.5) * 0.5 + 0.5;
    // Shift the color mix based on voice amplitude
    colorMix = mix(colorMix, sin(uTime * 2.0) * 0.5 + 0.5, uVoiceAmplitude);
    vec4 mixedColor = mix(uPrimaryColor, uSecondaryColor, colorMix) * edgeFactor;

    // Apply a subtle vignette effect
    float vignette = 1.0 - dot(centered, centered) * (0.3 - uVoiceAmplitude * 0.1);

    // Enhance colors based on voice amplitude
    vec4 bgColor = mix(uPrimaryColor, uSecondaryColor, uv.y) * (0.1 + uVoiceAmplitude * 0.1);

    // Combine everything
    FragColor = mixedColor + bgColor * vignette;

    // Ensure we respect transparency
    FragColor.a = min(FragColor.a, 1.0);
}
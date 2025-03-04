#version 460 core

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;           // Canvas size
uniform vec4 uPrimaryColor;   // Primary glow color
uniform vec4 uSecondaryColor; // Secondary glow color
uniform float uTime;          // For animation
uniform float uIntensity;     // Edge intensity
uniform float uFrequency;     // Breathing frequency

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
    float edgeFactor = pow(1.0 - smoothstep(0.0, uIntensity * 0.5, distFromEdge), 2.0);

    // Create a breathing effect
    float breathingEffect = pulse(uTime * uFrequency, 0.3) + 0.7;
    edgeFactor *= breathingEffect;

    // Add a wave effect along the edge
    float waveEffect = sin(uv.x * 20.0 + uTime * 2.0) * sin(uv.y * 20.0 + uTime * 2.0) * 0.05;
    edgeFactor += waveEffect * edgeFactor;

    // Mix the two colors based on time for a subtle shifting effect
    float colorMix = sin(uTime * 0.5) * 0.5 + 0.5;
    vec4 mixedColor = mix(uPrimaryColor, uSecondaryColor, colorMix) * edgeFactor;

    // Add a subtle gradient background with very low opacity
    vec4 bgColor = mix(uPrimaryColor, uSecondaryColor, uv.y) * 0.1;

    // Apply a subtle vignette effect
    float vignette = 1.0 - dot(centered, centered) * 0.3;

    // Combine everything
    FragColor = mixedColor + bgColor * vignette;

    // Ensure we respect transparency
    FragColor.a = min(FragColor.a, 1.0);
}
#version 460 core

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;      // Canvas size
uniform vec4 uColor;     // Glow color
uniform float uTime;     // For animation
uniform float uWidth;    // Glow width

out vec4 FragColor;

void main() {
    // Get normalized coordinates (0.0 to 1.0)
    vec2 uv = FlutterFragCoord() / uSize;

    // Calculate distance from the edge
    float distFromEdgeX = min(uv.x, 1.0 - uv.x);
    float distFromEdgeY = min(uv.y, 1.0 - uv.y);
    float distFromEdge = min(distFromEdgeX, distFromEdgeY);

    // Create the glow effect
    float glowIntensity = smoothstep(0.0, uWidth, distFromEdge);
    glowIntensity = 1.0 - glowIntensity;

    // Add pulsating effect
    float pulse = 0.5 * sin(uTime * 2.0) + 0.5;
    glowIntensity *= (0.75 + 0.25 * pulse);

    // Apply color with glow intensity
    vec4 glowColor = uColor * glowIntensity;

    // Apply the color to the output
    FragColor = glowColor;
}
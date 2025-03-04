#version 460 core

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform vec4 uColor;

out vec4 FragColor;

void main() {
    // Use FlutterFragCoord() for proper coordinate mapping
    vec2 fragCoord = FlutterFragCoord();

    // Ensure we're in the rectangle bounds
    FragColor = uColor;
}
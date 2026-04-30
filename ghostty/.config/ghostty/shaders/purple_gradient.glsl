#define OPACITY 0.30

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec4 terminal = texture(iChannel0, uv);

    float t = iTime * 0.12;

    vec2 p = uv;
    p.x += 0.10 * sin(t * 2.0 + uv.y * 5.0);
    p.y += 0.08 * cos(t * 1.6 + uv.x * 4.0);

    float g1 = smoothstep(0.15, 0.95, sin((p.x + p.y + t) * 3.2) * 0.5 + 0.5);
    float g2 = smoothstep(0.05, 0.85, sin((p.x * 2.8 - p.y * 1.7 - t * 1.4) * 2.4) * 0.5 + 0.5);
    float haze = mix(g1, g2, 0.45);

    vec3 purpleA = vec3(0.32, 0.18, 0.95);
    vec3 purpleB = vec3(0.93, 0.38, 0.92);
    vec3 purpleC = vec3(0.10, 0.07, 0.28);

    vec3 gradient = mix(purpleA, purpleB, haze);
    gradient = mix(gradient, purpleC, smoothstep(0.45, 1.0, uv.y + 0.15 * sin(t + uv.x * 6.0)));

    float bgLum = dot(iBackgroundColor, vec3(0.299, 0.587, 0.114));
    float baseAlpha = mix(0.18, 0.32, 1.0 - bgLum);
    // Tweak this value to adjust the intensity of the gradient effect
    float alpha = baseAlpha * OPACITY;

    float bgDistance = distance(terminal.rgb, iBackgroundColor);
    float bgMask = 1.0 - smoothstep(0.01, 0.06, bgDistance);
    vec3 color = mix(terminal.rgb, mix(iBackgroundColor, gradient, alpha), bgMask);

    fragColor = vec4(color, terminal.a);
}

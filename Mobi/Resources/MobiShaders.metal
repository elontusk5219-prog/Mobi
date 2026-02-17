//
//  MobiShaders.metal
//  Mobi
//
//  Soul Distillation: liquid threshold (ink-in-milk) and vortex collapse.
//  iOS 17+ SwiftUI ShaderLibrary; use #include <SwiftUI/SwiftUI_Metal.h> for Layer.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>

using namespace metal;

// MARK: - Layer effect: alpha threshold (liquid / mercury look)

[[stitchable]] half4 thresholdLayer(float2 position, SwiftUI::Layer layer) {
    half4 color = layer.sample(position);
    color.a = smoothstep(half(0.4), half(0.5), color.a);
    return color;
}

// MARK: - Distortion effect: zoom warp (hyperspace radial burst — pull from center outward)

[[stitchable]] float2 zoomWarp(float2 position, float2 center, float strength) {
    float2 direction = position - center;
    float dist = length(direction);
    float2 offset = direction * (strength * dist * 0.01);
    return position - offset;
}

// MARK: - Distortion effect: organic blob (floating bubble — irregular soft edge)

static float hash2(float2 p) {
    return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}

static float noise2d(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash2(i);
    float b = hash2(i + float2(1, 0));
    float c = hash2(i + float2(0, 1));
    float d = hash2(i + float2(1, 1));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// 泡泡式变形：径向膨缩 + 正弦基波（流畅）+ 噪声调制（有机）
// 需要 center、tts 参数，改用新 signature
static float fbmSmooth(float2 p, float time) {
    float t = fmod(time, 200.0);
    float v = 0.0;
    v += 0.5  * noise2d(p);
    v += 0.25 * noise2d(p * 2.0 + float2(t * 0.4, t * 0.3));  // 慢速漂移
    v += 0.125 * noise2d(p * 4.0 + float2(t * 0.2, -t * 0.25));
    return v;
}

[[stitchable]] float2 organicBlobDistortion(float2 position, float time, float intensity) {
    if (intensity <= 0.001) { return position; }
    float scale = 0.006;
    float2 p = position * scale;
    float n = fbmSmooth(p, time);
    float angle = (n - 0.5) * 6.28318;
    float amp = intensity * 18.0;
    float2 offset = float2(cos(angle), sin(angle)) * amp;
    return position + offset;
}

// 泡泡径向变形：中心向外推/拉，正弦+噪声，流畅且 TTS 可驱动
[[stitchable]] float2 organicBlobRadial(
    float2 position,
    float time,
    float intensity,
    float2 center,
    float tts
) {
    if (intensity <= 0.001) { return position; }
    float2 d = position - center;
    float dist = length(d);
    if (dist < 1.0) { return position; }
    float2 dir = d / dist;
    float t = fmod(time, 200.0);
    // 正弦基波：多频率叠加，产生流畅的「呼吸」感
    float base = sin(t * 0.6) * 0.5
        + sin(t * 0.35 + 1.0) * 0.35
        + sin(t * 0.9 + 2.3) * 0.25;
    // 噪声调制：随角度+时间变化，有机感
    float2 p = float2(atan2(d.y, d.x) * 0.5, dist * 0.008);
    float n = fbmSmooth(p, t);
    float noiseMod = (n - 0.5) * 2.0;
    // TTS：说话时振幅增大、叠加更快节奏
    float ttsBoost = 1.0 + tts * 1.2;
    float ttsPulse = sin(t * 4.0) * tts * 0.4;
    float displacement = (base + noiseMod + ttsPulse) * intensity * 22.0 * ttsBoost;
    return position + dir * displacement;
}

// MARK: - Distortion effect: vibe tremor (subtle jitter from vibe_keywords in METADATA)

[[stitchable]] float2 vibeTremorDistortion(float2 position, float time, float intensity) {
    if (intensity <= 0.001) { return position; }
    float freq = 8.0 + sin(time * 2.0) * 3.0;
    float amp = intensity * 3.0;
    float2 offset = float2(sin(position.x * 0.02 + time * freq) * amp, cos(position.y * 0.02 + time * freq * 1.3) * amp);
    return position + offset;
}

// MARK: - Distortion effect: vortex / twirl (collapse to center)

[[stitchable]] float2 vortexDistortion(float2 position, float strength, float2 center) {
    float2 d = position - center;
    float dist = length(d);
    float angle = atan2(d.y, d.x);
    angle += strength / max(dist, 0.001);
    return center + float2(cos(angle), sin(angle)) * dist;
}

// MARK: - Ethereal orb: organic edge (noise-modulated SDF), bioluminescent mask

static float hash(float3 p) {
    return fract(sin(dot(p, float3(127.1, 311.7, 74.7))) * 43758.5453);
}

static float noise3d(float3 p) {
    float3 i = floor(p);
    float3 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float n = mix(
        mix(mix(hash(i), hash(i + float3(1, 0, 0)), f.x),
            mix(hash(i + float3(0, 1, 0)), hash(i + float3(1, 1, 0)), f.x), f.y),
        mix(mix(hash(i + float3(0, 0, 1)), hash(i + float3(1, 0, 1)), f.x),
            mix(hash(i + float3(0, 1, 1)), hash(i + float3(1, 1, 1)), f.x), f.y),
        f.z
    );
    return n;
}

// MARK: - Layer effect: noise grain (P4 / overexposed film look for Cosmic Adult)

static float grainHash(float2 p) {
    return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}

[[stitchable]] half4 noiseGrain(float2 position, SwiftUI::Layer layer, float time) {
    half4 c = layer.sample(position);
    float n = grainHash(position * 0.02 + float2(time * 10.0, 0));
    half grain = half((n - 0.5) * 0.06);  // ~5% 胶片质感，避免塑料感
    c.rgb += grain;
    return c;
}

// MARK: - Layer effect: RGB split / glitch (unstable signal, Phantom Hover)

static float glitchHash(float t) {
    return fract(sin(t * 127.1) * 43758.5453);
}

[[stitchable]] half4 rgbSplitGlitch(float2 position, SwiftUI::Layer layer, float time) {
    float o = glitchHash(time * 20.0) * 4.0 - 2.0;
    half4 r = layer.sample(position + float2(o, 0));
    half4 g = layer.sample(position);
    half4 b = layer.sample(position - float2(o, 0));
    return half4(r.r, g.g, b.b, g.a);
}

// MARK: - Layer effect: infinite zoom (pull toward center for Infinite Dive)

[[stitchable]] half4 infiniteZoomLayer(float2 position, SwiftUI::Layer layer, float zoomOffset, float tension, float sizeW, float sizeH) {
    float2 size = float2(sizeW, sizeH);
    float2 center = size * 0.5;
    float2 uv = position - center;
    float zoomFactor = (zoomOffset / 10.0) * 0.99 * (1.0 + tension * 0.5);
    float scale = 1.0 - zoomFactor;
    scale = max(scale, 0.01);
    float2 samplePos = center + uv * scale;
    return layer.sample(samplePos);
}

// MARK: - Ethereal orb: organic edge (noise-modulated SDF), bioluminescent mask

// 球体-光晕边界：不规则模糊（不同位置 softWidth 不同），预留径向变形空间
[[stitchable]] half4 sphereVariableEdgeSoft(float2 position, SwiftUI::Layer layer, float time, float2 center, float2 size) {
    float dist = length(position - center);
    float baseRadius = 135.0;  // 容纳径向膨缩
    float noiseScale = 0.012;
    float3 noisePos = float3((position - center) * noiseScale, time * 0.2);
    float n1 = noise3d(noisePos);
    float n2 = noise3d(noisePos + float3(7.3, 13.1, 2.7));
    // 边界位置：噪声调制，产生不规则轮廓，幅度够大以容纳泡泡变形
    float threshold = baseRadius + 35.0 * (n1 - 0.5);
    // 模糊强度：不同位置不同 softWidth（15~55），实现不规则模糊
    float softWidth = 15.0 + 40.0 * n2;
    float alpha = 1.0 - smoothstep(threshold - softWidth, threshold + softWidth, dist);
    half4 c = layer.sample(position);
    c.a *= half(alpha);
    return c;
}

[[stitchable]] half4 etherealOrbOrganic(float2 position, SwiftUI::Layer layer, float time, float2 center, float2 size, float audio) {
    float dist = length(position - center);
    float baseRadius = 0.45 * min(size.x, size.y);
    float noiseScale = 0.008;
    float3 noisePos = float3((position - center) * noiseScale, time * 0.15);
    float n = noise3d(noisePos);
    float amplitude = 0.12 * min(size.x, size.y);
    float audioMod = 0.03 * min(size.x, size.y) * audio;
    float threshold = baseRadius + amplitude * (n - 0.5) + audioMod;
    float softWidth = 25.0;
    float alpha = 1.0 - smoothstep(threshold - softWidth, threshold + softWidth, dist);
    half4 c = layer.sample(position);
    c.a *= half(alpha);
    return c;
}

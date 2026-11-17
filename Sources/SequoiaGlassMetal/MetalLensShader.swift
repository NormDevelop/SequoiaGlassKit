/// Original, runtime-compiled Metal shader. Works with SwiftPM + Command Line Tools;
/// does NOT call or imitate Apple's proprietary Liquid Glass material API.
/// Input pixels belong to the host application. No desktop or cross-app access.
enum MetalLensShader {
    static let source = #"""
#include <metal_stdlib>
using namespace metal;

struct VertexOut { float4 position [[position]]; float2 uv; };
// Must match LensUniforms in OpticalRefractionView.swift field-for-field.
struct LensUniforms {
    float2 viewport;
    float2 mouse;
    float strength;
    float thickness;
    float rim;
    float softness;
    float bandWidth;
    float pixelScale;
    uint debugMode;
    uint isHovering;
    uint layoutMode;
    float dispersion;
    float tintOpacity;
    uint quality;
    uint renderMode;
    float2 cropOrigin;
    float2 cropExtent;
    uint flipSourceV;
    float2 customCenter;
    float2 customHalfExtent;
    float customRadius;
    uint customLensEnabled;
};

vertex VertexOut fullscreenVertex(uint vertexID [[vertex_id]]) {
    float2 p = float2(float((vertexID << 1) & 2), float(vertexID & 2));
    VertexOut out;
    out.position = float4(p * 2.0 - 1.0, 0.0, 1.0);
    out.uv = float2(p.x, 1.0 - p.y);
    return out;
}

float roundedBoxSDF(float2 p, float2 center, float2 halfExtent, float radius) {
    float2 q = abs(p - center) - (halfExtent - float2(radius));
    return length(max(q, float2(0.0))) + min(max(q.x, q.y), 0.0) - radius;
}

float2 safeNormal(float2 p, float2 c, float2 h, float radius) {
    float dx = roundedBoxSDF(p + float2(0.5,0), c, h, radius)
             - roundedBoxSDF(p - float2(0.5,0), c, h, radius);
    float dy = roundedBoxSDF(p + float2(0,0.5), c, h, radius)
             - roundedBoxSDF(p - float2(0,0.5), c, h, radius);
    float2 g = float2(dx,dy);
    return g * rsqrt(max(dot(g,g), 1e-8));
}

float windowWeight(float depth, float band) {
    float t = clamp(depth / max(band, 0.001), 0.0, 1.0);
    float w = sin(3.14159265359 * t);
    return w*w;  // C1 continuous at both boundaries
}

// Aspect-fill: no stretching when users import portrait or landscape photos.
float2 coverUV(float2 uv, float2 viewport, float2 textureSize) {
    float viewAspect = viewport.x / max(viewport.y, 1.0);
    float texAspect = textureSize.x / max(textureSize.y, 1.0);
    if (viewAspect > texAspect) {
        uv.y = 0.5 + (uv.y-0.5) * texAspect / viewAspect;
    } else {
        uv.x = 0.5 + (uv.x-0.5) * viewAspect / texAspect;
    }
    return clamp(uv, float2(0.0), float2(1.0));
}

// App-owned live content is a crop, not the entire view. Reconstruct its source
// coordinates in the shader instead of stretching the crop across the window.
float2 sampleUV(float2 viewUV, constant LensUniforms& u, float2 imageSize) {
    if (u.renderMode == 1) {
        float2 cropUV = (viewUV-u.cropOrigin)/max(u.cropExtent, float2(0.000001));
        if (u.flipSourceV != 0) cropUV.y = 1.0-cropUV.y;
        return clamp(cropUV, float2(0.0), float2(1.0));
    }
    return coverUV(viewUV, u.viewport, imageSize);
}

fragment float4 opticalFragment(VertexOut input [[stage_in]],
    texture2d<float> source [[texture(0)]],
    constant LensUniforms& u [[buffer(0)]]) {
    constexpr sampler s(address::clamp_to_edge, min_filter::linear, mag_filter::linear);
    float2 uv = clamp(input.uv, float2(0), float2(1));
    float2 p = uv*u.viewport;
    bool single = u.layoutMode != 0;
    float2 h = single
      ? float2(min(u.viewport.x*0.34, 335.0*u.pixelScale), min(u.viewport.y*0.24, 146.0*u.pixelScale))*u.thickness
      : float2(min(u.viewport.x*0.169, 290.0*u.pixelScale), min(u.viewport.y*0.136, 110.0*u.pixelScale))*u.thickness;
    float r = min(h.y*0.80, (single ? 74.0 : 56.0)*u.pixelScale*u.thickness);
    float2 left = float2(u.viewport.x*0.25, u.viewport.y*0.52);
    float2 right = float2(u.viewport.x*0.75, u.viewport.y*0.52);
    float2 center = single ? float2(u.viewport.x*0.5, u.viewport.y*0.52) : left;
    if (single && u.customLensEnabled != 0) {
        center = u.customCenter;
        h = max(u.customHalfExtent, float2(1.0));
        r = clamp(u.customRadius, 1.0, min(h.x,h.y));
    }
    bool enhanced = single;
    if (!single) {
        float dl = roundedBoxSDF(p, left, h, r);
        float dr = roundedBoxSDF(p, right, h, r);
        enhanced = dr < dl;
        center = enhanced ? right : left;
    }
    float d = roundedBoxSDF(p, center, h, r);
    // In an overlay most screen pixels are OUTSIDE the capsule. Return before
    // any source-texture sampling or normal/reflection calculation.
    if (u.renderMode == 1 && d > 1.3*u.pixelScale) return float4(0.0);
    float2 srcUV = sampleUV(uv, u, float2(source.get_width(), source.get_height()));
    float3 original = source.sample(s, srcUV).rgb;
    if (d > 12.0*u.pixelScale) return float4(original, 1.0);

    float2 normal = safeNormal(p, center, h, r);
    float band = min(max(u.bandWidth*u.pixelScale, 0.001), h.y*0.86);
    float amount = min(max(u.strength, 0.0), 0.55*band/3.14159265359)
                 * windowWeight(max(0.0, -d), band);
    float2 offset = enhanced && d < 0.0 ? normal*amount : float2(0.0);
    // Convert from output pixels to source UV, accounting for aspect-fill transform.
    float2 shifted = sampleUV(uv - offset/u.viewport, u,
                              float2(source.get_width(), source.get_height()));
    // A second texture read is only needed inside the optical displacement band.
    float3 refracted = (enhanced && amount > 0.0005)
        ? source.sample(s, shifted).rgb : original;
    if (d < 0.0 && enhanced && u.quality == 2 && u.dispersion > 0.001) {
        // Very small chromatic separation only in the optical band, never at boundary.
        float2 delta = normal * (u.dispersion*u.pixelScale/max(u.viewport.x, 1.0))
                     * windowWeight(max(0.0, -d), band);
        float2 deltaY = normal * (u.dispersion*u.pixelScale/max(u.viewport.y, 1.0))
                      * windowWeight(max(0.0, -d), band);
        float2 roiFactor = u.renderMode == 1 ? float2(1.0)/max(u.cropExtent,float2(0.000001)) : float2(1.0);
        float2 colorStep = float2(delta.x, deltaY.y)*roiFactor;
        if (u.renderMode == 1 && u.flipSourceV != 0) colorStep.y = -colorStep.y;
        float2 a = clamp(shifted + colorStep, float2(0), float2(1));
        float2 b = clamp(shifted - colorStep, float2(0), float2(1));
        refracted.r = source.sample(s, a).r;
        refracted.b = source.sample(s, b).b;
    }
    if (d < 0 && u.softness > 0.005 && u.quality > 0) {
        float2 step = float2(1.2*u.pixelScale)/max(u.viewport, float2(1.0));
        if (u.renderMode == 1) step /= max(u.cropExtent, float2(0.000001));
        float3 neighbors = source.sample(s, shifted+float2(step.x,0)).rgb
                         + source.sample(s, shifted-float2(step.x,0)).rgb
                         + source.sample(s, shifted+float2(0,step.y)).rgb
                         + source.sample(s, shifted-float2(0,step.y)).rgb;
        refracted = mix(refracted, neighbors*0.25, u.softness*0.18);
    }

    // v1.7 optics: distinct neutral substrate, inner caustic, and directional
    // Fresnel-like rim. Apple Liquid Glass uses a proprietary dynamic material;
    // this is an independently authored, tunable visual approximation.
    float interior = 1.0 - smoothstep(-1.25*u.pixelScale, 1.35*u.pixelScale, d);
    float outerCaustic = exp(-pow(d / max(1.45*u.pixelScale, 0.1), 2.0));
    float innerCaustic = exp(-pow((d + 6.0*u.pixelScale) /
                                   max(4.25*u.pixelScale, 0.1), 2.0));
    float innerScatter = exp(-pow((d + 15.0*u.pixelScale) /
                                   max(10.5*u.pixelScale, 0.1), 2.0));
    float incomingLight = max(dot(normal, normalize(float2(-0.42, -0.91))), 0.0);
    float upper = max(-normal.y, 0.0);
    float side = abs(normal.x);
    float lower = max(normal.y, 0.0);
    float fresnel = 0.34 + 0.66*pow(incomingLight, 1.65);

    float3 composed = refracted;
    // Environment-adaptive, low-opacity neutralisation. Unlike a fixed white
    // wash, it works on dark as well as warm/saturated backgrounds, and does
    // not replace the source pixels with a solid 'beige glass' fill.
    float luminance = dot(refracted, float3(0.2126, 0.7152, 0.0722));
    float backgroundLight = smoothstep(0.22, 0.75, luminance);
    float3 neutralTarget = mix(float3(0.105, 0.13, 0.17),
                               float3(0.965, 0.98, 0.995), backgroundLight);
    float neutralisation = (0.015 + 0.030*backgroundLight
                           + 0.55*clamp(u.tintOpacity, 0.0, 0.04))*interior;
    composed = mix(composed, neutralTarget, neutralisation);
    // Quiet resting state; bright *directional* highlights only where the
    // glass surface changes curvature. No large diffuse rectangular shadow.
    // Grazing-direction rim with a narrow silver line and asymmetric internal
    // caustic. The highlight is restricted to the lens curvature, NOT a filled
    // color overlay. Quality modes share this single rendering pass.
    float specularStrength = u.rim *
        (outerCaustic * (0.050 + 0.30*fresnel + 0.055*upper)
         + innerCaustic * (0.014 + 0.083*incomingLight)
         + innerScatter * 0.006*upper);
    float3 coolSpecular = float3(0.91, 0.965, 1.0);
    composed = composed + coolSpecular * specularStrength;
    composed *= 1.0 - u.rim*lower*innerCaustic*0.040;
    if (enhanced && u.isHovering != 0 && d < 0.0) {
        float2 relative = (p-u.mouse)/(float2(170.0,105.0)*u.pixelScale);
        float glow = exp(-3.4*dot(relative,relative))*0.027*u.rim;
        composed += float3(0.94, 0.97, 1.0)*glow;
    }
    // Debug modes show only the enhanced element. Baseline remains undistorted.
    if (enhanced && d < 0 && u.debugMode == 1) {
        float t = clamp(length(offset)/max(u.strength,0.001),0.0,1.0);
        composed = mix(float3(0.06,0.22,0.43), float3(1.0,0.55,0.14), t);
    } else if (enhanced && d < 0 && u.debugMode == 2) {
        composed = clamp(abs(refracted-original)*4.0, float3(0),float3(1));
    }
    float3 output = clamp(mix(original,composed,interior),float3(0),float3(1));
    if (u.renderMode == 1) {
        // Source view is visible underneath: only paint the glass capsule.
        // Premultiplied color at the subpixel edge avoids dark halos.
        float alpha = enhanced ? 1.0 - smoothstep(-1.2*u.pixelScale,
                                                   0.8*u.pixelScale, d) : 0.0;
        return float4(output * alpha, alpha);
    }
    return float4(output, 1.0);
}
"""#
}

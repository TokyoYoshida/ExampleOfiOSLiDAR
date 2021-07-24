#include <metal_stdlib>
#include <simd/simd.h>
#import "PointCloudShaderTypes.h"

using namespace metal;

struct RGBVertexOut {
    float4 position [[position]];
    float2 texCoord;
};

struct ParticleVertexOut {
    float4 position [[position]];
    float pointSize [[point_size]];
    float4 color;
};

float3 rotate(float3 p, float angle, float3 axis){
    float3 a = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float r = 1.0 - c;
    float3x3 m = float3x3(
        a.x * a.x * r + c,
        a.y * a.x * r + a.z * s,
        a.z * a.x * r - a.y * s,
        a.x * a.y * r - a.z * s,
        a.y * a.y * r + c,
        a.z * a.y * r + a.x * s,
        a.x * a.z * r + a.y * s,
        a.y * a.z * r - a.x * s,
        a.z * a.z * r + c
    );
    return m * p;
}

constexpr sampler colorSampler(mip_filter::linear, mag_filter::linear, min_filter::linear);
constant auto yCbCrToRGB = float4x4(float4(+1.0000f, +1.0000f, +1.0000f, +0.0000f),
                                    float4(+0.0000f, -0.3441f, +1.7720f, +0.0000f),
                                    float4(+1.4020f, -0.7141f, +0.0000f, +0.0000f),
                                    float4(-0.7010f, +0.5291f, -0.8860f, +1.0000f));
constant float2 viewVertices[] = { float2(-1, 1), float2(-1, -1), float2(1, 1), float2(1, -1) };
constant float2 viewTexCoords[] = { float2(0, 0), float2(0, 1), float2(1, 0), float2(1, 1) };

static simd_float4 worldPoint(simd_float2 cameraPoint, float depth, matrix_float3x3 cameraIntrinsicsInversed, matrix_float4x4 localToWorld, simd_float3 modelPosition, matrix_float4x4 modelTransform) {
    auto localPoint = cameraIntrinsicsInversed * simd_float3(cameraPoint, 1) * depth;
    localPoint = (simd_float4(localPoint + float3(0, 0, -0.5), 1) * modelTransform).xyz + float3(0, 0, 1.5);
    auto worldPoint = localToWorld * simd_float4(localPoint, 1);
//    worldPoint.y -= 0.5;

    return worldPoint / worldPoint.w;
}

vertex ParticleVertexOut unprojectVertex(uint vertexID [[vertex_id]],
                            constant PointCloudUniforms &uniforms [[buffer(0)]],
                            constant float2 *gridPoints [[buffer(1)]],
                            texture2d<float, access::sample> capturedImageTextureY [[texture(0)]],
                            texture2d<float, access::sample> capturedImageTextureCbCr [[texture(1)]],
                            texture2d<float, access::sample> depthTexture [[texture(2)]],
                            texture2d<unsigned int, access::sample> confidenceTexture [[texture(3)]]) {
    const auto gridPoint = gridPoints[vertexID];
    const auto texCoord = gridPoint / uniforms.cameraResolution;
    const auto depth = depthTexture.sample(colorSampler, texCoord).r;
    const auto position = worldPoint(gridPoint, depth, uniforms.cameraIntrinsicsInversed, uniforms.localToWorld, uniforms.modelPosition, uniforms.modelTransform);
    
    const auto ycbcr = float4(capturedImageTextureY.sample(colorSampler, texCoord).r, capturedImageTextureCbCr.sample(colorSampler, texCoord.xy).rg, 1);
    const auto sampledColor = (yCbCrToRGB * ycbcr).rgb;
    float confidence = confidenceTexture.sample(colorSampler, texCoord).r;
    
    const auto visibility = confidence >= uniforms.confidenceThreshold;

    float4 projectedPosition = uniforms.viewProjectionMatrix * float4(position.xyz, 1.0);
    const float pointSize = max(uniforms.particleSize / max(1.0, projectedPosition.z), 2.0);
    projectedPosition /= projectedPosition.w;

    ParticleVertexOut out;

    out.position = projectedPosition;
    out.color = float4(sampledColor, visibility);
    out.pointSize = pointSize;
    
    return out;
}

vertex RGBVertexOut rgbVertex(uint vertexID [[vertex_id]],
                              constant RGBUniforms &uniforms [[buffer(0)]]) {
    const float3 texCoord = float3(viewTexCoords[vertexID], 1) * uniforms.viewToCamera;
    
    RGBVertexOut out;
    out.position = float4(viewVertices[vertexID], 0, 1);
    out.texCoord = texCoord.xy;
    
    return out;
}

fragment float4 rgbFragment(RGBVertexOut in [[stage_in]],
                            constant RGBUniforms &uniforms [[buffer(0)]],
                            texture2d<float, access::sample> capturedImageTextureY [[texture(kTextureY)]],
                            texture2d<float, access::sample> capturedImageTextureCbCr [[texture(kTextureCbCr)]]) {
    
    const float2 offset = (in.texCoord - 0.5) * float2(1, 1 / uniforms.viewRatio) * 2;
    const float visibility = saturate(uniforms.radius * uniforms.radius - length_squared(offset));
    const float4 ycbcr = float4(capturedImageTextureY.sample(colorSampler, in.texCoord.xy).r, capturedImageTextureCbCr.sample(colorSampler, in.texCoord.xy).rg, 1);
    
    // convert and save the color back to the buffer
    const float3 sampledColor = (yCbCrToRGB * ycbcr).rgb;
    return float4(sampledColor, 1) * visibility;
}

vertex ParticleVertexOut particleVertex(uint vertexID [[vertex_id]],
                                        constant PointCloudUniforms &uniforms [[buffer(kPointCloudUniforms)]],
                                        constant ParticleUniforms *particleUniforms [[buffer(kParticleUniforms)]]) {
    
    const auto particleData = particleUniforms[vertexID];
    const auto position = particleData.position;
    const auto confidence = particleData.confidence;
    const auto sampledColor = particleData.color;
    const auto visibility = confidence >= uniforms.confidenceThreshold;
    
    float4 projectedPosition = uniforms.viewProjectionMatrix * float4(position, 1.0);
    const float pointSize = max(uniforms.particleSize / max(1.0, projectedPosition.z), 2.0);
    projectedPosition /= projectedPosition.w;
    
    ParticleVertexOut out;
    out.position = projectedPosition;
    out.pointSize = pointSize;
    out.color = float4(sampledColor, visibility);
    
    return out;
}

fragment float4 particleFragment(ParticleVertexOut in [[stage_in]],
                                 const float2 coords [[point_coord]]) {
    const float distSquared = length_squared(coords - float2(0.5));
    if (in.color.a == 0 || distSquared > 0.25) {
        discard_fragment();
    }
    
    return in.color;
}

fragment float4 simpleFragmentShader(ParticleVertexOut in [[ stage_in ]],
                                      const float2 coords [[point_coord]]) {
    const float distSquared = length_squared(coords - float2(0.5));
    if (in.color.a == 0 || distSquared > 0.25) {
        discard_fragment();
    }
    
    return in.color;
}

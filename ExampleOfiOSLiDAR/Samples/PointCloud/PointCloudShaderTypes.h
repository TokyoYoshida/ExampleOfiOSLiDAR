#ifndef ShaderTypes_h
#define ShaderTypes_h

#include <simd/simd.h>

struct PointCloudUniforms {
    matrix_float4x4 viewProjectionMatrix;
    matrix_float4x4 localToWorld;
    matrix_float3x3 cameraIntrinsicsInversed;
    simd_float2 cameraResolution;
    
    float particleSize;
    int maxPoints;
    int pointCloudCurrentIndex;
    int confidenceThreshold;
    
    simd_float3 modelPosition;
    matrix_float4x4 modelTransform;
};

#endif /* ShaderTypes_h */

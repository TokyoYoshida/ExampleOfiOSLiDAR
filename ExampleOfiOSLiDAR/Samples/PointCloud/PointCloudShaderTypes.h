/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Types and enums that are shared between shaders and the host app code.
*/

#ifndef ShaderTypes_h
#define ShaderTypes_h

#include <simd/simd.h>

enum TextureIndices {
    kTextureY = 0,
    kTextureCbCr = 1,
    kTextureDepth = 2,
    kTextureConfidence = 3
};

enum BufferIndices {
    kPointCloudUniforms = 0,
    kParticleUniforms = 1,
    kGridPoints = 2,
};

struct RGBUniforms {
    matrix_float3x3 viewToCamera;
    float viewRatio;
    float radius;
};

// 🤓パーティクルの基礎情報
struct PointCloudUniforms {
    matrix_float4x4 viewProjectionMatrix; // 🤓view projctionのマトリクス
    matrix_float4x4 localToWorld; // 🤓ローカル座標系
    matrix_float3x3 cameraIntrinsicsInversed; // 🤓カメラの逆転
    simd_float2 cameraResolution; // 🤓カメラの解像度
    
    float particleSize; // 🤓パーティクルの大きさ
    int maxPoints; // 🤓点の最大数
    int pointCloudCurrentIndex; // 🤓現在のインデックスう
    int confidenceThreshold; // 🤓信頼性のしきい値
    
    simd_float3 modelPosition;
    simd_float3 modelRotate;
};

// 🤓パーティクル１つ１つについての情報
struct ParticleUniforms {
    simd_float3 position; // 🤓パーティクルの位置
    simd_float3 color; // 🤓パーティクルの色
    float confidence; // 🤓パーティクルの信頼性
};

#endif /* ShaderTypes_h */

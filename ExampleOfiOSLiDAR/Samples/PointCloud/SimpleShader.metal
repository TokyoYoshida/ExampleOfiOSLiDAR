//
//  SimpleShader.metal
//  MetalExamples
//
//  Created by TokyoYoshida on 2021/06/05.
//

#include <metal_stdlib>
using namespace metal;

struct ColorInOut
{
    float4 position [[ position ]];
};

vertex ColorInOut simpleVertexShader(
        const device float4 *positions [[ buffer(0 )]],
        uint vid [[ vertex_id ]]
    ) {
    ColorInOut out;
    out.position = positions[vid];
    return out;
}

fragment float4 simpleFragmentShader(ColorInOut in [[ stage_in ]]) {
    return float4(1,0,0,1);
}

//
//  MDLMesh+Ext.swift
//  ExampleOfiOSLiDAR
//
//  Created by TokyoYoshida on 2021/02/11.
//

import ARKit
import MetalKit

extension MDLMesh {
    func vertices() -> [SIMD3<Float>]? {
        guard let layouts = vertexDescriptor.layouts.filter({($0 as! MDLVertexBufferLayout).stride != 0}) as? [MDLVertexBufferLayout],
              layouts.count == 1,
              let stride = layouts.first?.stride else {
            return nil
        }
        let base = vertexBuffers.first!.map().bytes
        let vertices = (0..<vertexCount).map {i in
            base.load(fromByteOffset: stride*i, as: SIMD3<Float>.self)
        }
        return vertices
    }
}

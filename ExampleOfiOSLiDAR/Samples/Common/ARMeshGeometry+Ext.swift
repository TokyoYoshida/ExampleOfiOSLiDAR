//
//  ARMeshGeometry+Ext.swift
//  ExampleOfiOSLiDAR
//
//  Created by TokyoYoshida on 2021/02/11.
//

import RealityKit
import ARKit
import MetalKit

extension ARMeshGeometry {
    func calcTextureCoordinates(mesh: MDLMesh, camera: ARCamera) -> vector_float2 {
        let vertices = mesh.vertices()
        let textureCoordinates = vertices.map { vertex -> SIMD3<Float> in
            let vertex4 = vector_float4(vertex.x, vertex.y, vertex.z, 1)
            let world_vertex4 = simd_mul(modelMatrix!, vertex4)
            let world_vector3 = simd_float3(x: world_vertex4.x, y: world_vertex4.y, z: world_vertex4.z)
            let pt = camera.projectPoint(world_vector3,
                orientation: .portrait,
                viewportSize: CGSize(
                    width: CGFloat(size.height),
                    height: CGFloat(size.width)))
            let v = 1.0 - Float(pt.x) / Float(size.height)
            let u = Float(pt.y) / Float(size.width)
            return vector_float2(u, v)
        }
    }
    // helps from StackOverflow:
    // https://stackoverflow.com/questions/61063571/arkit-3-5-how-to-export-obj-from-new-ipad-pro-with-lidar
    func toMDLMesh(device: MTLDevice, camera: ARCamera) -> MDLMesh {
        let allocator = MTKMeshBufferAllocator(device: device);

        let data = Data.init(bytes: vertices.buffer.contents(), count: vertices.stride * vertices.count);
        let vertexBuffer = allocator.newBuffer(with: data, type: .vertex);

        let indexData = Data.init(bytes: faces.buffer.contents(), count: faces.bytesPerIndex * faces.count * faces.indexCountPerPrimitive);
        let indexBuffer = allocator.newBuffer(with: indexData, type: .index);

        let submesh = MDLSubmesh(indexBuffer: indexBuffer,
                                 indexCount: faces.count * faces.indexCountPerPrimitive,
                                 indexType: .uInt32,
                                 geometryType: .triangles,
                                 material: nil);

        let vertexDescriptor = MDLVertexDescriptor();
        vertexDescriptor.attributes[0] = MDLVertexAttribute(name: MDLVertexAttributePosition,
                                                            format: .float3,
                                                            offset: 0,
                                                            bufferIndex: 0);
        vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: vertices.stride);

        let mesh = MDLMesh(vertexBuffer: vertexBuffer,
                       vertexCount: vertices.count,
                       descriptor: vertexDescriptor,
                       submeshes: [submesh])
        
        return mesh
    }
}

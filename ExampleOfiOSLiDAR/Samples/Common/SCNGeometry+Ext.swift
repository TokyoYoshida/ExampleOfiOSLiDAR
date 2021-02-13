//
//  SCNGeometry+Ext.swift
//  ExampleOfiOSLiDAR
//
//  Created by TokyoYoshida on 2021/02/13.
//

import SceneKit
import ARKit

extension SCNGeometry {
    convenience init(geometry: ARMeshGeometry) {
        func convertType(type: ARGeometryPrimitiveType) -> SCNGeometryPrimitiveType {
            switch type {
            case .line:
                return .line
            case .triangle:
                return .triangles
            @unknown default:
                fatalError("unknown type")
            }
            
        }
        let verticles = geometry.vertices
        let normals = geometry.normals
        let faces = geometry.faces
        let verticesSource = SCNGeometrySource(buffer: verticles.buffer, vertexFormat: verticles.format, semantic: .vertex, vertexCount: verticles.count, dataOffset: verticles.offset, dataStride: verticles.stride)
        let normalsSource = SCNGeometrySource(buffer: normals.buffer, vertexFormat: normals.format, semantic: .normal, vertexCount: normals.count, dataOffset: normals.offset, dataStride: normals.stride)
        let facesElement = SCNGeometryElement(buffer: faces.buffer, primitiveType: convertType(type: faces.primitiveType), primitiveCount: faces.count, bytesPerIndex: faces.bytesPerIndex)
        self.init(sources: [verticesSource, normalsSource], elements: [facesElement])
    }
}

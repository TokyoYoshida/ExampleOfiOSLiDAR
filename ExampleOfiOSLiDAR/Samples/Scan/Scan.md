## Color Scan

You can convert it to SCNGeometry using the ARMeshAnchor geometory property. 

```swift
extension SCNGeometry {
    convenience init(geometry: ARMeshGeometry, camera: ARCamera, modelMatrix: simd_float4x4, needTexture: Bool = false) {
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
        func calcTextureCoordinates(verticles: ARGeometrySource, camera: ARCamera, modelMatrix: simd_float4x4) ->  SCNGeometrySource? {
            func getVertex(at index: UInt32) -> SIMD3<Float> {
                    assert(verticles.format == MTLVertexFormat.float3, "Expected three floats (twelve bytes) per vertex.")
                    let vertexPointer = verticles.buffer.contents().advanced(by: verticles.offset + (verticles.stride * Int(index)))
                    let vertex = vertexPointer.assumingMemoryBound(to: SIMD3<Float>.self).pointee
                    return vertex
            }
            func buildCoordinates() -> [vector_float2]? {
                let size = camera.imageResolution
                let textureCoordinates = (0..<verticles.count).map { i -> vector_float2 in
                    let vertex = getVertex(at: UInt32(i))
                    let vertex4 = vector_float4(vertex.x, vertex.y, vertex.z, 1)
                    let world_vertex4 = simd_mul(modelMatrix, vertex4)
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
                return textureCoordinates
            }
            guard let texcoords = buildCoordinates() else {return nil}
            let result = SCNGeometrySource(textureCoordinates: texcoords)
            
            return result
        }
        let verticles = geometry.vertices
        let normals = geometry.normals
        let faces = geometry.faces
        let verticesSource = SCNGeometrySource(buffer: verticles.buffer, vertexFormat: verticles.format, semantic: .vertex, vertexCount: verticles.count, dataOffset: verticles.offset, dataStride: verticles.stride)
        let normalsSource = SCNGeometrySource(buffer: normals.buffer, vertexFormat: normals.format, semantic: .normal, vertexCount: normals.count, dataOffset: normals.offset, dataStride: normals.stride)
        let data = Data(bytes: faces.buffer.contents(), count: faces.buffer.length)
        let facesElement = SCNGeometryElement(data: data, primitiveType: convertType(type: faces.primitiveType), primitiveCount: faces.count, bytesPerIndex: faces.bytesPerIndex)
        var sources = [verticesSource, normalsSource]
        if needTexture {
            let textureCoordinates = calcTextureCoordinates(verticles: verticles, camera: camera, modelMatrix: modelMatrix)!
            sources.append(textureCoordinates)
        }
        self.init(sources: sources, elements: [facesElement])
    }
}
```

tanks to Stack Overflow answer: https://stackoverflow.com/questions/61538799/ipad-pro-lidar-export-geometry-texture

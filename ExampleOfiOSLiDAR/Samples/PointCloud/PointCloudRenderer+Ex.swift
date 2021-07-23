//
//  PointCloudRenderer+Ex.swift
//  ExampleOfiOSLiDAR
//
//  Created by TokyoYoshida on 2021/07/23.
//

import Metal
import MetalKit
import ARKit

extension PointCloudRenderer {
    class PointCloudBuider {
        private let numGridPoints = 500

        private let device: MTLDevice
        private lazy var library: MTLLibrary = device.makeDefaultLibrary()!
        private let mtkView: MTKView

        private let session: ARSession

        private var sampleFrame: ARFrame { session.currentFrame! }
        private lazy var cameraResolution = Float2(Float(sampleFrame.camera.imageResolution.width), Float(sampleFrame.camera.imageResolution.height))
        private var gridPointsBuffer: MTLBuffer!

        private var relaxedStencilState: MTLDepthStencilState!
        private lazy var unprojectPipelineState = makeUnprojectionPipelineState()!

        init(device: MTLDevice, session: ARSession, mtkView: MTKView) {
            func makeGridPoints() -> [Float2] {
                let gridArea = cameraResolution.x * cameraResolution.y
                let spacing = sqrt(gridArea / Float(numGridPoints))
                let deltaX = Int(round(cameraResolution.x / spacing))
                let deltaY = Int(round(cameraResolution.y / spacing))
                
                var points = [Float2]()
                for gridY in 0 ..< deltaY {
                    let alternatingOffsetX = Float(gridY % 2) * spacing / 2
                    for gridX in 0 ..< deltaX {
                        let cameraPoint = Float2(alternatingOffsetX + (Float(gridX) + 0.5) * spacing, (Float(gridY) + 0.5) * spacing)
                        
                        points.append(cameraPoint)
                    }
                }
                
                return points
            }
            func buildBuffer() {
                let array = makeGridPoints()
                guard let buffer = device.makeBuffer(bytes: array, length: MemoryLayout<Float2>.stride * array.count, options: .storageModeShared) else {
                    fatalError("Failed to create MTLBuffer")
                }
                gridPointsBuffer = buffer
            }
            func buildStencilState() {
                let relaxedStateDescriptor = MTLDepthStencilDescriptor()
                relaxedStencilState = device.makeDepthStencilState(descriptor: relaxedStateDescriptor)!
            }

            self.device = device
            self.session = session
            self.mtkView = mtkView

            buildBuffer()
            buildStencilState()
        }
        
        func makeUnprojectionPipelineState() -> MTLRenderPipelineState? {
            guard let vertexFunction = library.makeFunction(name: "unprojectVertex") else {
                    return nil
            }
            
            let descriptor = MTLRenderPipelineDescriptor()
            descriptor.vertexFunction = vertexFunction
            descriptor.isRasterizationEnabled = false
            descriptor.depthAttachmentPixelFormat = mtkView.depthStencilPixelFormat
            descriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
            
            return try? device.makeRenderPipelineState(descriptor: descriptor)
        }
        
        func update(commandBuffer: MTLCommandBuffer, renderEncoder: MTLRenderCommandEncoder, capturedImageTextureY: CVMetalTexture, capturedImageTextureCbCr: CVMetalTexture, depthTexture: CVMetalTexture, confidenceTexture: CVMetalTexture) {
            var retainingTextures = [capturedImageTextureY, capturedImageTextureCbCr, depthTexture, confidenceTexture]
            commandBuffer.addCompletedHandler { buffer in
                retainingTextures.removeAll()
            }
            
            renderEncoder.setDepthStencilState(relaxedStencilState)
            renderEncoder.setRenderPipelineState(unprojectPipelineState)
            renderEncoder.setVertexBuffer(gridPointsBuffer, offset: 0, index: 0)
            renderEncoder.setVertexTexture(CVMetalTextureGetTexture(capturedImageTextureY), index: 0)
            renderEncoder.setVertexTexture(CVMetalTextureGetTexture(capturedImageTextureCbCr), index: 1)
            renderEncoder.setVertexTexture(CVMetalTextureGetTexture(depthTexture), index: 2)
            renderEncoder.setVertexTexture(CVMetalTextureGetTexture(confidenceTexture), index: 3)
            renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: numGridPoints)
        }
    }
}

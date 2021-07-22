//
//  Renderer.swift
//  ARKitExamples
//
//  Created by TokyoYoshida on 2021/07/19.
//

import ARKit
import Metal
import MetalKit
import CoreImage

class PointCloudRenderer {
    private let device: MTLDevice
    private var renderPipeline: MTLRenderPipelineState!

    private var vertextBuffer: MTLBuffer!
    private let vertexData: [Float] = [
        -1, -1, 0, 1,
         1, -1, 0, 1,
        -1,  1, 0, 1,
         1,  1, 0, 1,
    ]

    init(device: MTLDevice) {
        func buildPipeline() {
            guard let library = device.makeDefaultLibrary() else {fatalError()}
            let descriptor = MTLRenderPipelineDescriptor()
            descriptor.vertexFunction = library.makeFunction(name: "simpleVertexShader")
            descriptor.fragmentFunction = library.makeFunction(name: "simpleFragmentShader")
            descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            renderPipeline = try! device.makeRenderPipelineState(descriptor: descriptor)
        }
        func buildBuffers() {
            let size = vertexData.count * MemoryLayout<Float>.size
            vertextBuffer = device.makeBuffer(bytes: vertexData, length: size)
        }

        self.device = device
        buildPipeline()
        buildBuffers()
    }
    
    func update(_ commandBuffer: MTLCommandBuffer, drawable: CAMetalDrawable) {
        
        let renderPassDescriptor: MTLRenderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture

        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!

        guard let renderPipeline = renderPipeline else {fatalError()}

        
        renderEncoder.setRenderPipelineState(renderPipeline)
        renderEncoder.setVertexBuffer(vertextBuffer, offset: 0, index: 0)
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)

        renderEncoder.endEncoding()
    }
}

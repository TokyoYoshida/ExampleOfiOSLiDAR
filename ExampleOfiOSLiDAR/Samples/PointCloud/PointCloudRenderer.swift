//
//  PointCloudRenderer+Ex.swift
//  ExampleOfiOSLiDAR
//
//  Created by TokyoYoshida on 2021/07/23.
//

import Metal
import MetalKit
import ARKit

class PointCloudRenderer {
    private let maxPoints = 500_000
    private let numGridPoints = 50_000
    private let particleSize: Float = 10
    private let maxBuffers = 1

    private let device: MTLDevice
    private lazy var library: MTLLibrary = device.makeDefaultLibrary()!
    private let mtkView: MTKView

    private let session: ARSession

    private var sampleFrame: ARFrame { session.currentFrame! }
    private lazy var cameraResolution = Float2(Float(sampleFrame.camera.imageResolution.width), Float(sampleFrame.camera.imageResolution.height))
    private var gridPointsBuffer: MTLBuffer!

    private var relaxedStencilState: MTLDepthStencilState!
    private lazy var unprojectPipelineState = makeUnprojectionPipelineState()!
    private let confidenceThreshold = 1

    private lazy var semaphore = DispatchSemaphore(value: maxBuffers)
    private let orientation = UIInterfaceOrientation.landscapeRight
    private var viewportSize = CGSize()
    private lazy var rotateToARCamera = Self.makeRotateToARCameraMatrix(orientation: orientation)

    private lazy var pointCloudUniforms: PointCloudUniforms = {
        var uniforms = PointCloudUniforms()
        uniforms.maxPoints = Int32(maxPoints)
        uniforms.confidenceThreshold = Int32(confidenceThreshold)
        uniforms.particleSize = particleSize
        uniforms.cameraResolution = cameraResolution
        uniforms.modelTransform = matrix_float4x4(
            simd_float4(1, 0,  0, 0),
            simd_float4(0, 1,  0, 0),
            simd_float4(0, 0,  1, 0),
            simd_float4(0, 0,  0, 1))
        return uniforms
    }()
    
    var modelTransform: matrix_float4x4 {
        get {
            return pointCloudUniforms.modelTransform
        }
        set(value) {
            pointCloudUniforms.modelTransform = value
        }
    }

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
        func initViewPortSize() {
            viewportSize = mtkView.bounds.size
        }

        self.device = device
        self.session = session
        self.mtkView = mtkView

        buildBuffer()
        buildStencilState()
        initViewPortSize()
    }
    
    private func makeUnprojectionPipelineState() -> MTLRenderPipelineState? {
        guard let vertexFunction = library.makeFunction(name: "unprojectVertex"),
              let fragmentFunction = library.makeFunction(name: "simpleFragmentShader")
        else {
                return nil
        }
        
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
//        descriptor.sampleCount = mtkView.sampleCount
//        descriptor.isRasterizationEnabled = false
        descriptor.depthAttachmentPixelFormat = mtkView.depthStencilPixelFormat
        descriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        
        return try? device.makeRenderPipelineState(descriptor: descriptor)
    }
    
    func drawRectResized(size: CGSize) {
        viewportSize = size
    }

    func update(_ commandBuffer: MTLCommandBuffer, renderEncoder: MTLRenderCommandEncoder, capturedImageTextureY: CVMetalTexture, capturedImageTextureCbCr: CVMetalTexture, depthTexture: CVMetalTexture, confidenceTexture: CVMetalTexture) {
        func updateUniforms() {
            guard let frame = session.currentFrame else {return}
            let camera = frame.camera
            let cameraIntrinsicsInversed = camera.intrinsics.inverse
            let viewMatrix = camera.viewMatrix(for: orientation)
            let viewMatrixInversed = viewMatrix.inverse
            let projectionMatrix = camera.projectionMatrix(for: orientation, viewportSize: viewportSize, zNear: 0.001, zFar: 0)
            pointCloudUniforms.viewProjectionMatrix = projectionMatrix * viewMatrix
            pointCloudUniforms.localToWorld = viewMatrixInversed * rotateToARCamera
            pointCloudUniforms.cameraIntrinsicsInversed = cameraIntrinsicsInversed
        }
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        commandBuffer.addCompletedHandler { [weak self] commandBuffer in
            if let self = self {
                self.semaphore.signal()
            }
        }
        
        updateUniforms()

        var retainingTextures = [capturedImageTextureY, capturedImageTextureCbCr, depthTexture, confidenceTexture]
        commandBuffer.addCompletedHandler { buffer in
            retainingTextures.removeAll()
        }
        
        renderEncoder.setDepthStencilState(relaxedStencilState)
        renderEncoder.setRenderPipelineState(unprojectPipelineState)
        renderEncoder.setVertexBytes(&pointCloudUniforms, length: MemoryLayout<PointCloudUniforms>.stride, index: 0)
        renderEncoder.setVertexBuffer(gridPointsBuffer, offset: 0, index: 1)
        renderEncoder.setVertexTexture(CVMetalTextureGetTexture(capturedImageTextureY), index: 0)
        renderEncoder.setVertexTexture(CVMetalTextureGetTexture(capturedImageTextureCbCr), index: 1)
        renderEncoder.setVertexTexture(CVMetalTextureGetTexture(depthTexture), index: 2)
        renderEncoder.setVertexTexture(CVMetalTextureGetTexture(confidenceTexture), index: 3)
        renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: numGridPoints)
        renderEncoder.endEncoding()
    }

    static func makeRotateToARCameraMatrix(orientation: UIInterfaceOrientation) -> matrix_float4x4 {
        func cameraToDisplayRotation(orientation: UIInterfaceOrientation) -> Int {
            switch orientation {
            case .landscapeLeft:
                return 180
            case .portrait:
                return 90
            case .portraitUpsideDown:
                return -90
            default:
                return 0
            }
        }
        let flipYZ = matrix_float4x4(
            [1, 0, 0, 0],
            [0, -1, 0, 0],
            [0, 0, -1, 0],
            [0, 0, 0, 1] )

        let rotationAngle = Float(cameraToDisplayRotation(orientation: orientation)) * .degreesToRadian
        return flipYZ * matrix_float4x4(simd_quaternion(rotationAngle, Float3(0, 0, 1)))
    }
}

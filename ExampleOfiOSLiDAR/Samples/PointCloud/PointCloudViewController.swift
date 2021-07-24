//
//  ViewController.swift
//  ExampleOfiOSLiDAR
//
//  Created by TokyoYoshida on 2021/01/07.
//

import ARKit
import Metal
import MetalKit
import CoreImage

class PointCloudViewController: UIViewController, UIGestureRecognizerDelegate {
    @IBOutlet weak var mtkView: MTKView!
    
    // ARKit
    private var session: ARSession!
    var alphaTexture: MTLTexture?

    // Metal
    private let device = MTLCreateSystemDefaultDevice()!
    private var commandQueue: MTLCommandQueue!
    private var matteGenerator: ARMatteGenerator!
    lazy private var textureCache: CVMetalTextureCache = {
        var cache: CVMetalTextureCache?
        CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &cache)
        return cache!
    }()

    private var texture: MTLTexture!
    lazy private var renderer = PointCloudRenderer(device: device,session: session, mtkView: mtkView)
    
    var orientation: UIInterfaceOrientation {
        guard let orientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation else {
            fatalError()
        }
        return orientation
    }

    override func viewDidLoad() {
        func initMatteGenerator() {
            matteGenerator = ARMatteGenerator(device: device, matteResolution: .half)
        }
        func initMetal() {
            commandQueue = device.makeCommandQueue()
            mtkView.device = device
            mtkView.framebufferOnly = false
            mtkView.delegate = self
        }
        func buildConfigure() -> ARWorldTrackingConfiguration {
            let configuration = ARWorldTrackingConfiguration()

            configuration.environmentTexturing = .automatic
            if type(of: configuration).supportsFrameSemantics(.sceneDepth) {
               configuration.frameSemantics = .sceneDepth
            }

            return configuration
        }
        func runARSession() {
            let configuration = buildConfigure()
            session.run(configuration)
        }
        func initARSession() {
            session = ARSession()
            runARSession()
        }
        func createTexture() {
            let width = mtkView.currentDrawable!.texture.width
            let height = mtkView.currentDrawable!.texture.height

            let colorDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: mtkView.colorPixelFormat,
                                                                 width: height, height: width, mipmapped: false)
            colorDesc.usage = MTLTextureUsage(rawValue: MTLTextureUsage.renderTarget.rawValue | MTLTextureUsage.shaderRead.rawValue)

        }
        func initGesture() {
            let tapGesture = UIPanGestureRecognizer(target: self, action: #selector(swipeScreen(_:)))
            tapGesture.delegate = self
            self.view.addGestureRecognizer(tapGesture)
        }
        super.viewDidLoad()
        initARSession()
        initMatteGenerator()
        initMetal()
        createTexture()
        initGesture()
    }

    @objc func swipeScreen(_ sender:UIPanGestureRecognizer){
        let maxRad = Float.pi * 0.01
        let cameraResolution = Float2(Float(session.currentFrame?.camera.imageResolution.width ?? 0), Float(session.currentFrame?.camera.imageResolution.height ?? 0))
        let point = sender.translation(in: view)

        let radY = -(maxRad * Float(point.x) / cameraResolution.x).truncatingRemainder(dividingBy: Float.pi)
        let rotateY = matrix_float4x4(
                simd_float4(cos(radY), 0,  0, -sin(radY)),
                simd_float4(0, 1,  0, 0),
                simd_float4(sin(radY), 0,  cos(radY), 0),
            simd_float4(0, 0, 0, 1))

        let radX = -(maxRad * Float(point.y) / cameraResolution.y).truncatingRemainder(dividingBy: Float.pi)
        let rotateX = matrix_float4x4(
                simd_float4(1, 0,  0, 0),
                simd_float4(0, cos(radX),  sin(radX), 0),
                simd_float4(0, -sin(radX), cos(radX), 0),
            simd_float4(0, 0, 0, 1))

        renderer.modelTransform = simd_mul(simd_mul(renderer.modelTransform, rotateY),rotateX)

        print(point)
        print(renderer.modelTransform)
    }
}

extension PointCloudViewController: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        guard session.currentFrame != nil else {return}
        renderer.drawRectResized(size: size)
    }

    func draw(in view: MTKView) {
        func getAlphaTexture(_ commandBuffer: MTLCommandBuffer) -> MTLTexture? {
            guard let currentFrame = session.currentFrame else {
                return nil
            }

            return matteGenerator.generateMatte(from: currentFrame, commandBuffer: commandBuffer)
        }
        func buildRenderEncoder(_ commandBuffer: MTLCommandBuffer) -> MTLRenderCommandEncoder? {
            let rpd = view.currentRenderPassDescriptor
            rpd?.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1)
            rpd?.colorAttachments[0].loadAction = .clear
            rpd?.colorAttachments[0].storeAction = .store
            return commandBuffer.makeRenderCommandEncoder(descriptor: rpd!)
        }
        guard let drawable = view.currentDrawable else {return}
        
        let commandBuffer = commandQueue.makeCommandBuffer()!
        
        guard let (textureY, textureCbCr) = session.currentFrame?.buildCapturedImageTextures(textureCache: textureCache) else {return}

        guard let (depthTexture, confidenceTexture) = session.currentFrame?.buildDepthTextures(textureCache: textureCache) else {return}

        guard let encoder = buildRenderEncoder(commandBuffer) else {return}

        renderer.update(commandBuffer, renderEncoder: encoder, capturedImageTextureY: textureY, capturedImageTextureCbCr: textureCbCr, depthTexture: depthTexture, confidenceTexture: confidenceTexture)
                
        commandBuffer.present(drawable)
        
        commandBuffer.commit()
        
        commandBuffer.waitUntilCompleted()
    }
}

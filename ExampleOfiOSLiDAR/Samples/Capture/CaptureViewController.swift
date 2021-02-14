//
//  CaptureViewController.swift
//  ExampleOfiOSLiDAR
//
//  Created by TokyoYoshida on 2021/02/10.
//

import RealityKit
import ARKit

class LabelScene: SKScene {
    var onTapped: (() -> Void)? = nil
    override public init(size: CGSize){
        super.init(size: size)

        self.scaleMode = SKSceneScaleMode.resizeFill

        let label = SKLabelNode(fontNamed: "Chalkduster")
        label.text = "Capture"
        label.fontSize = 65
        label.fontColor = .blue
        label.position = CGPoint(x:frame.midX, y: label.frame.size.height)

        self.addChild(label)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("Not been implemented")
    }
    
    convenience init(size: CGSize, onTapped: @escaping () -> Void) {
        self.init(size: size)
        self.onTapped = onTapped
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let onTapped = self.onTapped {
            onTapped()
        }
    }
}
class CaptureViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    
    @IBOutlet weak var sceneView: ARSCNView!
    var cameraImage: CGImage?
    var captureingFlg = false
    
    var orientation: UIInterfaceOrientation {
        guard let orientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation else {
            fatalError()
        }
        return orientation
    }
    lazy var viewportSize: CGSize = sceneView.bounds.size

    @IBOutlet weak var imageViewHeight: NSLayoutConstraint!
    lazy var imageViewSize: CGSize = {
        CGSize(width: view.bounds.size.width, height: imageViewHeight.constant)
    }()

    override func viewDidLoad() {
        func setARViewOptions() {
            sceneView.scene = SCNScene()
        }
        func buildConfigure() -> ARWorldTrackingConfiguration {
            let configuration = ARWorldTrackingConfiguration()

            configuration.environmentTexturing = .automatic
            configuration.sceneReconstruction = .mesh
            if type(of: configuration).supportsFrameSemantics(.sceneDepth) {
               configuration.frameSemantics = .sceneDepth
            }

            return configuration
        }
        func setControls() {
            sceneView.overlaySKScene = LabelScene(size:sceneView.bounds.size) { [weak self] in
                self?.tappedCaptureButton()
            }
        }
        super.viewDidLoad()
        sceneView.delegate = self
        sceneView.session.delegate = self
        setARViewOptions()
        let configuration = buildConfigure()
        sceneView.session.run(configuration)
        setControls()
    }
    
    func session(_ session: ARSession, didUpdate: ARFrame){
        self.cameraImage = self.captureCamera()
   }

    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        
        guard captureingFlg == false,
              let anchor = anchor as? ARMeshAnchor ,
              let frame = sceneView.session.currentFrame else { return nil }

        let node = SCNNode()
        let geometry = captureGeometory(frame: frame, anchor: anchor, node: node)
        node.geometry = geometry

        return node
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard captureingFlg == false,
              let frame = sceneView.session.currentFrame else { return }
        guard let anchor = anchor as? ARMeshAnchor else { return }
        let geometry = captureGeometory(frame: frame, anchor: anchor, node: node)
        node.geometry = geometry
    }
    
    func captureGeometory(frame: ARFrame, anchor: ARMeshAnchor, node: SCNNode, needTexture: Bool = false) -> SCNGeometry {

        let camera = frame.camera

        let geometory = SCNGeometry(geometry: anchor.geometry, camera: camera, modelMatrix: anchor.transform)
        node.geometry = geometory

        if needTexture {
            let texture = cameraImage
            let imageMaterial = SCNMaterial()
            imageMaterial.isDoubleSided = false
            imageMaterial.diffuse.contents = texture
            geometory.materials = [imageMaterial]
        }
        
        return geometory
    }
    
    func tappedCaptureButton() {
        func captureColor() {
            guard let frame = sceneView.session.currentFrame else { return }
            let camera = frame.camera
            guard let anchors = sceneView.session.currentFrame?.anchors else { return }
            let meshAnchors = anchors.compactMap { $0 as? ARMeshAnchor}
            for anchor in meshAnchors {
                guard let node = sceneView.node(for: anchor) else { continue }
                let geometory = captureGeometory(frame: frame, anchor: anchor, node: node, needTexture: true)
                node.geometry = geometory
            }
        }
        captureingFlg = true
        DispatchQueue.main.async {
            captureColor()
            self.captureingFlg = false
        }
    }
    func captureCamera() -> CGImage?{
        guard let frame = sceneView.session.currentFrame else {return nil}

        let pixelBuffer = frame.capturedImage

        var image = CIImage(cvPixelBuffer: pixelBuffer)

        let transform = frame.displayTransform(for: orientation, viewportSize: viewportSize).inverted()
        image = image.transformed(by: transform)

        let context = CIContext(options:nil)
        guard let cameraImage = context.createCGImage(image, from: image.extent) else {return nil}

        return cameraImage
    }
}

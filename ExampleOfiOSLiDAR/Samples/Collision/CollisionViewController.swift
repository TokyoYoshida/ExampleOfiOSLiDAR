//
//  CollisionViewController.swift
//  ExampleOfiOSLiDAR
//
//  Created by TokyoYoshida on 2021/02/01.
//

import RealityKit
import ARKit

class CollisionViewController: UIViewController, ARSessionDelegate {
    
    @IBOutlet var arView: ARView!
    @IBOutlet weak var imageView: UIImageView!
    
    var orientation: UIInterfaceOrientation {
        guard let orientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation else {
            fatalError()
        }
        return orientation
    }
    @IBOutlet weak var imageViewHeight: NSLayoutConstraint!
    lazy var imageViewSize: CGSize = {
        CGSize(width: view.bounds.size.width, height: imageViewHeight.constant)
    }()

    override func viewDidLoad() {
        func setARViewOptions() {
            arView.environment.sceneUnderstanding.options = []
            arView.environment.sceneUnderstanding.options.insert(.occlusion)
            arView.environment.sceneUnderstanding.options.insert(.physics)
            arView.renderOptions = [.disablePersonOcclusion, .disableDepthOfField, .disableMotionBlur]
            arView.automaticallyConfigureSession = false
        }
        func buildConfigure() -> ARWorldTrackingConfiguration {
            let configuration = ARWorldTrackingConfiguration()

            configuration.sceneReconstruction = .meshWithClassification
            configuration.environmentTexturing = .automatic
            if type(of: configuration).supportsFrameSemantics(.sceneDepth) {
               configuration.frameSemantics = .sceneDepth
            }

            return configuration
        }
        func initARView() {
            setARViewOptions()
            let configuration = buildConfigure()
            arView.session.run(configuration)
        }
        func addGesture() {
            let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            arView.addGestureRecognizer(tapRecognizer)
        }
        func loadAnchor() {
            let boxAnchor = try! Experience.loadBox()
            arView.scene.anchors.append(boxAnchor)
        }
        super.viewDidLoad()
        
        arView.session.delegate = self
        initARView()
        addGesture()
        loadAnchor()
    }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
//        imageView.image = session.currentFrame?.depthMapTransformedImage(orientation: orientation, viewPort: self.imageView.bounds)
    }

    @objc
    func handleTap(_ sender: UITapGestureRecognizer) {
        func getTapPositionInWorld() -> SIMD3<Float> {
            let screenPos = sender.location(in: nil)
            let worldPos = arView.unproject(screenPos, viewport: arView.bounds)!
            return worldPos
        }
        func buildSphere(radius: Float, color: UIColor) -> ModelEntity {
            let sphere = ModelEntity(mesh: .generateSphere(radius: radius), materials: [SimpleMaterial(color: color, isMetallic: false)])
            sphere.position.y = radius
            return sphere
        }
        let tapLocation = getTapPositionInWorld()
        let sphere = buildSphere(radius: 0.1, color: .lightGray)
//        sphere.position = tapLocation
        let transform: simd_float4x4(tapLocation.x, tapLocation.y, tapLocation.z, 1)
        let anchor = ARAnchor(name:"sphere",
                              toransform: transform)
        arView.scene.anchors.append(anchor)

//        let transform = simd
//        if let result = arView.raycast(from: tapLocation, allowing: .estimatedPlane, alignment: .any).first {
//            let resultAnchor = AnchorEntity(world: result.worldTransform)
//            resultAnchor.addChild(buildSphere(radius: 0.1, color: .lightGray))
//            arView.scene.addAnchor(resultAnchor)
//        }
    }
}

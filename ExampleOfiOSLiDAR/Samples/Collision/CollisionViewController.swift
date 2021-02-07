//
//  CollisionViewController.swift
//  ExampleOfiOSLiDAR
//
//  Created by TokyoYoshida on 2021/02/01.
//

import RealityKit
import ARKit
import Combine

class CustomBox: Entity, HasModel {
  required init() {
    super.init()
    self.components[ModelComponent] = ModelComponent(
      mesh: .generateBox(size: [1, 0.2, 1]),
      materials: [SimpleMaterial(
                    color: .red,
        isMetallic: false)
      ]
    )
  }
}

class CollisionViewController: UIViewController, ARSessionDelegate {
    
    @IBOutlet var arView: ARView!
    @IBOutlet weak var imageView: UIImageView!
    let boxAnchor = try! Experience.loadBox()
    let plane = CustomBox()
    var sceneObserver: Cancellable?
    let anchorName = "ball"

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
            configuration.planeDetection = [.horizontal]
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
            arView.scene.anchors.append(boxAnchor)
        }
        super.viewDidLoad()
        
        arView.session.delegate = self
        initARView()
        addGesture()
        loadAnchor()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        sceneObserver = arView.scene.subscribe(to: SceneEvents.Update.self, {event in
                self.updateLoop(deltaTimeInterval: event.deltaTime)
        })
    }
    
    func getZForward(transform: simd_float4x4) -> SIMD3<Float> {
        return SIMD3<Float>(transform.columns.2.x, transform.columns.2.y, transform.columns.2.z)
    }

    // main loop for each frame
    func updateLoop(deltaTimeInterval: TimeInterval) {
        guard let camera = arView.session.currentFrame?.camera else {return}
        let foward = getZForward(transform: camera.transform)
        let anchors = arView.scene.anchors.filter {
            $0.name == anchorName
        }
        for anchor in anchors {
//            anchor.position -= foward*0.1
        }
        
    }

    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            guard let planeAnchor = anchor as? ARPlaneAnchor else { continue }
            let box = CustomBox()
            box.position = simd_make_float3(
                planeAnchor.transform.columns.3.x,
                planeAnchor.transform.columns.3.y,
                planeAnchor.transform.columns.3.z)
//            boxAnchor.addChild(box)
        }
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors {
            guard let planeAnchor = anchor as? ARPlaneAnchor else { continue }
//            boxAnchor.setTransformMatrix(planeAnchor.transform, relativeTo: nil)
            plane.position = simd_make_float3(
                planeAnchor.transform.columns.3.x,
                planeAnchor.transform.columns.3.y,
                planeAnchor.transform.columns.3.z)
        }
    }

    
    @objc
    func handleTap(_ sender: UITapGestureRecognizer) {
        func sphere(radius: Float, color: UIColor, foward: SIMD3<Float>) -> ModelEntity {
            let sphere = ModelEntity(mesh: .generateSphere(radius: radius), materials: [SimpleMaterial(color: color, isMetallic: true)])

            sphere.generateCollisionShapes(recursive: true)
            sphere.physicsBody = .init()
            sphere.physicsBody?.mode = .dynamic
            sphere.physicsMotion =  PhysicsMotionComponent(linearVelocity: foward,
                                                           angularVelocity: [0, 0, 0])

            return sphere
        }
        func calcBallDirection(cameraTransform: simd_float4x4) -> SIMD3<Float> {
//            let rotation = simd_float4(1, 0, 0, -.pi/2)
//            let trans = simd_mul(cameraTransform, rotation)
            return -getZForward(transform: cameraTransform)
        }
        func addObjectOnTappedPoint() {
            guard let currentFrame = arView.session.currentFrame else {return}
            var translation = matrix_identity_float4x4
           translation.columns.3.z = -0.1
           let transform = simd_mul(currentFrame.camera.transform, translation)

            let forward = calcBallDirection(cameraTransform: transform)
            let resultAnchor = AnchorEntity(world: transform)
            resultAnchor.name = anchorName
            resultAnchor.addChild(sphere(radius: 0.01, color: .lightGray, foward: forward))
            arView.scene.addAnchor(resultAnchor)
//            resultAnchor.transform = arView.cameraTransform
//            resultAnchor.position += getZForward(transform: arView.cameraTransform.matrix)*1
        }
        addObjectOnTappedPoint()
    }
}

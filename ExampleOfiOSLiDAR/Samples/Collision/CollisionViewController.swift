//
//  CollisionViewController.swift
//  ExampleOfiOSLiDAR
//
//  Created by TokyoYoshida on 2021/02/01.
//

import RealityKit
import ARKit

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
        func sphere(radius: Float, color: UIColor) -> ModelEntity {
            let sphere = ModelEntity(mesh: .generateSphere(radius: radius), materials: [SimpleMaterial(color: color, isMetallic: false)])

            sphere.position.y = radius
            return sphere
        }
        func addObjectOnTappedPoint() {
            let tappedLocation = sender.location(in: arView)
            
            let tappedWorld = arView.unproject(tappedLocation, viewport: arView.bounds)
            let resultAnchor = AnchorEntity()
            resultAnchor.addChild(sphere(radius: 0.1, color: .lightGray))
            arView.scene.addAnchor(resultAnchor)
            resultAnchor.position = tappedWorld!
        }
        addObjectOnTappedPoint()
    }
}

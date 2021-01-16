//
//  DepthMapPolygonViewController.swift
//  ExampleOfiOSLiDAR
//
//  Created by TokyoYoshida on 2021/01/16.
//

import RealityKit
import ARKit

class DepthMapPolygonViewController: UIViewController, ARSessionDelegate {
    
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
        super.viewDidLoad()
        
        arView.session.delegate = self

        
        // Add the box anchor to the scene

        arView.environment.sceneUnderstanding.options = []
        arView.environment.sceneUnderstanding.options.insert(.occlusion)
        arView.environment.sceneUnderstanding.options.insert(.physics)
//        arView.debugOptions.insert(.showSceneUnderstanding)
        arView.renderOptions = [.disablePersonOcclusion, .disableDepthOfField, .disableMotionBlur]
        arView.automaticallyConfigureSession = false

        let configuration = ARWorldTrackingConfiguration()
        configuration.sceneReconstruction = .meshWithClassification

        configuration.environmentTexturing = .automatic
        if type(of: configuration).supportsFrameSemantics(.sceneDepth) {
           // Activate sceneDepth
           configuration.frameSemantics = .sceneDepth
        }
        arView.session.run(configuration)

        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        arView.addGestureRecognizer(tapRecognizer)

        // Load the "Box" scene from the "Experience" Reality File
        let boxAnchor = try! Experience.loadBox()
        arView.scene.anchors.append(boxAnchor)
    }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
       guard let sceneDepth = frame.smoothedSceneDepth ?? frame.sceneDepth  else { return }
        var pixelBuffer: CVPixelBuffer!
        pixelBuffer = sceneDepth.depthMap
        
        imageView.image = session.currentFrame?.depthMapTransformedImage(orientation: orientation, size: self.imageView.bounds.size)
        

//        var texturePixelFormat: MTLPixelFormat!
//        setMTLPixelFormat(&texturePixelFormat, basedOn: pixelBuffer)
//        depthTexture = createTexture(fromPixelBuffer: pixelBuffer, pixelFormat: texturePixelFormat, planeIndex: 0)
    }

    @objc
    func handleTap(_ sender: UITapGestureRecognizer) {
        func sphere(radius: Float, color: UIColor) -> ModelEntity {
            let sphere = ModelEntity(mesh: .generateSphere(radius: radius), materials: [SimpleMaterial(color: color, isMetallic: false)])
            // Move sphere up by half its diameter so that it does not intersect with the mesh
            sphere.position.y = radius
            return sphere
        }
        let tapLocation = sender.location(in: arView)
        if let result = arView.raycast(from: tapLocation, allowing: .estimatedPlane, alignment: .any).first {
            let resultAnchor = AnchorEntity(world: result.worldTransform)
            resultAnchor.addChild(sphere(radius: 0.1, color: .lightGray))
            arView.scene.addAnchor(resultAnchor)
        }
    }
}

//
//  CollisionViewController.swift
//  ExampleOfiOSLiDAR
//
//  Created by TokyoYoshida on 2021/02/01.
//

import RealityKit
import ARKit
import Combine

class CollisionViewController: UIViewController, ARSessionDelegate {
    
    @IBOutlet var arView: ARView!
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
        super.viewDidLoad()
        
        arView.session.delegate = self
        initARView()
        addGesture()
    }
    
    func getZForward(transform: simd_float4x4) -> SIMD3<Float> {
        return SIMD3<Float>(transform.columns.2.x, transform.columns.2.y, transform.columns.2.z)
    }

    @objc
    func handleTap(_ sender: UITapGestureRecognizer) {
        func buildBall(radius: Float, color: UIColor, linearVelocity: SIMD3<Float>) -> ModelEntity {
            let sphere = ModelEntity(mesh: .generateSphere(radius: radius), materials: [SimpleMaterial(color: color, isMetallic: true)])

            sphere.generateCollisionShapes(recursive: true)
            sphere.physicsBody = .init()
            sphere.physicsBody?.mode = .dynamic
            sphere.physicsMotion =  PhysicsMotionComponent(linearVelocity: linearVelocity,
                                                           angularVelocity: [0, 0, 0])

            return sphere
        }
        func calcBallPosition(cameraTransform: simd_float4x4) -> simd_float4x4 {
           var translation = matrix_identity_float4x4
           translation.columns.3.z = -0.1
           return simd_mul(cameraTransform, translation)
        }
        func calcBallDirection(cameraTransform: simd_float4x4) -> SIMD3<Float> {
            var moveTrans = matrix_identity_float4x4
            moveTrans.columns.3.z = -0.1

            var rotateXTrans = matrix_identity_float4x4
            let rad = Float.pi/4
            rotateXTrans.columns.1.y = cos(rad)
            rotateXTrans.columns.1.z = sin(rad)
            rotateXTrans.columns.2.y = -sin(rad)
            rotateXTrans.columns.2.z = cos(rad)

            let transform = cameraTransform * moveTrans * rotateXTrans

            return -getZForward(transform: transform)
        }
        func addObjectOnTappedPoint() {
            guard let currentFrame = arView.session.currentFrame else {return}
            let cameraTransform = currentFrame.camera.transform

            let ballPosition = calcBallPosition(cameraTransform: cameraTransform)
            let ballVelocity = calcBallDirection(cameraTransform: cameraTransform)

            let resultAnchor = AnchorEntity(world: ballPosition)
            resultAnchor.name = anchorName
            let ball = buildBall(radius: 0.01, color: .lightGray, linearVelocity: ballVelocity)

            resultAnchor.addChild(ball)
            arView.scene.addAnchor(resultAnchor)
        }
        addObjectOnTappedPoint()
    }
}

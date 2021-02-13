//
//  CaptureViewController.swift
//  ExampleOfiOSLiDAR
//
//  Created by TokyoYoshida on 2021/02/10.
//

import RealityKit
import ARKit

class CaptureViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    
    @IBOutlet weak var sceneView: ARSCNView!
    var capturedImage: UIImage?
    
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
        super.viewDidLoad()
        sceneView.delegate = self
        sceneView.session.delegate = self
        setARViewOptions()
        let configuration = buildConfigure()
        sceneView.session.run(configuration)
    }
    
    func session(_ session: ARSession, didUpdate: ARFrame){
        guard let image = session.currentFrame?.capturedImage else {
            return
        }
        capturedImage = UIImage(ciImage: CIImage(cvImageBuffer: image))
    }

    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        
        guard let anchor = anchor as? ARMeshAnchor ,
              let frame = sceneView.session.currentFrame else { return nil }

        let camera = frame.camera
        let geometory = SCNGeometry(geometry: anchor.geometry, camera: camera, modelMatrix: anchor.transform)
        let texture = capturedImage
        let imageMaterial = SCNMaterial()
        imageMaterial.isDoubleSided = false
        imageMaterial.diffuse.contents = texture
        geometory.materials = [imageMaterial]
        let node = SCNNode(geometry: geometory)

        return node
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let anchor = anchor as? ARMeshAnchor ,
              let frame = sceneView.session.currentFrame else { return }

        let camera = frame.camera

        let geometory = SCNGeometry(geometry: anchor.geometry, camera: camera, modelMatrix: anchor.transform)
        node.geometry = geometory

        let texture = capturedImage
        let imageMaterial = SCNMaterial()
        imageMaterial.isDoubleSided = false
        imageMaterial.diffuse.contents = texture
        geometory.materials = [imageMaterial]
    }
}

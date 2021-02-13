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
    var cameraImage: CGImage?
    
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
        super.viewDidLoad()
        sceneView.delegate = self
        sceneView.session.delegate = self
        setARViewOptions()
        let configuration = buildConfigure()
        sceneView.session.run(configuration)
    }
    
    func session(_ session: ARSession, didUpdate: ARFrame){
        DispatchQueue.main.async {
            self.cameraImage = self.captureCamera()
        }
   }

    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        
        guard let anchor = anchor as? ARMeshAnchor ,
              let frame = sceneView.session.currentFrame else { return nil }

        let camera = frame.camera
        let geometory = SCNGeometry(geometry: anchor.geometry, camera: camera, modelMatrix: anchor.transform)
        let texture = cameraImage
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

        let texture = cameraImage
        let imageMaterial = SCNMaterial()
        imageMaterial.isDoubleSided = false
        imageMaterial.diffuse.contents = texture
        geometory.materials = [imageMaterial]
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

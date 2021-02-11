//
//  CaptureViewController.swift
//  ExampleOfiOSLiDAR
//
//  Created by TokyoYoshida on 2021/02/10.
//

import RealityKit
import ARKit

class CaptureViewController: UIViewController, ARSessionDelegate {
    
    @IBOutlet var arView: ARView!
    
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
            arView.debugOptions.insert(.showSceneUnderstanding)
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
        func initARView() {
            setARViewOptions()
            let configuration = buildConfigure()
            arView.session.run(configuration)
        }
        arView.session.delegate = self
        super.viewDidLoad()
        initARView()
    }

    @IBAction func tappedExportButton(_ sender: UIButton) {
        func convertToAsset(meshAnchors: [ARMeshAnchor]) -> MDLAsset? {
            guard let device = MTLCreateSystemDefaultDevice() else {return nil}

            let asset = MDLAsset()

            for anchor in meshAnchors {
                let mdlMesh = anchor.geometry.toMDLMesh(device: device)
                asset.add(mdlMesh)
            }
            
            return asset
        }
        func export(asset: MDLAsset) throws -> URL {
            let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let url = directory.appendingPathComponent("scaned.obj")

            try asset.export(to: url)

            return url
        }
        func share(url: URL) {
            let vc = UIActivityViewController(activityItems: [url],applicationActivities: nil)
            vc.popoverPresentationController?.sourceView = sender
            self.present(vc, animated: true, completion: nil)
        }
        if let meshAnchors = arView.session.currentFrame?.anchors.compactMap({ $0 as? ARMeshAnchor }),
           let asset = convertToAsset(meshAnchors: meshAnchors) {
            do {
                let url = try export(asset: asset)
                share(url: url)
            } catch {
                print("export error")
            }
        }
    }
}

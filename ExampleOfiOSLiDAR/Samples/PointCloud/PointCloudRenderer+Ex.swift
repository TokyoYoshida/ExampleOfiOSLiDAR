//
//  PointCloudRenderer+Ex.swift
//  ExampleOfiOSLiDAR
//
//  Created by TokyoYoshida on 2021/07/23.
//

import Metal
import MetalKit
import ARKit

extension PointCloudRenderer {
    class PointCloudBuider {
        private let numGridPoints = 500

        private let session: ARSession
        private var sampleFrame: ARFrame { session.currentFrame! }
        private lazy var cameraResolution = Float2(Float(sampleFrame.camera.imageResolution.width), Float(sampleFrame.camera.imageResolution.height))
        
        init(session: ARSession) {
            self.session = session
        }

        func makeGridPoints() -> [Float2] {
            let gridArea = cameraResolution.x * cameraResolution.y
            let spacing = sqrt(gridArea / Float(numGridPoints))
            let deltaX = Int(round(cameraResolution.x / spacing))
            let deltaY = Int(round(cameraResolution.y / spacing))
            
            var points = [Float2]()
            for gridY in 0 ..< deltaY {
                let alternatingOffsetX = Float(gridY % 2) * spacing / 2
                for gridX in 0 ..< deltaX {
                    let cameraPoint = Float2(alternatingOffsetX + (Float(gridX) + 0.5) * spacing, (Float(gridY) + 0.5) * spacing)
                    
                    points.append(cameraPoint)
                }
            }
            
            return points
        }
    }
}

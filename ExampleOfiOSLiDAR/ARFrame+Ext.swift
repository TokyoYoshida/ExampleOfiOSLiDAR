//
//  ARFrame+Ext.swift
//  ExampleOfiOSLiDAR
//
//  Created by TokyoYoshida on 2021/01/14.
//

import ARKit
import UIKit

extension ARFrame {
    func depthMapImage(orientation: UIInterfaceOrientation, size: CGSize) -> UIImage? {
        guard let pixelBuffer = self.sceneDepth?.depthMap else { return nil }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let transform = self.displayTransform(for: orientation, viewportSize: size).inverted()
//        let transform = self.displayTransform(for: .portrait, viewportSize: size)
//        let transform = CGAffineTransform(a: 1, b: 0, c: 0, d: 1, tx: 0, ty: 0)
        let cgImage = CIContext().createCGImage(ciImage.transformed(by: transform), from: ciImage.extent)
        guard let image = cgImage else { return nil }
        return UIImage(cgImage: image)
    }
}

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
        let imageSize = CGSize(width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))
        let normalizeTransform = CGAffineTransform(scaleX: 1.0/imageSize.width, y: 1.0/imageSize.height)
        let flipTransform = (orientation.isPortrait) ? CGAffineTransform(scaleX: -1, y: -1).translatedBy(x: -1, y: -1) : .identity

        let displayTransform = self.displayTransform(for: orientation, viewportSize: size)
        let toViewPortTransform = CGAffineTransform(scaleX: size.width, y: size.height)
        let transform = normalizeTransform
                .concatenating(flipTransform)
                .concatenating(displayTransform)
                .concatenating(toViewPortTransform)
        
        let cgImage = CIContext().createCGImage(ciImage.transformed(by: transform), from: ciImage.extent)
        guard let image = cgImage else { return nil }
        return UIImage(cgImage: image)
    }

    func depthMapTransformedImage(orientation: UIInterfaceOrientation, rect: CGRect) -> UIImage? {
        let size = rect.size
        guard let pixelBuffer = self.sceneDepth?.depthMap else { return nil }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let imageSize = CGSize(width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))
        let normalizeTransform = CGAffineTransform(scaleX: 1.0/imageSize.width, y: 1.0/imageSize.height)
        let flipTransform = (orientation.isPortrait) ? CGAffineTransform(scaleX: -1, y: -1).translatedBy(x: -1, y: -1) : .identity
        let displayTransform = self.displayTransform(for: orientation, viewportSize: size)
        let toViewPortTransform = CGAffineTransform(scaleX: size.width, y: size.height)
        let transform = normalizeTransform.concatenating(flipTransform).concatenating(displayTransform).concatenating(toViewPortTransform)
        
        return UIImage(ciImage: ciImage.transformed(by: transform).cropped(to: rect))
    }

    func depthMapRawImage() -> UIImage? {
        guard let pixelBuffer = self.sceneDepth?.depthMap else { return nil }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let cgImage = CIContext().createCGImage(ciImage, from: ciImage.extent)
        guard let image = cgImage else { return nil }
        return UIImage(cgImage: image)
    }

    func cameraToDisplayRotation(orientation: UIInterfaceOrientation) -> Int {
        switch orientation {
        case .landscapeLeft:
            return 180
        case .portrait:
            return 90
        case .portraitUpsideDown:
            return -90
        default:
            return 0
        }
    }

    func cameraToDisplayRotationRadian(orientation: UIInterfaceOrientation) -> CGFloat {
        CGFloat(cameraToDisplayRotation(orientation: orientation)) * .degreesToRadian
    }
}

extension CGFloat {
    static let degreesToRadian = CGFloat.pi / 180
}

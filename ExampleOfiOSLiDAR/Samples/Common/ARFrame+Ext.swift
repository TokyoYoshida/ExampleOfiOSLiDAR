//
//  ARFrame+Ext.swift
//  ExampleOfiOSLiDAR
//
//  Created by TokyoYoshida on 2021/01/14.
//

import ARKit
import UIKit

extension ARFrame {
    func depthMapTransformedImage(orientation: UIInterfaceOrientation, viewPort: CGRect) -> UIImage? {
        guard let pixelBuffer = self.sceneDepth?.depthMap else { return nil }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        return UIImage(ciImage: screenTransformed(ciImage: ciImage, orientation: orientation, viewPort: viewPort))
    }

    func ConfidenceMapTransformedImage(orientation: UIInterfaceOrientation, viewPort: CGRect) -> UIImage? {
        guard let pixelBuffer = self.sceneDepth?.confidenceMap,
              let ciImage = confidenceMapToCIImage(pixelBuffer: pixelBuffer) else { return nil }
        
        return UIImage(ciImage: screenTransformed(ciImage: ciImage, orientation: orientation, viewPort: viewPort))
    }

    func confidenceMapToCIImage(pixelBuffer: CVPixelBuffer) -> CIImage? {
        func confienceValueToPixcelValue(confidenceValue: UInt8) -> UInt8 {
            guard confidenceValue <= ARConfidenceLevel.high.rawValue else {return 0}
            return UInt8(floor(Float(confidenceValue) / Float(ARConfidenceLevel.high.rawValue) * 255))
        }
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        guard let base = CVPixelBufferGetBaseAddress(pixelBuffer) else { return nil }
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)

        for i in stride(from: 0, to: bytesPerRow*height, by: MemoryLayout<UInt8>.stride) {
            let data = base.load(fromByteOffset: i, as: UInt8.self)
            let pixcelValue = confienceValueToPixcelValue(confidenceValue: data)
            base.storeBytes(of: pixcelValue, toByteOffset: i, as: UInt8.self)
        }
        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))

        return CIImage(cvPixelBuffer: pixelBuffer)
    }

    func screenTransformed(ciImage: CIImage, orientation: UIInterfaceOrientation, viewPort: CGRect) -> CIImage {
        let transform = screenTransform(orientation: orientation, viewPortSize: viewPort.size, captureSize: ciImage.extent.size)
        return ciImage.transformed(by: transform).cropped(to: viewPort)
    }

    func screenTransform(orientation: UIInterfaceOrientation, viewPortSize: CGSize, captureSize: CGSize) -> CGAffineTransform {
        let normalizeTransform = CGAffineTransform(scaleX: 1.0/captureSize.width, y: 1.0/captureSize.height)
        let flipTransform = (orientation.isPortrait) ? CGAffineTransform(scaleX: -1, y: -1).translatedBy(x: -1, y: -1) : .identity
        let displayTransform = self.displayTransform(for: orientation, viewportSize: viewPortSize)
        let toViewPortTransform = CGAffineTransform(scaleX: viewPortSize.width, y: viewPortSize.height)
        return normalizeTransform.concatenating(flipTransform).concatenating(displayTransform).concatenating(toViewPortTransform)
    }

    fileprivate func createTexture(fromPixelBuffer pixelBuffer: CVPixelBuffer, pixelFormat: MTLPixelFormat, planeIndex: Int, textureCache: CVMetalTextureCache) -> CVMetalTexture? {
        let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, planeIndex)
        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, planeIndex)
        
        var texture: CVMetalTexture? = nil
        let status = CVMetalTextureCacheCreateTextureFromImage(nil, textureCache, pixelBuffer, nil, pixelFormat,
                                                               width, height, planeIndex, &texture)
        
        if status != kCVReturnSuccess {
            texture = nil
        }
        
        return texture
    }

    func buildCapturedImageTextures(textureCache: CVMetalTextureCache) -> (textureY: CVMetalTexture, textureCbCr: CVMetalTexture)? {
        // Create two textures (Y and CbCr) from the provided frame's captured image
        let pixelBuffer = self.capturedImage
        
        guard CVPixelBufferGetPlaneCount(pixelBuffer) >= 2 else {
            return nil
        }
        
        guard let capturedImageTextureY = createTexture(fromPixelBuffer: pixelBuffer, pixelFormat: .r8Unorm, planeIndex: 0, textureCache: textureCache),
              let capturedImageTextureCbCr = createTexture(fromPixelBuffer: pixelBuffer, pixelFormat: .rg8Unorm, planeIndex: 1, textureCache: textureCache) else {
            return nil
        }
        
        return (textureY: capturedImageTextureY, textureCbCr: capturedImageTextureCbCr)
    }
}

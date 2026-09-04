import CoreGraphics
import Foundation

enum MenuBarItemCaptureGeometry {
    /// Maps a Cocoa-space item frame into pixel coordinates of a captured band.
    /// `itemFrame` and `captureRect` use the same bottom-left origin.
    /// The returned rect is in CGImage space (top-left origin).
    static func pixelCropRect(
        itemFrame: CGRect,
        captureRect: CGRect,
        imageSize: CGSize
    ) -> CGRect? {
        guard captureRect.width > 0, captureRect.height > 0, imageSize.width > 0, imageSize.height > 0 else {
            return nil
        }

        let intersection = itemFrame.intersection(captureRect)
        guard !intersection.isNull, intersection.width > 1, intersection.height > 1 else {
            return nil
        }

        let scaleX = imageSize.width / captureRect.width
        let scaleY = imageSize.height / captureRect.height
        let x = (intersection.minX - captureRect.minX) * scaleX
        let cocoaYFromBottom = intersection.minY - captureRect.minY
        let yFromTop = (captureRect.height - cocoaYFromBottom - intersection.height) * scaleY

        return CGRect(
            x: x,
            y: yFromTop,
            width: intersection.width * scaleX,
            height: intersection.height * scaleY
        )
    }

    static func menuBarCaptureRect(screenFrame: CGRect, visibleFrame: CGRect) -> CGRect {
        let menuBarHeight = max(24, screenFrame.maxY - visibleFrame.maxY)
        return CGRect(
            x: screenFrame.minX,
            y: screenFrame.maxY - menuBarHeight,
            width: screenFrame.width,
            height: menuBarHeight
        )
    }

    static func itemFrame(xPosition: CGFloat?, width: CGFloat?, captureRect: CGRect) -> CGRect? {
        guard let xPosition, let width, width > 1 else { return nil }
        let height = max(16, captureRect.height - 2)
        return CGRect(
            x: xPosition,
            y: captureRect.minY + ((captureRect.height - height) / 2),
            width: width,
            height: height
        )
    }
}

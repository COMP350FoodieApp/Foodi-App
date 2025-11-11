import UIKit

extension UIImage {
    func resized(toMax dimension: CGFloat) -> UIImage {
        let maxDimension = max(size.width, size.height)
        // If already small enough, just return original
        guard maxDimension > dimension else { return self }

        let scale = dimension / maxDimension
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.8)
        self.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resizedImage ?? self
    }
}


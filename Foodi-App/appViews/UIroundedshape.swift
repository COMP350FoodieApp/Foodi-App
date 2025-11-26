//
//  UIroundedshape.swift
//  Foodi
//
//  Created by Tyler Hedberg on 11/25/25.
//

import SwiftUI
import UIKit

struct RoundedCornerShape: Shape {
    var corners: UIRectCorner
    var radius: CGFloat

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

//
//  FoodiHeader.swift
//  Foodi
//
//  Created by d-rod on 10/29/25.
//

import SwiftUI


struct FoodiHeader: View {
    // Actions
    var onProfile: () -> Void = {}
    var onSettings: () -> Void = {}
    var onBack: (() -> Void)? = nil          
    // Appearance
    var bannerColor: Color = .foodiBlue
    var titleSize: CGFloat = 22
    var titleWeight: Font.Weight = .bold
    var titleText: String = "Foodi"

    var body: some View {
        let iconColor: Color = .white

        HStack(spacing: 12) {
            // Back chevron if onBack provided
            if let onBack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .imageScale(.large)
                        .foregroundStyle(iconColor)
                        .padding(.trailing, 2)
                }
                .buttonStyle(.plain)
            }

            // Title
            Text(titleText)
                .font(.system(size: titleSize, weight: titleWeight))
                .foregroundColor(.white)

            Spacer(minLength: 0)

            // Right: gear + profile
            HStack(spacing: 18) {
                Button(action: onSettings) {
                    Image(systemName: "gearshape")
                        .imageScale(.large)
                        .foregroundStyle(iconColor)
                        .accessibilityLabel("Settings")
                }
                .buttonStyle(.plain)

                Button(action: onProfile) {
                    Image(systemName: "person.crop.circle")
                        .imageScale(.large)
                        .foregroundStyle(iconColor)
                        .accessibilityLabel("Profile")
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 10)
        .background(bannerColor)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.white.opacity(0.15)).frame(height: 0.5)
        }
    }
}


extension FoodiHeader {
    init(
        bannerColor: Color = .foodiBlue,
        titleText: String = "Foodi",
        titleSize: CGFloat = 22,
        titleWeight: Font.Weight = .bold,
        onBack: (() -> Void)? = nil,
        onProfile: @escaping () -> Void = {},
        onSettings: @escaping () -> Void = {}
    ) {
        self.bannerColor = bannerColor
        self.titleText = titleText
        self.titleSize = titleSize
        self.titleWeight = titleWeight
        self.onBack = onBack
        self.onProfile = onProfile
        self.onSettings = onSettings
    }
}

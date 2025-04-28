//
//  AppColors.swift
//  WebexConnectDemo
//

import Foundation
import SwiftUICore

/// A struct that defines a collection of colors used in the application.
struct AppColors {
    static let profileConnectionGreenColor = Color(red: 39 / 255, green: 161 / 255, blue: 122 / 255, opacity: 1.0)
    static let whiteOpacity95 = Color.white.opacity(0.95)
    static let whiteOpacity60 = Color.white.opacity(0.6)
    static let whiteOpacity70 = Color.white.opacity(0.7)
    
    static let blackOpacity95 = Color.black.opacity(0.95)
    
    static let grayOpacity30 = Color.gray.opacity(0.3)
    
    static let signoutRed = Color(red: 252 / 255, green: 139 / 255, blue: 152 / 255, opacity: 1)
    static let connectionColor = Color(red: 159/255, green: 237/255, blue: 216/255, opacity: 1.0)
    static let connectionBackgroundColor = Color(red: 159/255, green: 237/255, blue: 216/255, opacity: 1.0)
    static let profileAvatarColor = Color(red: 39 / 255, green: 161 / 255, blue: 122 / 255, opacity: 1.0)
    
    static let newMessageBlueBackgroundColor = Color(red: 17/255, green: 112/255, blue: 207/255)
    
    static let connectedBackgroundColor = Color(red: 14/255, green: 43/255, blue: 32/255, opacity: 1.0)
    static let connectingColor = Color(red: 255/255, green: 212/255, blue: 218/255, opacity: 1.0)
    static let connectingBackgroundColor = Color(red: 54/255, green: 34/255, blue: 12/255, opacity: 1.0)
    static let disconnectedBackgroundColor = Color(red: 79/255, green: 14/255, blue: 16/255, opacity: 1.0)
}

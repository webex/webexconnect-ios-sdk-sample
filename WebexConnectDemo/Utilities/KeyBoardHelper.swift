//
//  KeyBoardHelper.swift
//  WebexConnectDemo
//

#if canImport(UIKit)
import UIKit

/// Utility method to hide the keyboard in SwiftUI by resigning first responder status.
func hideKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                    to: nil, from: nil, for: nil)
}
#endif

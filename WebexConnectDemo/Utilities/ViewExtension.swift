import Foundation
import SwiftUI

/// A SwiftUI View extension to add placeholder functionality and alert presentation.
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            if shouldShow {
                placeholder()
            }
            self
        }
    }
}

extension View {
    func alert(isPresented: Binding<Bool>, alertViewModel: AlertViewModel) -> some View {
        alert(isPresented: isPresented) {
            Alert(
                title: Text(alertViewModel.title),
                message: Text(alertViewModel.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

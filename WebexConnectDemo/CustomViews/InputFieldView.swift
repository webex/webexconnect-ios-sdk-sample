//
//  InputFieldView.swift
//  WebexConnectDemo
//

import SwiftUI

struct InputFieldView: View {
    @Binding var text: String
    var placeholder: String
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Background Rounded Rectangle
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray, lineWidth: 1)
                .frame(height: 60) // Fixed height for consistent styling
            
            Text(placeholder)
                .font(AppFonts.sfProRegular13)
                .foregroundColor(AppColors.whiteOpacity95)
                .background(Color(.clear)) // Match the background for cleaner look
                .padding(.horizontal, 10)
                .padding(.vertical, 0)
                .offset(y: -10) // Move up when text is not empty
            
            // TextField for user input
            TextField("", text: $text)
                .font(AppFonts.sfProRegular17)
                .foregroundColor(AppColors.whiteOpacity95)
                .padding(.horizontal, 10)
                .padding(.vertical, 20)
                .offset(y: 10)
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
        .padding(.vertical, 10)
    }
}

struct InputFieldView_Previews: PreviewProvider {
    static var previews: some View {
        InputFieldView(text: .constant(""), placeholder: "Thread title (required)")
            .padding()
            .previewLayout(.sizeThatFits)
    }
}

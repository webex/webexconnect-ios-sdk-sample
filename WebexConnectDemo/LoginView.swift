//
//  LoginView.swift
//  WebexConnectDemo
import SwiftUI
import WebexConnectCore

/// Login screen where user provides their User ID for SDK registration.
/// This file defines the LoginView, the initial screen where users provide their User ID to register with the Webex Connect SDK.
///  It displays a login form with a text input for the user ID and a "Next" button to initiate SDK registration.
struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()  // Observed view model for state and logic

    var body: some View {
        ProgressView(isShowing: $viewModel.showLoading) {
            VStack(spacing: 20) {
                Spacer()

                // App Logo
                Image("webex-connect-logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 103, height: 73)

                // Title
                Text("Login")
                    .font(AppFonts.sfProRegular28)
                    .foregroundColor(AppColors.whiteOpacity95)

                Spacer()

                // Instructional text
                Text("Start by entering your user id.")
                    .font(AppFonts.sfProRegular14)
                    .foregroundColor(AppColors.whiteOpacity95)

                // Input field
                InputFieldView(text: $viewModel.userId, placeholder: "User id")
                    .padding(.horizontal, 15)

                // Button to trigger registration
                Button(action: {
                    viewModel.startRegistration()
                }) {
                    Text("Next")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .font(AppFonts.sfProBold17)
                        .foregroundColor(AppColors.blackOpacity95)
                        .background(AppColors.whiteOpacity95)
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                        .padding(.horizontal, 40)
                }

                Spacer()
                Spacer()
                Spacer()

                // Footer branding
                Text("Webex")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.whiteOpacity95)
                + Text(" Connect")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.whiteOpacity95)
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .alert(item: $viewModel.alertModel) { alert in
                Alert(title: Text(alert.title), message: Text(alert.message), dismissButton: .default(Text("OK")))
            }
            .fullScreenCover(isPresented: $viewModel.showConversationsView) {
                HomeView()
            }
        }
    }
}
#Preview {
    LoginView()
}

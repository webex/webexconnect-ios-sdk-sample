//
//  ProfileView.swift
//  WebexConnectDemo
import SwiftUI
import WebexConnectCore

/// Created to display user profile information, app version, and sign-out option.
///  ProfileView provides:
///  - Display of the signed-in user's ID and avatar.
///  - Quick navigation to Notifications and Messages tabs within the app.
///  - Display of the Webex Connect SDK version.
///  - Option for the user to sign out.
struct ProfileView: View {
    // MARK: - Properties
    
    let userId: String               // Current signed-in user ID
    let sdkVersion: String           // SDK version to display
    let onDismiss: () -> Void        // Closure to handle dismiss action
    @Binding var isUserSignedIn: Bool // Tracks user sign-in status
    @Binding var selectedTab: Int    // Controls the selected tab in the parent view
    
    @SwiftUI.Environment(\.dismiss) var dismiss // Dismiss environment action

    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    // MARK: - Body
    
    var body: some View {
        VStack {
            // Profile Section with background image, close button, profile picture, and user ID
            ZStack(alignment: .top) {
                backgroundHeader
                profileContent
            }
            .padding(.bottom, 24)

            // Profile Options Section: Notifications, Messages, SDK Version
            profileOptionsSection

            // Sign Out Button
            signOutButton

            Spacer()
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Error"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .overlay(
            Group {
                if isLoading {
                    ActivityIndicator(isAnimating: $isLoading, style: .large)
                        .frame(width: 50, height: 50)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(10)
                }
            }
        )
        .padding()
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
    
    // MARK: - Components

    private var backgroundHeader: some View {
        Image("wallpaper")
            .resizable()
            .scaledToFill()
            .frame(height: 150)
            .clipShape(RoundedCorner(radius: 20, corners: [.topLeft, .topRight]))
    }
    
    private var profileContent: some View {
        VStack(spacing: 12) {
            HStack {
                // Close Button
                Button(action: onDismiss) {
                    Image("close_button")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                }
                .padding(.trailing)
                .offset(x: 60, y: 15)
                Spacer()
            }

            VStack(spacing: 12) {
                ZStack(alignment: .bottomTrailing) {
                    // Profile Avatar
                    Image("Avatar")
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                        .frame(width: 80, height: 80)

                    // Online Status Indicator
                    Circle()
                        .foregroundColor(AppColors.profileConnectionGreenColor)
                        .frame(width: 16, height: 16)
                        .offset(x: -8, y: -8)
                }
                
                // User ID Display
                Text("User ID: \(userId)")
                    .font(AppFonts.sfProBold17)
                    .foregroundColor(AppColors.whiteOpacity95)
            }
            .padding(.top, 100)
        }
    }
    
    private var profileOptionsSection: some View {
        VStack(spacing: 16) {
            // Notifications and Messages Section
            SectionContainer {
                ProfileRow(title: "Notifications", value: nil)
                    .onTapGesture {
                        selectedTab = 1
                        dismiss()
                    }
                Divider().background(AppColors.whiteOpacity70)
                ProfileRow(title: "Messages", value: nil)
                    .onTapGesture {
                        selectedTab = 0
                        dismiss()
                    }
            }
            .padding([.leading, .trailing], 16)
            
            // SDK Version Display Section
            SectionContainer {
                ProfileRow(title: "SDK version", value: sdkVersion, valueColor: .blue)
            }
            .padding([.leading, .trailing], 16)
        }
        .padding(.horizontal)
    }
    
    private var signOutButton: some View {
        Button(action: signOut) {
            Text("Sign Out")
                .font(AppFonts.sfProRegular17)
                .foregroundColor(AppColors.signoutRed)
                .padding()
        }
        .padding(.top, 16)
    }

    // MARK: - Actions

    /// Signs out the user and dismisses the view
    func signOut() {
        isLoading = true
        WebexConnectProvider.instance.unregister { response, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error  {
                    alertMessage = "Failed to unregister: \(error.localizedDescription)"
                    showAlert = true
                    isUserSignedIn = true
                } else {
                    isUserSignedIn = false
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Section Container

/// A reusable container view that applies background and corner radius styling for sections.
struct SectionContainer<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(AppColors.grayOpacity30)
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Profile Row

/// A reusable row view to display a title and an optional value.
struct ProfileRow: View {
    let title: String
    let value: String?
    var valueColor: Color = .white

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.white)
            Spacer()
            if let value = value {
                Text(value)
                    .font(.body)
                    .foregroundColor(valueColor)
            }
        }
        .padding()
    }
}

// MARK: - Preview

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView(
            userId: "213424",
            sdkVersion: "3.0.0",
            onDismiss: {},
            isUserSignedIn: .constant(true),
            selectedTab: .constant(0)
        )
        .previewLayout(.sizeThatFits)
        .background(Color.black)
    }
}

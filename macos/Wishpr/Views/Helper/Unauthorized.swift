import SwiftUI

struct Unauthorized: View {
    var body: some View {
        VStack() {
            Spacer()
            VStack {
                Text("No screen recording permission.")
                    .font(.largeTitle)
                    .padding(.top)
                Text("Open System Settings and go to Privacy & Security > Screen Recording to grant permission.")
                    .font(.title2)
                    .padding(.bottom)
            }
            .frame(maxWidth: .infinity)
            .background(.red)
            
        }
    }
}

#Preview {
    Unauthorized()
}

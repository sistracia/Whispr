import SwiftUI

struct Unauthorized: View {
    var body: some View {
        VStack() {
            Spacer()
            VStack {
                Text("Permission Required")
                    .font(.largeTitle)
                    .padding(.top)
                Text("""
Open System Settings and grant the permission, go to:
1. Privacy & Security > Screen Recording.
2. Privacy & Security > Microphone.
""")
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

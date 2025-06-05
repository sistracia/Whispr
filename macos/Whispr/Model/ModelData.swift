import SwiftUI

@MainActor
class ModelData: ObservableObject {
    @Published var notes: [Note] = []
}

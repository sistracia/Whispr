import SwiftUI

extension View {
    func tag<V>(_ tag: V, selectable: Bool) -> some View where V : Hashable {
        Group {
            if selectable == true {
                self.tag(tag)
            } else {
                self.foregroundColor(.secondary)
            }
        }
    }
}

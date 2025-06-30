import SwiftUI

struct NoteVoiceMeter<
    LabelContent: View,
    ButtonContent: View,
    PopoverContent: View
>: View {
    var state: StreamState
    @StateObject var audioLevelsProvider: AudioLevelsProvider

    @ViewBuilder var label: LabelContent
    @ViewBuilder var button: ButtonContent
    @ViewBuilder var popover: PopoverContent

    @State private var isShowingPopover: Bool = false

    var body: some View {
        return VStack(alignment: .leading) {
            HStack {
                label
                if state == .streaming
                    && audioLevelsProvider.audioLevels.level.isZero
                {
                    Button {
                        isShowingPopover = true
                    } label: {
                        button
                    }
                    .foregroundStyle(.red)
                    .buttonStyle(.borderless)
                    .popover(
                        isPresented: $isShowingPopover,
                        arrowEdge: .bottom
                    ) {
                        popover
                            .padding()
                    }
                    .labelsVisibility(.hidden)
                }
            }
            AudioLevelsView(
                audioLevelsProvider: audioLevelsProvider
            )
        }
    }
}

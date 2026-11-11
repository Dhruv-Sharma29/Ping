import SwiftUI

/// Last row of a paged list: loads older issues when scrolled into view, or on tap.
struct LoadMoreRow: View {
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        HStack {
            Spacer()
            if isLoading {
                ProgressView()
            } else {
                Button("Load Older Issues", systemImage: "arrow.down.circle", action: action)
            }
            Spacer()
        }
        .frame(minHeight: 44)
        .onAppear(perform: action)
    }
}

import SwiftUI
import UIKit

struct HeaderView: View {
    let title: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.title)
                .bold()
                .foregroundColor(.white)
            Text(description)
                .font(.subheadline)
                .foregroundColor(Color.white.opacity(0.95))
            Text("For Educational Purpose Only")
                .font(.subheadline)
                .bold()
                .foregroundColor(Color(red: 255/255, green: 153/255, blue: 102/255))
        }
        // Add top inset so header content sits below the status bar/notch
        .padding(EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 102/255, green: 126/255, blue: 234/255), // #667eea
                    Color(red: 118/255, green: 75/255, blue: 162/255)   // #764ba2
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        // Measure and publish our height so parent views can offset content dynamically.
        .background(
            GeometryReader { geo in
                Color.clear
                    .preference(key: HeaderHeightKey.self, value: geo.size.height)
            }
        )
    }
}

/// PreferenceKey used to report header height to ancestor views.
struct HeaderHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        // Keep the largest measured value (should be stable)
        value = max(value, nextValue())
    }
}

#Preview {
    HeaderView(title: "Signals", description: "Live signal data and metrics")
        .previewLayout(.sizeThatFits)
}

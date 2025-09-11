import SwiftUI

/// メディア選択モードの切り替えボタン
struct MediaSelectionModeButton: View {
    // MARK: - Properties
    
    let isSelectionMode: Bool
    let action: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        Button(action: action) {
            Text(buttonTitle)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .fixedSize()
                .animation(.none, value: buttonTitle)
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
    }
    
    // MARK: - Private Properties
    
    private var buttonTitle: String {
        if isSelectionMode {
            String(localized: "Cancel", bundle: .module)
        } else {
            String(localized: "Select", bundle: .module)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        MediaSelectionModeButton(isSelectionMode: false) {}
        MediaSelectionModeButton(isSelectionMode: true) {}
    }
    .padding()
}

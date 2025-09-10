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
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
        .animation(.easeInOut(duration: 0.2), value: isSelectionMode)
    }
    
    // MARK: - Private Properties
    
    private var buttonTitle: String {
        if isSelectionMode {
            return NSLocalizedString("Done", bundle: .module, comment: "")
        } else {
            return NSLocalizedString("Edit", bundle: .module, comment: "")
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

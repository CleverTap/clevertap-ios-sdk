import SwiftUI

extension View {
    func roundedBorder() -> some View {
        return self.overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary, lineWidth: 1)
        ).textFieldStyle(.roundedBorder)
    }
    
    func buttonStyle() -> some View {
        return self.padding()
            .frame(maxWidth: .infinity)
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(8)
    }
}

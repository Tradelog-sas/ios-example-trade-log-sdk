import SwiftUI
import TradelogSupport

struct ContentView: View {
    @State private var showSupport = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)

            Text("Tradelog Demo")
                .font(.largeTitle.bold())

            Text("Prueba de integración del SDK de soporte.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            Button {
                showSupport = true
            } label: {
                Label("Abrir soporte", systemImage: "message.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
        .padding()
        // Abre el SDK de Tradelog como hoja modal.
        .sheet(isPresented: $showSupport) {
            SupportChatView(isPresented: $showSupport)
        }
    }
}

/// Contenedor del chat de soporte de Tradelog.
struct SupportChatView: View {
    @Binding var isPresented: Bool

    var body: some View {
        TradeLogSwiftUIContainer(
            onCloseRequested: { isPresented = false },
            onBackButtonRequested: { isPresented = false }
        )
        .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}

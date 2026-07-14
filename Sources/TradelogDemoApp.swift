import SwiftUI
import TradelogSupport

@main
struct TradelogDemoApp: App {

    init() {
        Self.configureTradeLog()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }

    /// Inicializa el SDK de Tradelog al arrancar la app.
    /// Los valores salen de `AppConfig` (generado desde `.env` por el Makefile).
    private static func configureTradeLog() {
        let options = TradeLogSdkOptions(
            apiKey: AppConfig.apiKey,
            tenantId: AppConfig.tenantId,
            environment: AppConfig.environment.lowercased() == "production" ? .production : .staging,
            enableLogs: AppConfig.enableLogs,
            officialModules: [.logger, .userInfo],
            initialCustomerName: AppConfig.customerName,
            initialCustomerData: AppConfig.customerData,
            uiConfigurationCacheDurationSeconds: 60
        )

        do {
            try TradeLogSdk.initialize(options: options)
        } catch {
            print("⚠️ TradeLog SDK init falló: \(error)")
        }
    }
}

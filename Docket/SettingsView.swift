import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: DocketStore
    @EnvironmentObject private var purchases: PurchaseManager
    @AppStorage("docket_low_stock_alerts") private var lowStockAlerts: Bool = true
    @AppStorage("docket_default_threshold") private var defaultThreshold: Int = 2
    @State private var activeSheet: DocketSheet?
    @State private var showResetConfirm = false
    @State private var restoreMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Low Stock Alerts") {
                    Toggle("Show low stock banner", isOn: $lowStockAlerts)
                        .accessibilityIdentifier("lowStockAlertsToggle")

                    Stepper("Default threshold: \(defaultThreshold)", value: $defaultThreshold, in: 0...20)
                        .accessibilityIdentifier("defaultThresholdStepper")
                }

                Section("Docket Pro") {
                    if purchases.isPro {
                        Label("Pro unlocked", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(DKTheme.chalkGreen)
                    } else {
                        Button("Upgrade to Pro") {
                            activeSheet = .paywall
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("upgradeProButton")
                    }
                    Button("Restore Purchases") {
                        Task {
                            await purchases.restore()
                            restoreMessage = purchases.isPro ? "Purchases restored." : "No purchases found."
                        }
                    }
                    .buttonStyle(.plain)
                    if let restoreMessage {
                        Text(restoreMessage)
                            .font(.caption)
                            .foregroundStyle(DKTheme.inkFaded)
                    }
                }

                Section("About") {
                    Link("Privacy Policy", destination: URL(string: "https://shimondeitel.github.io/docket-site/privacy.html")!)
                    Link("Contact Support", destination: URL(string: "mailto:s0533495227@gmail.com")!)
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0")
                            .foregroundStyle(DKTheme.inkFaded)
                    }
                }

                Section {
                    Button("Reset All Data", role: .destructive) {
                        showResetConfirm = true
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Settings")
            .dismissKeyboardOnTap()
            .confirmationDialog(
                "Reset all supply items and history?",
                isPresented: $showResetConfirm,
                titleVisibility: .visible
            ) {
                Button("Reset", role: .destructive) {
                    store.deleteAllData()
                }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .paywall:
                    PaywallView()
                default:
                    EmptyView()
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(DocketStore())
        .environmentObject(PurchaseManager())
}

import SwiftUI

@main
struct DocketApp: App {
    @StateObject private var store = DocketStore()
    @StateObject private var purchases = PurchaseManager()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(store)
                .environmentObject(purchases)
        }
    }
}

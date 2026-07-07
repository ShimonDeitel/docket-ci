import Foundation
import Combine

@MainActor
final class DocketStore: ObservableObject {
    @Published private(set) var items: [SupplyItem] = []
    @Published private(set) var logEntries: [SupplyLogEntry] = []

    static let freeItemLimit = 5

    private let fileURL: URL

    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.fileURL = dir.appendingPathComponent("docket_data.json")
        if ProcessInfo.processInfo.arguments.contains("-uiTestReset") {
            try? FileManager.default.removeItem(at: fileURL)
        }
        load()
        if items.isEmpty {
            seedDefaults()
        }
    }

    private func seedDefaults() {
        items = [
            SupplyItem(name: "Pencils (box of 12)", category: "Writing", totalQuantity: 10, usedQuantity: 3, lowStockThreshold: 2),
            SupplyItem(name: "Notebooks", category: "Paper", totalQuantity: 8, usedQuantity: 6, lowStockThreshold: 2),
            SupplyItem(name: "Glue Sticks", category: "Art", totalQuantity: 6, usedQuantity: 1, lowStockThreshold: 1)
        ]
        logEntries = []
        save()
    }

    func canAddItem(isPro: Bool) -> Bool {
        isPro || items.count < Self.freeItemLimit
    }

    @discardableResult
    func addItem(name: String, category: String, totalQuantity: Int, lowStockThreshold: Int, isPro: Bool) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, totalQuantity > 0, canAddItem(isPro: isPro) else { return false }
        let item = SupplyItem(name: trimmed, category: category, totalQuantity: totalQuantity, lowStockThreshold: lowStockThreshold)
        items.append(item)
        logEntries.append(SupplyLogEntry(itemID: item.id, delta: totalQuantity, note: "Initial stock"))
        save()
        return true
    }

    func updateItem(_ id: UUID, name: String, category: String, totalQuantity: Int, lowStockThreshold: Int) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, totalQuantity > 0, let idx = items.firstIndex(where: { $0.id == id }) else { return }
        items[idx].name = trimmed
        items[idx].category = category
        items[idx].totalQuantity = totalQuantity
        items[idx].lowStockThreshold = lowStockThreshold
        save()
    }

    func deleteItem(_ id: UUID) {
        items.removeAll { $0.id == id }
        logEntries.removeAll { $0.itemID == id }
        save()
    }

    /// Mark one unit as used (decrements remaining, increments usedQuantity).
    func markUsed(_ id: UUID, count: Int = 1, note: String = "") {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        items[idx].usedQuantity = min(items[idx].totalQuantity, items[idx].usedQuantity + count)
        logEntries.append(SupplyLogEntry(itemID: id, delta: -count, note: note))
        save()
    }

    /// Restock: adds to total quantity (new supplies purchased).
    func restock(_ id: UUID, count: Int, note: String = "") {
        guard let idx = items.firstIndex(where: { $0.id == id }), count > 0 else { return }
        items[idx].totalQuantity += count
        logEntries.append(SupplyLogEntry(itemID: id, delta: count, note: note.isEmpty ? "Restocked" : note))
        save()
    }

    func deleteAllData() {
        items = []
        logEntries = []
        seedDefaults()
    }

    // MARK: - Derived

    var lowStockItems: [SupplyItem] {
        items.filter(\.isLowStock)
    }

    func logEntries(for itemID: UUID) -> [SupplyLogEntry] {
        logEntries.filter { $0.itemID == itemID }.sorted { $0.date > $1.date }
    }

    /// Quirky signature stat: overall "supply health" score, 0-100, the
    /// average remaining-fraction across all items — a single number that
    /// tells you at a glance how well-stocked the whole classroom is.
    var supplyHealthScore: Int {
        guard !items.isEmpty else { return 100 }
        let avgRemainingFraction = items.reduce(0.0) { $0 + (1 - $1.usedFraction) } / Double(items.count)
        return Int((avgRemainingFraction * 100).rounded())
    }

    // MARK: - Persistence

    private struct Snapshot: Codable {
        var items: [SupplyItem]
        var logEntries: [SupplyLogEntry]
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        if let decoded = try? JSONDecoder().decode(Snapshot.self, from: data) {
            items = decoded.items
            logEntries = decoded.logEntries
        }
    }

    func save() {
        let snapshot = Snapshot(items: items, logEntries: logEntries)
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}

import Foundation

/// A school supply item tracked by total quantity purchased and quantity
/// used so far — the core "used vs remaining" concept.
struct SupplyItem: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var category: String   // e.g. "Paper", "Writing", "Art"
    var totalQuantity: Int
    var usedQuantity: Int
    var lowStockThreshold: Int

    init(
        id: UUID = UUID(),
        name: String,
        category: String,
        totalQuantity: Int,
        usedQuantity: Int = 0,
        lowStockThreshold: Int = 2
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.totalQuantity = totalQuantity
        self.usedQuantity = usedQuantity
        self.lowStockThreshold = lowStockThreshold
    }

    var remainingQuantity: Int { max(0, totalQuantity - usedQuantity) }

    var usedFraction: Double {
        guard totalQuantity > 0 else { return 0 }
        return min(1.0, Double(usedQuantity) / Double(totalQuantity))
    }

    var isLowStock: Bool { remainingQuantity <= lowStockThreshold }
    var isDepleted: Bool { remainingQuantity <= 0 }
}

/// A restock or usage log entry (Pro feature: full history per item).
struct SupplyLogEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var itemID: UUID
    var delta: Int   // positive = restocked, negative = used
    var date: Date
    var note: String

    init(id: UUID = UUID(), itemID: UUID, delta: Int, date: Date = Date(), note: String = "") {
        self.id = id
        self.itemID = itemID
        self.delta = delta
        self.date = date
        self.note = note
    }
}

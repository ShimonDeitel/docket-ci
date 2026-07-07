import XCTest
@testable import Docket

final class DocketTests: XCTestCase {
    var store: DocketStore!

    @MainActor
    override func setUp() {
        super.setUp()
        store = DocketStore()
        store.deleteAllData()
        for i in store.items { store.deleteItem(i.id) }
    }

    @MainActor
    func testAddItem() {
        let added = store.addItem(name: "Erasers", category: "Writing", totalQuantity: 5, lowStockThreshold: 1, isPro: false)
        XCTAssertTrue(added)
        XCTAssertEqual(store.items.count, 1)
        XCTAssertEqual(store.items[0].remainingQuantity, 5)
    }

    @MainActor
    func testAddItemRejectsEmptyName() {
        let added = store.addItem(name: "  ", category: "Writing", totalQuantity: 5, lowStockThreshold: 1, isPro: false)
        XCTAssertFalse(added)
    }

    @MainActor
    func testAddItemRejectsZeroQuantity() {
        let added = store.addItem(name: "Erasers", category: "Writing", totalQuantity: 0, lowStockThreshold: 1, isPro: false)
        XCTAssertFalse(added)
    }

    @MainActor
    func testFreeLimitBlocksSixthItem() {
        for i in 0..<5 {
            _ = store.addItem(name: "Item\(i)", category: "Writing", totalQuantity: 5, lowStockThreshold: 1, isPro: false)
        }
        XCTAssertFalse(store.canAddItem(isPro: false))
        let sixth = store.addItem(name: "Extra", category: "Writing", totalQuantity: 5, lowStockThreshold: 1, isPro: false)
        XCTAssertFalse(sixth)
        XCTAssertEqual(store.items.count, 5)
    }

    @MainActor
    func testProAllowsUnlimitedItems() {
        for i in 0..<6 {
            _ = store.addItem(name: "Item\(i)", category: "Writing", totalQuantity: 5, lowStockThreshold: 1, isPro: true)
        }
        XCTAssertEqual(store.items.count, 6)
    }

    @MainActor
    func testMarkUsedIncrementsUsedQuantity() {
        _ = store.addItem(name: "Erasers", category: "Writing", totalQuantity: 5, lowStockThreshold: 1, isPro: false)
        let id = store.items[0].id
        store.markUsed(id)
        XCTAssertEqual(store.items[0].usedQuantity, 1)
        XCTAssertEqual(store.items[0].remainingQuantity, 4)
    }

    @MainActor
    func testMarkUsedCannotExceedTotal() {
        _ = store.addItem(name: "Erasers", category: "Writing", totalQuantity: 2, lowStockThreshold: 1, isPro: false)
        let id = store.items[0].id
        store.markUsed(id, count: 5)
        XCTAssertEqual(store.items[0].usedQuantity, 2)
        XCTAssertEqual(store.items[0].remainingQuantity, 0)
        XCTAssertTrue(store.items[0].isDepleted)
    }

    @MainActor
    func testRestockIncreasesTotalQuantity() {
        _ = store.addItem(name: "Erasers", category: "Writing", totalQuantity: 5, lowStockThreshold: 1, isPro: false)
        let id = store.items[0].id
        store.markUsed(id, count: 4)
        store.restock(id, count: 10)
        XCTAssertEqual(store.items[0].totalQuantity, 15)
        XCTAssertEqual(store.items[0].remainingQuantity, 11)
    }

    @MainActor
    func testRestockIgnoresZeroOrNegative() {
        _ = store.addItem(name: "Erasers", category: "Writing", totalQuantity: 5, lowStockThreshold: 1, isPro: false)
        let id = store.items[0].id
        store.restock(id, count: 0)
        XCTAssertEqual(store.items[0].totalQuantity, 5)
    }

    @MainActor
    func testIsLowStock() {
        _ = store.addItem(name: "Glue", category: "Art", totalQuantity: 5, lowStockThreshold: 2, isPro: false)
        let id = store.items[0].id
        XCTAssertFalse(store.items[0].isLowStock)
        store.markUsed(id, count: 4)
        XCTAssertTrue(store.items[0].isLowStock)
    }

    @MainActor
    func testLowStockItemsFiltersCorrectly() {
        _ = store.addItem(name: "Low", category: "Writing", totalQuantity: 2, lowStockThreshold: 5, isPro: false)
        _ = store.addItem(name: "High", category: "Writing", totalQuantity: 20, lowStockThreshold: 2, isPro: false)
        let lows = store.lowStockItems.map(\.name)
        XCTAssertTrue(lows.contains("Low"))
        XCTAssertFalse(lows.contains("High"))
    }

    @MainActor
    func testDeleteItemAlsoDeletesLogEntries() {
        _ = store.addItem(name: "Erasers", category: "Writing", totalQuantity: 5, lowStockThreshold: 1, isPro: false)
        let id = store.items[0].id
        XCTAssertFalse(store.logEntries.isEmpty)
        store.deleteItem(id)
        XCTAssertTrue(store.items.isEmpty)
        XCTAssertTrue(store.logEntries.isEmpty)
    }

    @MainActor
    func testUsedFractionComputation() {
        _ = store.addItem(name: "Notebooks", category: "Paper", totalQuantity: 10, lowStockThreshold: 2, isPro: false)
        let id = store.items[0].id
        store.markUsed(id, count: 3)
        XCTAssertEqual(store.items[0].usedFraction, 0.3, accuracy: 0.001)
    }

    @MainActor
    func testSupplyHealthScoreAllFull() {
        _ = store.addItem(name: "A", category: "Writing", totalQuantity: 10, lowStockThreshold: 1, isPro: true)
        XCTAssertEqual(store.supplyHealthScore, 100)
    }

    @MainActor
    func testSupplyHealthScoreDropsWithUsage() {
        _ = store.addItem(name: "A", category: "Writing", totalQuantity: 10, lowStockThreshold: 1, isPro: true)
        let id = store.items[0].id
        store.markUsed(id, count: 5)
        XCTAssertEqual(store.supplyHealthScore, 50)
    }

    @MainActor
    func testDeleteAllDataReseeds() {
        _ = store.addItem(name: "Extra", category: "Writing", totalQuantity: 5, lowStockThreshold: 1, isPro: true)
        store.deleteAllData()
        XCTAssertFalse(store.items.isEmpty)
    }
}

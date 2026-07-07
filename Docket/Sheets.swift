import SwiftUI

enum DocketSheet: Identifiable {
    case addItem
    case editItem(SupplyItem)
    case restock(SupplyItem)
    case paywall

    var id: String {
        switch self {
        case .addItem: return "addItem"
        case .editItem(let i): return "edit-\(i.id)"
        case .restock(let i): return "restock-\(i.id)"
        case .paywall: return "paywall"
        }
    }
}

struct ItemFormView: View {
    @EnvironmentObject private var store: DocketStore
    @EnvironmentObject private var purchases: PurchaseManager
    @Environment(\.dismiss) private var dismiss

    let existing: SupplyItem?

    @State private var name: String
    @State private var category: String
    @State private var totalQuantityText: String
    @State private var lowStockThresholdText: String

    init(existing: SupplyItem?) {
        self.existing = existing
        _name = State(initialValue: existing?.name ?? "")
        _category = State(initialValue: existing?.category ?? "Writing")
        _totalQuantityText = State(initialValue: existing.map { String($0.totalQuantity) } ?? "10")
        _lowStockThresholdText = State(initialValue: existing.map { String($0.lowStockThreshold) } ?? "2")
    }

    private var isEditing: Bool { existing != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Supply Item") {
                    TextField("Name (e.g. Pencils)", text: $name)
                        .accessibilityIdentifier("itemNameField")
                    TextField("Category (e.g. Writing)", text: $category)
                        .accessibilityIdentifier("itemCategoryField")
                    TextField("Total quantity", text: $totalQuantityText)
                        .keyboardType(.numberPad)
                        .accessibilityIdentifier("itemTotalQuantityField")
                    TextField("Low stock threshold", text: $lowStockThresholdText)
                        .keyboardType(.numberPad)
                        .accessibilityIdentifier("itemLowStockField")
                }

                if isEditing {
                    Section {
                        Button("Delete Item", role: .destructive) {
                            if let existing {
                                store.deleteItem(existing.id)
                            }
                            dismiss()
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("deleteItemButton")
                    }
                }
            }
            .dismissKeyboardOnTap()
            .navigationTitle(isEditing ? "Edit Item" : "New Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .buttonStyle(.plain)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        let total = Int(totalQuantityText) ?? 0
                        let threshold = Int(lowStockThresholdText) ?? 0
                        if isEditing, let existing {
                            store.updateItem(existing.id, name: name, category: category, totalQuantity: total, lowStockThreshold: threshold)
                        } else {
                            store.addItem(name: name, category: category, totalQuantity: total, lowStockThreshold: threshold, isPro: purchases.isPro)
                        }
                        dismiss()
                    }
                    .buttonStyle(.plain)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || Int(totalQuantityText) == nil)
                    .accessibilityIdentifier("saveItemButton")
                }
            }
        }
    }
}

struct RestockView: View {
    @EnvironmentObject private var store: DocketStore
    @Environment(\.dismiss) private var dismiss

    let item: SupplyItem

    @State private var countText: String = "10"
    @State private var note: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Restock \(item.name)") {
                    TextField("Quantity added", text: $countText)
                        .keyboardType(.numberPad)
                        .accessibilityIdentifier("restockCountField")
                }
                Section("Note (optional)") {
                    TextField("e.g. bought at Target", text: $note)
                        .accessibilityIdentifier("restockNoteField")
                }
            }
            .dismissKeyboardOnTap()
            .navigationTitle("Restock")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .buttonStyle(.plain)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let count = Int(countText) {
                            store.restock(item.id, count: count, note: note)
                        }
                        dismiss()
                    }
                    .buttonStyle(.plain)
                    .disabled(Int(countText) == nil || (Int(countText) ?? 0) <= 0)
                    .accessibilityIdentifier("saveRestockButton")
                }
            }
        }
    }
}

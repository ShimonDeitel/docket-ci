import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: DocketStore
    @EnvironmentObject private var purchases: PurchaseManager
    @State private var activeSheet: DocketSheet?

    var body: some View {
        NavigationStack {
            ZStack {
                DKTheme.backdrop.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        HStack {
                            Text("Docket")
                                .font(DKTheme.titleFont)
                                .foregroundStyle(DKTheme.ink)
                            Spacer()
                            Button {
                                if store.canAddItem(isPro: purchases.isPro) {
                                    activeSheet = .addItem
                                } else {
                                    activeSheet = .paywall
                                }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundStyle(DKTheme.chalkGreen)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("addItemButton")
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 8)

                        healthGaugeCard

                        if !store.lowStockItems.isEmpty {
                            lowStockBanner
                        }

                        if store.items.isEmpty {
                            emptyState
                        } else {
                            itemsList
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .addItem:
                    ItemFormView(existing: nil)
                case .editItem(let item):
                    ItemFormView(existing: item)
                case .restock(let item):
                    RestockView(item: item)
                case .paywall:
                    PaywallView()
                }
            }
        }
    }

    /// Quirky signature feature: a literal chalkboard "Supply Health"
    /// gauge — a single 0-100 score (a gauge-style progress ring drawn
    /// like a piece of chalk arcing across a blackboard) summarizing how
    /// well-stocked the whole classroom's supplies are.
    private var healthGaugeCard: some View {
        HStack(spacing: 20) {
            ChalkGaugeView(score: store.supplyHealthScore)
                .frame(width: 88, height: 88)
                .accessibilityIdentifier("supplyHealthGauge")
                .accessibilityValue("\(store.supplyHealthScore) percent supply health")

            VStack(alignment: .leading, spacing: 6) {
                Text("SUPPLY HEALTH")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.75))
                    .tracking(1.0)
                Text("\(store.supplyHealthScore)%")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text(store.lowStockItems.isEmpty ? "All supplies well-stocked" : "\(store.lowStockItems.count) item(s) running low")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
            Spacer()
        }
        .padding(16)
        .background(DKTheme.chalkGreen)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 18)
    }

    private var lowStockBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(DKTheme.danger)
            Text(store.lowStockItems.map(\.name).joined(separator: ", "))
                .font(.caption.weight(.semibold))
                .foregroundStyle(DKTheme.danger)
                .lineLimit(2)
            Spacer()
        }
        .padding(12)
        .background(DKTheme.danger.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 18)
    }

    private var itemsList: some View {
        VStack(spacing: 10) {
            ForEach(store.items) { item in
                SupplyRow(
                    item: item,
                    onMarkUsed: { store.markUsed(item.id) },
                    onRestock: { activeSheet = .restock(item) },
                    onEdit: { activeSheet = .editItem(item) }
                )
            }
        }
        .padding(.horizontal, 18)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "pencil.and.ruler.fill")
                .font(.system(size: 48))
                .foregroundStyle(DKTheme.inkFaded)
            Text("No supplies yet")
                .font(DKTheme.headlineFont)
                .foregroundStyle(DKTheme.ink)
            Text("Add an item to start tracking used vs remaining.")
                .font(.subheadline)
                .foregroundStyle(DKTheme.inkFaded)
        }
        .padding(.top, 24)
        .padding(.horizontal, 18)
    }
}

/// A chalk-drawn circular gauge: an arc that fills proportional to the
/// supply health score, styled like chalk on a blackboard.
struct ChalkGaugeView: View {
    let score: Int

    private var fraction: Double { Double(max(0, min(100, score))) / 100 }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.25), lineWidth: 8)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(DKTheme.pencilYellow, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.6), value: fraction)
            Text("\(score)")
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
        }
    }
}

struct SupplyRow: View {
    let item: SupplyItem
    var onMarkUsed: () -> Void
    var onRestock: () -> Void
    var onEdit: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .top) {
                Button(action: onEdit) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name)
                            .font(DKTheme.headlineFont)
                            .foregroundStyle(DKTheme.ink)
                        Text(item.category)
                            .font(.caption)
                            .foregroundStyle(DKTheme.inkFaded)
                    }
                }
                .buttonStyle(.plain)
                Spacer()
                Text("\(item.remainingQuantity) left")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(item.isLowStock ? DKTheme.danger : DKTheme.chalkGreen)
                    .accessibilityIdentifier("remainingLabel_\(item.name)")
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(DKTheme.rule)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(item.isLowStock ? DKTheme.danger : DKTheme.pencilYellow)
                        .frame(width: geo.size.width * item.usedFraction)
                        .animation(.easeOut(duration: 0.4), value: item.usedFraction)
                }
            }
            .frame(height: 10)
            .accessibilityIdentifier("usedBar_\(item.name)")

            HStack {
                Text("\(item.usedQuantity) used of \(item.totalQuantity)")
                    .font(.caption2)
                    .foregroundStyle(DKTheme.inkFaded)
                Spacer()
                Button("Mark Used", action: onMarkUsed)
                    .buttonStyle(.plain)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DKTheme.chalkGreen)
                    .accessibilityIdentifier("markUsedButton_\(item.name)")
                Button("Restock", action: onRestock)
                    .buttonStyle(.plain)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DKTheme.pencilYellow)
                    .accessibilityIdentifier("restockButton_\(item.name)")
            }
        }
        .padding(12)
        .background(DKTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(DKTheme.rule, lineWidth: 1))
    }
}

#Preview {
    HomeView()
        .environmentObject(DocketStore())
        .environmentObject(PurchaseManager())
}

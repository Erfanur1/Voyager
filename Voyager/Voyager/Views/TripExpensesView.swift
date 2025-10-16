import SwiftUI
import CoreData

struct TripExpensesView: View {
    @ObservedObject var trip: Trip
    @State private var showingAddExpense = false
    
    var groupedExpenses: [String: [Expense]] {
        Dictionary(grouping: trip.expensesArray) { $0.category ?? "Other" }
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(.systemBackground), Color(.secondarySystemBackground).opacity(0.3)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            List {
                // Total Section
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Total Expenses")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text(String(format: "$%.2f", trip.totalExpenses))
                                .font(.system(size: 36, weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.green, .mint],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        }
                        
                        Spacer()
                        
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.green.opacity(0.2), .mint.opacity(0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 70, height: 70)
                            
                            Image(systemName: "dollarsign.circle.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.green, .mint],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                    }
                    .padding(.vertical, 12)
                    .listRowBackground(
                        LinearGradient(
                            colors: [.green.opacity(0.05), .mint.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                }
                
                if trip.expensesArray.isEmpty {
                    Section {
                        VStack(spacing: 24) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.orange.opacity(0.3), .yellow.opacity(0.3)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 100, height: 100)
                                
                                Image(systemName: "dollarsign.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.orange, .yellow],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                            
                            VStack(spacing: 8) {
                                Text("No Expenses Yet")
                                    .font(.title2)
                                    .bold()
                                
                                Text("Start tracking your trip spending")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Button("Add First Expense") {
                                showingAddExpense = true
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    colors: [.orange, .yellow],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(25)
                            .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                        .padding(.vertical, 40)
                    }
                } else {
                    ForEach(Array(groupedExpenses.keys.sorted()), id: \.self) { category in
                        Section {
                            ForEach(groupedExpenses[category] ?? [], id: \.self) { expense in
                                ColorfulExpenseRow(expense: expense)
                                    .listRowBackground(
                                        categoryColor(for: category).opacity(0.05)
                                    )
                            }
                        } header: {
                            HStack {
                                Image(systemName: categoryIcon(for: category))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: categoryGradient(for: category),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                Text(category)
                                    .font(.headline)
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddExpense = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
        }
        .sheet(isPresented: $showingAddExpense) {
            AddExpenseView(trip: trip)
        }
    }
    
    func categoryColor(for category: String) -> Color {
        switch category {
        case "Food & Dining": return .orange
        case "Transportation": return .blue
        case "Accommodation": return .purple
        case "Activities": return .pink
        case "Shopping": return .green
        default: return .gray
        }
    }
    
    func categoryGradient(for category: String) -> [Color] {
        switch category {
        case "Food & Dining": return [.orange, .red]
        case "Transportation": return [.blue, .cyan]
        case "Accommodation": return [.purple, .pink]
        case "Activities": return [.pink, .red]
        case "Shopping": return [.green, .mint]
        default: return [.gray, .secondary]
        }
    }
    
    func categoryIcon(for category: String) -> String {
        switch category {
        case "Food & Dining": return "fork.knife.circle.fill"
        case "Transportation": return "car.circle.fill"
        case "Accommodation": return "bed.double.circle.fill"
        case "Activities": return "star.circle.fill"
        case "Shopping": return "bag.circle.fill"
        default: return "circle.fill"
        }
    }
}

struct ColorfulExpenseRow: View {
    let expense: Expense
    
    var categoryColor: Color {
        switch expense.category {
        case "Food & Dining": return .orange
        case "Transportation": return .blue
        case "Accommodation": return .purple
        case "Activities": return .pink
        case "Shopping": return .green
        default: return .gray
        }
    }
    
    var categoryGradient: [Color] {
        switch expense.category {
        case "Food & Dining": return [.orange, .red]
        case "Transportation": return [.blue, .cyan]
        case "Accommodation": return [.purple, .pink]
        case "Activities": return [.pink, .red]
        case "Shopping": return [.green, .mint]
        default: return [.gray, .secondary]
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Category Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: categoryGradient.map { $0.opacity(0.2) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                
                Image(systemName: categoryIconName)
                    .foregroundStyle(
                        LinearGradient(
                            colors: categoryGradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            // Expense Details
            VStack(alignment: .leading, spacing: 6) {
                Text(expense.title ?? "Untitled")
                    .font(.headline)
                
                HStack(spacing: 8) {
                    if let date = expense.date {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption2)
                            Text(date, style: .date)
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    if let tripName = expense.trip?.name {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(tripName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            // Amount
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "$%.2f", expense.amount))
                    .font(.title3)
                    .bold()
                    .foregroundStyle(
                        LinearGradient(
                            colors: categoryGradient,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                if let currency = expense.currency, currency != "USD" {
                    Text(currency)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(categoryColor.opacity(0.2))
                        .foregroundColor(categoryColor)
                        .cornerRadius(4)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    var categoryIconName: String {
        switch expense.category {
        case "Food & Dining": return "fork.knife"
        case "Transportation": return "car.fill"
        case "Accommodation": return "bed.double.fill"
        case "Activities": return "star.fill"
        case "Shopping": return "bag.fill"
        default: return "circle.fill"
        }
    }
}

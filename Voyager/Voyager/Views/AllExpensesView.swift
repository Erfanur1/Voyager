import SwiftUI
import CoreData

struct AllExpensesView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Expense.date, ascending: false)],
        animation: .default)
    private var expenses: FetchedResults<Expense>
    
    var groupedExpenses: [String: [Expense]] {
        Dictionary(grouping: expenses) { expense in
            expense.category ?? "Other"
        }
    }
    
    var totalAmount: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.secondarySystemBackground).opacity(0.3)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                List {
                    // Total Section with Chart
                    Section {
                        VStack(spacing: 20) {
                            HStack {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Total Spending")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                    
                                    Text(String(format: "$%.2f", totalAmount))
                                        .font(.system(size: 42, weight: .bold))
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
                                        .frame(width: 80, height: 80)
                                    
                                    Image(systemName: "chart.pie.fill")
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
                            
                            // Category Breakdown
                            if !expenses.isEmpty {
                                VStack(spacing: 12) {
                                    ForEach(Array(groupedExpenses.keys.sorted()), id: \.self) { category in
                                        let categoryTotal = groupedExpenses[category]?.reduce(0) { $0 + $1.amount } ?? 0
                                        let percentage = (categoryTotal / totalAmount) * 100
                                        
                                        HStack(spacing: 12) {
                                            Image(systemName: categoryIcon(for: category))
                                                .foregroundStyle(
                                                    LinearGradient(
                                                        colors: categoryGradient(for: category),
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                                .frame(width: 24)
                                            
                                            Text(category)
                                                .font(.subheadline)
                                                .foregroundColor(.primary)
                                            
                                            Spacer()
                                            
                                            Text(String(format: "%.0f%%", percentage))
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            
                                            Text(String(format: "$%.0f", categoryTotal))
                                                .font(.subheadline)
                                                .bold()
                                                .foregroundStyle(
                                                    LinearGradient(
                                                        colors: categoryGradient(for: category),
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                                )
                                        }
                                    }
                                }
                                .padding(.top, 8)
                            }
                        }
                        .padding(.vertical, 8)
                        .listRowBackground(
                            LinearGradient(
                                colors: [.green.opacity(0.05), .mint.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    }
                    
                    if expenses.isEmpty {
                        Section {
                            VStack(spacing: 24) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 100, height: 100)
                                    
                                    Image(systemName: "dollarsign.circle")
                                        .font(.system(size: 50))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.blue, .purple],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                }
                                
                                VStack(spacing: 8) {
                                    Text("No Expenses Yet")
                                        .font(.title2)
                                        .bold()
                                    
                                    Text("Add expenses to your trips to track spending")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .listRowBackground(Color.clear)
                            .padding(.vertical, 60)
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
            .navigationTitle("All Expenses")
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

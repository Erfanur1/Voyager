import SwiftUI
import CoreData

struct AddExpenseView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage("preferredCurrency") private var preferredCurrency = "USD"
    
    let trip: Trip
    
    @State private var title = ""
    @State private var amount = ""
    @State private var category = "Food & Dining"
    @State private var date = Date()
    @State private var selectedCurrency = "USD"
    @State private var convertedAmount: Double?
    @State private var exchangeRate: Double?
    @State private var isConverting = false
    @State private var error: Error?
    
    let categories = ["Food & Dining", "Transportation", "Accommodation", "Activities", "Shopping", "Other"]
    let currencies = ["USD", "EUR", "GBP", "JPY", "AUD", "CAD", "CHF", "CNY", "INR", "MXN"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Expense Details") {
                    TextField("Title", text: $title)
                    
                    HStack {
                        TextField("Amount", text: $amount)
                            .keyboardType(.decimalPad)
                        
                        Picker("Currency", selection: $selectedCurrency) {
                            ForEach(currencies, id: \.self) { currency in
                                Text(currency).tag(currency)
                            }
                        }
                        .labelsHidden()
                    }
                    
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                
                if selectedCurrency != preferredCurrency,
                   let rate = exchangeRate,
                   let converted = convertedAmount {
                    Section("Currency Conversion") {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Exchange Rate")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("1 \(selectedCurrency) = \(String(format: "%.4f", rate)) \(preferredCurrency)")
                                    .font(.subheadline)
                            }
                            
                            Spacer()
                            
                            if isConverting {
                                ProgressView()
                            }
                        }
                        
                        HStack {
                            Text("Amount in \(preferredCurrency)")
                                .font(.headline)
                            Spacer()
                            Text(String(format: "%.2f", converted))
                                .font(.headline)
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveExpense() }
                        .disabled(title.isEmpty || amount.isEmpty)
                }
            }
            .onChange(of: amount) { _ in
                Task { await convertCurrency() }
            }
            .onChange(of: selectedCurrency) { _ in
                Task { await convertCurrency() }
            }
            .errorAlert(error: $error)
        }
    }
    
    private func convertCurrency() async {
        guard let amountValue = Double(amount),
              amountValue > 0,
              selectedCurrency != preferredCurrency else {
            convertedAmount = nil
            exchangeRate = nil
            return
        }
        
        isConverting = true
        
        do {
            let result = try await CurrencyService.shared.convertCurrency(
                amount: amountValue,
                from: selectedCurrency,
                to: preferredCurrency
            )
            
            await MainActor.run {
                self.convertedAmount = result.convertedAmount
                self.exchangeRate = result.rate
                self.isConverting = false
            }
        } catch {
            await MainActor.run {
                self.error = error
                self.isConverting = false
            }
        }
    }
    
    private func saveExpense() {
        guard let amountValue = Double(amount) else { return }
        
        let expense = Expense(context: viewContext)
        expense.id = UUID()
        expense.title = title
        expense.amount = amountValue
        expense.category = category
        expense.date = date
        expense.currency = selectedCurrency
        expense.trip = trip
        
        do {
            try PersistenceController.shared.save()
            dismiss()
        } catch {
            self.error = error
        }
    }
}

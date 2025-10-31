import SwiftUI

// Single reusable DateField component with configurable title and range.
public struct DateField: View {
    let title: String
    @Binding var date: Date
    var minDate: Date?
    var maxDate: Date?
    @State private var showSheet: Bool = false

    public init(title: String, date: Binding<Date>, minDate: Date? = nil, maxDate: Date? = nil) {
        self.title = title
        self._date = date
        self.minDate = minDate
        self.maxDate = maxDate
    }

    private var range: ClosedRange<Date> {
        (minDate ?? .distantPast)...(maxDate ?? .distantFuture)
    }

    public var body: some View {
        Button {
            showSheet = true
        } label: {
            HStack {
                Text(title)
                Spacer()
                Text(date.formatted(date: .abbreviated, time: .omitted))
                    .foregroundStyle(.secondary)
            }
        }
        .sheet(isPresented: $showSheet) {
            NavigationStack {
                VStack(alignment: .leading) {
                    DatePicker("Vyberte datum \(title.lowercased())", selection: $date, in: range, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .padding()
                }
                .navigationTitle("Vyberte datum \(title.lowercased())")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Hotovo") { showSheet = false }
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .onChange(of: date) { _, _ in
            if showSheet { showSheet = false }
        }
    }
}

// (aliases removed after migrating call sites)

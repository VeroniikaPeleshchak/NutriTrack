import SwiftUI
import Charts

struct AnalyticsView: View {
    @StateObject private var viewModel = AnalyticsViewModel()
    let periods = ["Тиждень", "Місяць", "Рік"]
    
    var chartDomain: ClosedRange<Date> {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        let now = Date()
        
        switch viewModel.selectedPeriod {
        case "Рік":
            let start = calendar.date(from: calendar.dateComponents([.year], from: now)) ?? now
            let end = calendar.date(byAdding: DateComponents(year: 1, second: -1), to: start) ?? now
            return start...end
        case "Місяць":
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
            let end = calendar.date(byAdding: DateComponents(month: 1, second: -1), to: start) ?? now
            return start...end
        default:
            let start = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
            let end = calendar.date(byAdding: DateComponents(day: 7, second: -1), to: start) ?? now
            return start...end
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Аналітика")
                        .font(.system(size: 28, weight: .bold))
                        .padding(.horizontal)
                    
                    Picker("Період", selection: $viewModel.selectedPeriod) {
                        ForEach(periods, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    if viewModel.isLoading && viewModel.weightData.isEmpty {
                        ProgressView().frame(maxWidth: .infinity).padding(.top, 50)
                    } else {
                        WeightChartCard(
                            weightData: viewModel.weightData,
                            weightChange: viewModel.weightChange,
                            selectedPeriod: viewModel.selectedPeriod,
                            domain: chartDomain
                        )
                        .padding(.horizontal)
                        
                        CalorieChartCard(
                            calorieData: viewModel.calorieData,
                            averageCalories: viewModel.averageCalories,
                            goal: viewModel.dailyCalorieGoal,
                            selectedPeriod: viewModel.selectedPeriod,
                            domain: chartDomain
                        )
                        .padding(.horizontal)
                        
                        HStack {
                            Circle().fill(Color.gray.opacity(0.3)).frame(width: 10, height: 10)
                            Text("Ціль: \(Int(viewModel.dailyCalorieGoal)) ккал/день")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Spacer()
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(15)
                        .padding(.horizontal)
                        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                }
                .padding(.vertical)
            }
            .navigationBarHidden(true)
            .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
            .task { await viewModel.loadAnalytics() }
        }
    }
}

// MARK: - ДИЗАЙН КАРТОК

struct WeightChartCard: View {
    let weightData: [WeightChartDataPoint]
    let weightChange: Double
    let selectedPeriod: String
    let domain: ClosedRange<Date>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Динаміка ваги").font(.headline)
                Text("Зміна ваги за \(selectedPeriod.lowercased())").font(.caption).foregroundColor(.gray)
            }
            
            HStack(alignment: .bottom) {
                Text(String(format: "%.1f", weightData.last?.weight ?? 0)).font(.system(size: 32, weight: .bold)) + Text(" кг").font(.headline).foregroundColor(.gray)
                Spacer()
                Text(String(format: "%+.1f кг", weightChange))
                    .font(.caption).bold()
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(weightChange <= 0 ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                    .foregroundColor(weightChange <= 0 ? .green : .red)
                    .cornerRadius(8)
            }
            
            Chart(weightData) { point in
                LineMark(x: .value("Дата", point.date, unit: .day), y: .value("Вага", point.weight))
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Color.blue)
                PointMark(x: .value("Дата", point.date, unit: .day), y: .value("Вага", point.weight))
                    .foregroundStyle(Color.blue)
            }
            .frame(height: 180)
            // ДОДАНО ВІДСТУП (.plotDimension), ЩОБ НЕ ОБРІЗАЛИСЯ КРАЇ
            .chartXScale(domain: domain, range: .plotDimension(padding: 15))
            .chartXAxis {
                if selectedPeriod == "Рік" {
                    AxisMarks(values: .stride(by: .month)) { value in
                        AxisGridLine()
                        if let date = value.as(Date.self) {
                            AxisValueLabel { Text(date, format: .dateTime.month(.abbreviated)) }
                        }
                    }
                } else if selectedPeriod == "Місяць" {
                    AxisMarks(values: .stride(by: .day, count: 7)) { value in
                        AxisGridLine()
                        if let date = value.as(Date.self) {
                            AxisValueLabel { Text(date, format: .dateTime.day()) }
                        }
                    }
                } else {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisGridLine()
                        if let date = value.as(Date.self) {
                            AxisValueLabel { Text(date, format: .dateTime.weekday(.abbreviated)) }
                        }
                    }
                }
            }
        }
        .padding(20).background(Color.white).cornerRadius(20).shadow(color: .black.opacity(0.05), radius: 10)
    }
}

struct CalorieChartCard: View {
    let calorieData: [CalorieChartDataPoint]
    let averageCalories: Double
    let goal: Double
    let selectedPeriod: String
    let domain: ClosedRange<Date>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Споживання калорій").font(.headline)
                Text("Калорії по днях").font(.caption).foregroundColor(.gray)
            }
            
            Text("\(Int(averageCalories))").font(.system(size: 32, weight: .bold)) + Text(" ккал середнє").font(.headline).foregroundColor(.gray)
            
            Chart {
                ForEach(calorieData) { point in
                    BarMark(x: .value("Дата", point.date, unit: .day), y: .value("Калорії", point.calories))
                        .foregroundStyle(Color.green.opacity(0.8))
                        .cornerRadius(4)
                }
                RuleMark(y: .value("Ціль", goal))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    .foregroundStyle(Color.gray.opacity(0.5))
            }
            .frame(height: 180)
            // ДОДАНО ВІДСТУП (.plotDimension), ЩОБ НЕ ОБРІЗАЛИСЯ КРАЇ
            .chartXScale(domain: domain, range: .plotDimension(padding: 15))
            .chartXAxis {
                if selectedPeriod == "Рік" {
                    AxisMarks(values: .stride(by: .month)) { value in
                        AxisGridLine()
                        if let date = value.as(Date.self) {
                            AxisValueLabel { Text(date, format: .dateTime.month(.abbreviated)) }
                        }
                    }
                } else if selectedPeriod == "Місяць" {
                    AxisMarks(values: .stride(by: .day, count: 7)) { value in
                        AxisGridLine()
                        if let date = value.as(Date.self) {
                            AxisValueLabel { Text(date, format: .dateTime.day()) }
                        }
                    }
                } else {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisGridLine()
                        if let date = value.as(Date.self) {
                            AxisValueLabel { Text(date, format: .dateTime.weekday(.abbreviated)) }
                        }
                    }
                }
            }
        }
        .padding(20).background(Color.white).cornerRadius(20).shadow(color: .black.opacity(0.05), radius: 10)
    }
}

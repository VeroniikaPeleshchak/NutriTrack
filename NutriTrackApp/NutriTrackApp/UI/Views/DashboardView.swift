import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @Binding var selectedTab: Int
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // MARK: - Перемикач дати (як на макеті)
                    HStack {
                        Button(action: { viewModel.changeDate(by: -1) }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .padding(.horizontal)
                        }
                        
                        Spacer()
                        
                        Text(viewModel.displayDateString)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button(action: { viewModel.changeDate(by: 1) }) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 18, weight: .semibold))
                                .padding(.horizontal)
                        }
                    }
                    .padding(.top, 10)
                    
                    // MARK: - Заголовок сторінки
                    HStack {
                        Text("Головна").font(.system(size: 28, weight: .bold))
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    if viewModel.isLoading && viewModel.calorieGoal == 0 {
                        ProgressView().padding(.top, 50)
                    } else {
                        
                        Button(action: {
                            selectedTab = 1
                        }) {
                            CalorieCard(
                                consumed: viewModel.consumedCalories,
                                goal: viewModel.calorieGoal,
                                remaining: viewModel.remainingCalories
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal)
                        
                        MacrosCard(
                            proteinConsumed: viewModel.consumedProtein, proteinGoal: viewModel.proteinGoal,
                            carbConsumed: viewModel.consumedCarb, carbGoal: viewModel.carbGoal,
                            fatConsumed: viewModel.consumedFat, fatGoal: viewModel.fatGoal
                        )
                        .padding(.horizontal)
                        
                        WaterCard(
                            waterAmount: viewModel.waterAmount,
                            onAdd: { amount in Task { await viewModel.addWater(amount: amount) } },
                            onRemove: { Task { await viewModel.removeLastWater() } }
                        )
                        .padding(.horizontal)
                        
                        ActivityCard(steps: viewModel.steps, burnedCalories: viewModel.burnedCalories)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationBarHidden(true)
            .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
            .task { await viewModel.loadDailyData() }
            .refreshable { await viewModel.loadDailyData() }
        }
    }
}

struct WaterCard: View {
    let waterAmount: Int
    let onAdd: (Int) -> Void
    let onRemove: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Гідратація").font(.headline)
                Spacer()
                Text("\(waterAmount) мл").font(.headline).foregroundColor(.blue)
            }
            
            let filledGlasses = min(waterAmount / 250, 8)
            HStack(spacing: 8) {
                ForEach(0..<8, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 6)
                        .fill(index < filledGlasses ? Color.blue : Color.blue.opacity(0.1))
                        .frame(height: 30)
                }
            }
            
            HStack(spacing: 10) {
                Button(action: onRemove) {
                    Image(systemName: "minus").font(.system(size: 14, weight: .bold))
                        .frame(width: 45, height: 45)
                        .background(Color(.systemGray6)).cornerRadius(12)
                }
                
                Button(action: { onAdd(250) }) {
                    Text("+ 250 мл").font(.subheadline).bold()
                        .frame(maxWidth: .infinity).frame(height: 45)
                        .background(Color.blue.opacity(0.1)).foregroundColor(.blue).cornerRadius(12)
                }
                
                Button(action: { onAdd(500) }) {
                    Text("+ 500 мл").font(.subheadline).bold()
                        .frame(maxWidth: .infinity).frame(height: 45)
                        .background(Color.blue).foregroundColor(.white).cornerRadius(12)
                }
            }
        }
        .padding(20).background(Color.white).cornerRadius(20)
    }
    
}

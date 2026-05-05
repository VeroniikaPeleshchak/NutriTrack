import SwiftUI

struct DiaryView: View {
    @StateObject private var viewModel = DiaryViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // MARK: - Дата та Навігація
                HStack {
                    Button(action: { viewModel.changeDate(byDays: -1) }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .padding()
                    }
                    
                    Spacer()
                    
                    Text(viewModel.displayDateString)
                        .font(.system(size: 20, weight: .bold))
                    
                    Spacer()
                    
                    Button(action: { viewModel.changeDate(byDays: 1) }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 20, weight: .semibold))
                            .padding()
                    }
                }
                .foregroundColor(.blue)
                .padding(.horizontal)
                
                Text("Щоденник харчування")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.vertical, 5)
                
                if viewModel.isLoading && viewModel.mealSections.isEmpty {
                    Spacer()
                    ProgressView().scaleEffect(1.2)
                    Spacer()
                } else {
                    // MARK: - Список (З картками і свайпами)
                    List {
                        ForEach(viewModel.mealSections) { section in
                            Section {
                                DiarySectionHeader(section: section, date: viewModel.selectedDate)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 8, trailing: 16))
                                
                                if section.consumedItems.isEmpty {
                                    Text("Ще не додано продуктів")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .padding(.vertical, 16)
                                        .listRowSeparator(.hidden)
                                } else {
                                    ForEach(section.consumedItems) { item in
                                        ConsumedItemRow(item: item)
                                            .padding(.vertical, 4)
                                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                                Button(role: .destructive) {
                                                    Task { await viewModel.deleteProduct(consumedId: item.consumedId) }
                                                } label: {
                                                    Label("Видалити", systemImage: "trash")
                                                }
                                                .tint(.red)
                                            }
                                    }
                                }
                            }
                            .listRowBackground(Color(.systemBackground))
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .refreshable { await viewModel.loadDiary() }
                }
            }
            .navigationBarHidden(true)
            .background(Color(.systemGroupedBackground))
            .onAppear {
                Task { await viewModel.loadDiary() }
            }
        }
    }
}

// MARK: - ДОПОМІЖНІ КОМПОНЕНТИ

struct DiarySectionHeader: View {
    let section: MealSectionUI
    let date: Date
    
    var body: some View {

        ZStack {
            HStack {
                Text(section.mealType)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("\(Int(section.totalSectionCalories)) ккал")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.leading, 4)
                
                Spacer()
                
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
            }
            
            NavigationLink(destination: CatalogView(mealType: section.mealType, date: date)) {
                EmptyView()
            }
            .opacity(0)
        }
    }
}

struct ConsumedItemRow: View {
    let item: ConsumedItemUI
    
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.product.name)
                    .font(.system(size: 16, weight: .medium))
                
                Text("\(Int(item.amount)) г")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text("\(Int(item.totalCalories)) ккал")
                .font(.system(size: 16, weight: .semibold))
        }
    }
}

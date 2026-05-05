import SwiftUI
import UIKit

struct AdminView: View {
    @StateObject private var viewModel = AdminViewModel()
    @State private var selectedTab = 0
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // MARK: - Заголовок
                HStack {
                    Text("Адмін-панель")
                        .font(.system(size: 28, weight: .bold))
                    Spacer()
                }
                .padding()

                // MARK: - Картки статистики
                if let stats = viewModel.stats {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            AdminStatCard(title: "Активні користувачі", value: "\(stats.activeUsers)", subtitle: "Оновлено щойно", icon: "person.2.fill", bgColor: Color.blue.opacity(0.1), textColor: .blue)
                            AdminStatCard(title: "Страв у базі", value: "\(stats.totalProducts)", subtitle: "Доступні всім", icon: "fork.knife", bgColor: Color.green.opacity(0.1), textColor: .green)
                            AdminStatCard(title: "Запити на розгляді", value: "\(stats.pendingRequests)", subtitle: "Потребують перевірки", icon: "clock.fill", bgColor: Color.purple.opacity(0.1), textColor: .purple)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 20)
                }

                // MARK: - Кастомні вкладки
                HStack(spacing: 10) {
                    TabButton(title: "Запити користувачів", isSelected: selectedTab == 0) {
                        selectedTab = 0
                        hideKeyboard() 
                        Task { await viewModel.loadDashboard() }
                    }
                    TabButton(title: "База продуктів", isSelected: selectedTab == 1) {
                        selectedTab = 1
                        hideKeyboard()
                        Task { await viewModel.loadGlobalProducts() }
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 15)
                
                Divider()
                
                // MARK: - Вміст
                if viewModel.isLoading && viewModel.stats == nil && viewModel.globalProducts.isEmpty {
                    Spacer()
                    ProgressView().scaleEffect(1.5)
                    Spacer()
                } else {
                    if selectedTab == 0 {
                        requestsTab
                    } else {
                        databaseTab
                    }
                }
            }
            .navigationBarHidden(true)
            .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
            .onTapGesture { hideKeyboard() } // Ховаємо клавіатуру при тапі по фону
            .task {
                await viewModel.loadDashboard()
            }
            .sheet(isPresented: $viewModel.showEditSheet) {
                AdminProductEditSheet(viewModel: viewModel)
            }
        }
    }
    
    // MARK: - Вкладка 1: Запити користувачів
    private var requestsTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Нові запити на додавання страв")
                        .font(.headline)
                    Spacer()
                    Text("\(viewModel.pendingRequests.count) запитів")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                if viewModel.pendingRequests.isEmpty {
                    Text("Немає нових запитів на модерацію.")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    ForEach(viewModel.pendingRequests, id: \.id) { product in
                        PendingRequestRow(product: product) {
                            Task { await viewModel.approveProduct(id: product.id!) }
                        } onReject: {
                            Task { await viewModel.rejectProduct(id: product.id!) }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 20)
        }
        .refreshable {
            await viewModel.loadDashboard()
        }
    }
    
    // MARK: - Вкладка 2: База продуктів
    private var databaseTab: some View {
        VStack(spacing: 0) {
            HStack(spacing: 15) {
                HStack {
                    Image(systemName: "magnifyingglass").foregroundColor(.gray)
                    TextField("Пошук продуктів в базі...", text: $viewModel.searchQuery)
                }
                .padding(10)
                .background(Color.white)
                .cornerRadius(10)
                
                Button(action: {
                    hideKeyboard()
                    viewModel.openAddSheet()
                }) {
                    Text("+ Додати продукт")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
            .padding()
            
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 10) {
                        Text("НАЗВА ПРОДУКТУ").font(.caption).foregroundColor(.gray).frame(width: 150, alignment: .leading)
                        Text("КАЛОРІЇ").font(.caption).foregroundColor(.gray).frame(width: 70, alignment: .center)
                        Text("БІЛКИ").font(.caption).foregroundColor(.gray).frame(width: 60, alignment: .center)
                        Text("ВУГЛЕВОДИ").font(.caption).foregroundColor(.gray).frame(width: 80, alignment: .center)
                        Text("ЖИРИ").font(.caption).foregroundColor(.gray).frame(width: 60, alignment: .center)
                        Text("ДІЇ").font(.caption).foregroundColor(.gray).frame(width: 80, alignment: .center)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 15)
                    
                    Divider()
                    
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.filteredGlobalProducts, id: \.id) { product in
                                HStack(spacing: 10) {
                                    Text(product.name)
                                        .font(.system(size: 14, weight: .medium))
                                        .frame(width: 150, alignment: .leading)
                                    
                                    Text("\(Int(product.calories)) ккал")
                                        .font(.system(size: 14))
                                        .frame(width: 70, alignment: .center)
                                    
                                    Text("\(String(format: "%.1f", product.proteins)) г")
                                        .font(.system(size: 14)).foregroundColor(.gray)
                                        .frame(width: 60, alignment: .center)
                                    
                                    Text("\(String(format: "%.1f", product.carbs)) г")
                                        .font(.system(size: 14)).foregroundColor(.gray)
                                        .frame(width: 80, alignment: .center)
                                    
                                    Text("\(String(format: "%.1f", product.fats)) г")
                                        .font(.system(size: 14)).foregroundColor(.gray)
                                        .frame(width: 60, alignment: .center)
                                    
                                    HStack(spacing: 15) {
                                        Button(action: {
                                            hideKeyboard()
                                            viewModel.openEditSheet(for: product)
                                        }) {
                                            Image(systemName: "square.and.pencil").foregroundColor(.blue)
                                        }
                                        Button(action: {
                                            hideKeyboard()
                                            if let id = product.id { Task { await viewModel.deleteGlobalProduct(id: id) } }
                                        }) {
                                            Image(systemName: "trash").foregroundColor(.red)
                                        }
                                    }
                                    .frame(width: 80, alignment: .center)
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal)
                                .background(Color.white)
                                
                                Divider()
                            }
                        }
                    }
                }
                .background(Color.white)
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - ДОПОМІЖНІ КОМПОНЕНТИ

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? .white : .gray)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(isSelected ? Color.blue : Color.white)
                .cornerRadius(20)
                .shadow(color: isSelected ? .blue.opacity(0.3) : .gray.opacity(0.1), radius: 5, y: 2)
        }
    }
}

struct AdminStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let bgColor: Color
    let textColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Circle().fill(bgColor).frame(width: 35, height: 35)
                    .overlay(Image(systemName: icon).foregroundColor(textColor).font(.system(size: 16)))
                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Text(value).font(.system(size: 28, weight: .bold))
            Text(subtitle).font(.system(size: 12)).foregroundColor(.gray)
        }
        .padding()
        .frame(width: 180, alignment: .leading)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .gray.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}


struct PendingRequestRow: View {
    let product: ProductDTO
    let onApprove: () -> Void
    let onReject: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(product.name).font(.system(size: 16, weight: .bold))
                Text("• \(Int(product.calories)) ккал/100г").font(.subheadline).foregroundColor(.gray)
                Spacer()
            }
            
            Text("Користувач ID: \(product.createdByUserId ?? 0)")
                .font(.caption)
                .foregroundColor(.gray)
            
            HStack(spacing: 15) {
                Button(action: onApprove) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Схвалити")
                    }
                    .font(.subheadline).fontWeight(.bold)
                    .frame(maxWidth: .infinity).frame(height: 38)
                    .background(Color.green).foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                Button(action: onReject) {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                        Text("Відхилити")
                    }
                    .font(.subheadline).fontWeight(.bold)
                    .frame(maxWidth: .infinity).frame(height: 38)
                    .background(Color.red).foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .gray.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Форма Додавання / Редагування[cite: 28]
struct AdminProductEditSheet: View {
    @ObservedObject var viewModel: AdminViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Основна інформація")) {
                    TextField("Назва продукту", text: $viewModel.productName)
                }
                
                Section(header: Text("Харчова цінність (на 100г)")) {
                    TextField("Калорії (ккал)", text: $viewModel.productCalories).keyboardType(.decimalPad)
                    TextField("Білки (г)", text: $viewModel.productProteins).keyboardType(.decimalPad)
                    TextField("Жири (г)", text: $viewModel.productFats).keyboardType(.decimalPad)
                    TextField("Вуглеводи (г)", text: $viewModel.productCarbs).keyboardType(.decimalPad)
                }
                
                // Вивід помилок
                if let error = viewModel.errorMessage {
                    Text(error).foregroundColor(.red).font(.caption).listRowBackground(Color.clear)
                }
                
                Button(action: {
                    hideKeyboard()
                    Task {
                        let success = await viewModel.saveProduct()
                        if success { dismiss() }
                    }
                }) {
                    HStack {
                        Spacer()
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Text(viewModel.editingProduct == nil ? "Створити" : "Зберегти зміни")
                                .bold()
                        }
                        Spacer()
                    }
                }
                .buttonStyle(.borderless)
                .disabled(viewModel.isLoading)
            }
            .navigationTitle(viewModel.editingProduct == nil ? "Новий продукт" : "Редагування")
            .navigationBarItems(leading: Button("Скасувати") {
                hideKeyboard()
                dismiss()
            })
            .onTapGesture { hideKeyboard() }
        }
    }
}

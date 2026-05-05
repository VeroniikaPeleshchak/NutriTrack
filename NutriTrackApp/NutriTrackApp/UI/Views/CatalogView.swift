import SwiftUI

struct CatalogView: View {
    let mealType: String
    let date: Date
    
    @StateObject private var viewModel = CatalogViewModel()
    @Environment(\.dismiss) var dismiss
    
    @State private var showingPortionSheet = false
    @State private var showingScanner = false
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Рядок пошуку
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Пошук продуктів...", text: $viewModel.searchQuery)
                    .onChange(of: viewModel.searchQuery) { newValue in
                        Task { await viewModel.search() }
                    }
                
                Button(action: { showingScanner = true }) {
                    Image(systemName: "camera")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            .padding(.top, 10)
            
            // MARK: - Кнопка "+ Створити свою страву"
            NavigationLink(destination: CreateCustomProductView(viewModel: viewModel)) {
                HStack {
                    Image(systemName: "plus")
                    Text("Створити свою страву")
                        .fontWeight(.medium)
                    Spacer()
                }
                .foregroundColor(.blue)
                .padding()
                .background(Color.blue.opacity(0.05))
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.top, 10)
            }
            
            if viewModel.isLoading && viewModel.searchResults.isEmpty {
                ProgressView().padding(.top, 30)
            }
            
            // MARK: - Список результатів
            List(viewModel.searchResults, id: \.id) { product in
                ZStack(alignment: .topTrailing) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(product.name)
                                .font(.system(size: 16, weight: .medium))
                            Text("100 г")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Text("\(Int(product.calories)) ккал")
                            .font(.system(size: 15, weight: .bold))
                            .padding(.trailing, 5)
                    }
                    .padding(.vertical, 8)
                    
                    if product.createdByUserId == AuthManager.shared.currentUserId && !product.isApproved {
                        CornerTriangle()
                            .fill(Color.orange)
                            .frame(width: 20, height: 20)
                            .offset(x: 16, y: -8)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if product.id != nil {
                        viewModel.selectedProduct = product
                        viewModel.portionGramsStr = "100"
                        showingPortionSheet = true
                    }
                }
                .listRowBackground(viewModel.selectedProduct?.id == product.id ? Color.blue.opacity(0.15) : Color(.systemBackground))
                
                // MARK: - СВАЙПИ ДЛЯ СВОЇХ СТРАВ
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    if product.createdByUserId == AuthManager.shared.currentUserId && !product.isApproved {
                        Button(role: .destructive) {
                            if let id = product.id { Task { await viewModel.deleteMyProduct(id: id) } }
                        } label: { Label("Видалити", systemImage: "trash") }
                        .tint(.red)
                        
                        Button {
                            viewModel.prepareForEditing(product)
                            viewModel.showEditSheet = true
                        } label: { Label("Змінити", systemImage: "pencil") }
                        .tint(.orange)
                    }
                }
            }
            .listStyle(PlainListStyle())
        }
        .navigationTitle("Додати продукт")
        .task {
            if viewModel.searchResults.isEmpty {
                await viewModel.loadInitialProducts()
            }
        }
        .sheet(isPresented: $showingPortionSheet, onDismiss: {
            viewModel.selectedProduct = nil
        }) {
            PortionSelectionSheet(viewModel: viewModel, mealType: mealType, date: date) {
                showingPortionSheet = false
                viewModel.selectedProduct = nil
                dismiss()
            }
        }
        .sheet(isPresented: $viewModel.showEditSheet) {
            NavigationView {
                CreateCustomProductView(viewModel: viewModel)
            }
        }
        .onTapGesture {
            hideKeyboard()
        }
    }
}

// MARK: - Модальне вікно вибору порції
struct PortionSelectionSheet: View {
    @ObservedObject var viewModel: CatalogViewModel
    let mealType: String
    let date: Date
    let onAdd: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            if let product = viewModel.selectedProduct {
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(product.name)
                        .font(.title2)
                        .bold()
                    Text("\(Int(product.calories)) ккал / 100 г")
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 30)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Розмір порції")
                        .fontWeight(.medium)
                        .padding(.horizontal, 20)
                    
                    HStack {
                        TextField("100", text: $viewModel.portionGramsStr)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.primary)
                        Spacer()
                        Text("г")
                            .foregroundColor(.gray)
                            .font(.system(size: 18, weight: .medium))
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue.opacity(0.5), lineWidth: 1.5)
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 3)
                    .padding(.horizontal, 20)
                    
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal, 25)
                    }
                }
                
                HStack {
                    Text("Загальна калорійність")
                        .foregroundColor(.gray)
                        .font(.system(size: 15))
                    
                    Spacer()
                    
                    let amount = Double(viewModel.portionGramsStr.replacingOccurrences(of: ",", with: ".")) ?? 0
                    Text("\(Int((product.calories * amount) / 100)) ккал")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.primary)
                }
                .padding()
                .background(Color.green.opacity(0.15))
                .cornerRadius(12)
                .padding(.horizontal, 20)
                
                Spacer()
                
                Button(action: {
                    hideKeyboard()
                    Task {
                        if await viewModel.addSelectedProductToDiary(mealType: mealType, date: date) {
                            onAdd()
                        }
                    }
                }) {
                    Text("Додати")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 55)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { hideKeyboard() }
        .presentationDetents([.fraction(0.55), .medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - ФІГУРА ДЛЯ КУТОЧКА
struct CornerTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

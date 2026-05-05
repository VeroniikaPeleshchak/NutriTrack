import SwiftUI

struct CreateCustomProductView: View {
    @ObservedObject var viewModel: CatalogViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Form {
            Section(header: Text("Інформація про страву")) {
                TextField("Назва страви", text: $viewModel.customName)
            }
            
            Section(header: Text("Харчова цінність (на 100 г)")) {
                TextField("Калорії (ккал)", text: $viewModel.customCalories).keyboardType(.decimalPad)
                TextField("Білки (г)", text: $viewModel.customProteins).keyboardType(.decimalPad)
                TextField("Жири (г)", text: $viewModel.customFats).keyboardType(.decimalPad)
                TextField("Вуглеводи (г)", text: $viewModel.customCarbs).keyboardType(.decimalPad)
            }
            
            // ВИВІД ПОМИЛОК ВАЛІДАЦІЇ
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .listRowBackground(Color.clear)
            }
            
            Button(action: {
                hideKeyboard() 
                Task {
                    let success = await viewModel.saveCustomProduct()
                    if success {
                        dismiss()
                    }
                }
            }) {
                HStack {
                    Spacer()
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Text(viewModel.editingProductId == nil ? "Зберегти страву" : "Оновити страву")
                            .fontWeight(.bold)
                    }
                    Spacer()
                }
            }
            .buttonStyle(.borderless)
            .disabled(viewModel.isLoading)
        }
        .navigationTitle(viewModel.editingProductId == nil ? "Нова страва" : "Редагування")
        .onDisappear {
            viewModel.clearForm()
        }
        .onTapGesture {
            hideKeyboard()
        }
    }
}

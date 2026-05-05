import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 25) {
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Розкажіть про себе").font(.system(size: 32, weight: .bold))
            }
            .padding(.top, 20)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Стать").fontWeight(.bold)
                HStack(spacing: 15) {
                    GenderTab(title: "Чоловік", isSelected: viewModel.gender == "Чоловік") {
                        hideKeyboard()
                        viewModel.gender = "Чоловік"
                    }
                    GenderTab(title: "Жінка", isSelected: viewModel.gender == "Жінка") {
                        hideKeyboard()
                        viewModel.gender = "Жінка"
                    }
                }
            }
            
            VStack(spacing: 20) {
                DatePicker("Дата народження", selection: $viewModel.dateOfBirth, displayedComponents: .date)
                    .padding().background(Color(.systemGray6)).cornerRadius(12)
                
                OnboardingInputField(label: "Зріст (см)", text: $viewModel.height, placeholder: "170", isNumber: true)
                OnboardingInputField(label: "Поточна вага (кг)", text: $viewModel.currentWeight, placeholder: "70", isNumber: true)
                OnboardingInputField(label: "Цільова вага (кг)", text: $viewModel.goalWeight, placeholder: "65", isNumber: true)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Рівень фізичної активності").fontWeight(.bold)
                Picker("Активність", selection: $viewModel.activityLevel) {
                    ForEach(viewModel.activityOptions, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(maxWidth: .infinity).padding().background(Color(.systemGray6)).cornerRadius(12)
            }
            
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.system(size: 13, weight: .medium))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            
            Spacer()
            
            Button(action: {
                hideKeyboard()
                Task { await viewModel.finishSetup() }
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 15).fill(Color.blue).frame(height: 55)
                    if viewModel.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Завершити налаштування").foregroundColor(.white).fontWeight(.bold)
                    }
                }
            }
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 25)
        .background(Color(.systemBackground).edgesIgnoringSafeArea(.all))
        .contentShape(Rectangle()) 
        .onTapGesture {
            hideKeyboard()
        }
        .fullScreenCover(isPresented: $viewModel.shouldNavigateToMain) {
            MainTabView()
        }
    }
}

// MARK: - Допоміжні компоненти
struct OnboardingInputField: View {
    let label: String; @Binding var text: String; let placeholder: String; var isNumber: Bool = false
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).font(.system(size: 14, weight: .medium))
            TextField(placeholder, text: $text)
                .keyboardType(isNumber ? .decimalPad : .default)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
        }
    }
}

struct GenderTab: View {
    let title: String; let isSelected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).frame(maxWidth: .infinity).frame(height: 50)
                .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
                .foregroundColor(isSelected ? .blue : .primary)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2))
                .cornerRadius(12)
        }
    }
}

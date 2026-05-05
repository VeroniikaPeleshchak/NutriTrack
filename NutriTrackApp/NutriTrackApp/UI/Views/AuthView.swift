import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @StateObject private var viewModel = AuthViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 25) {
                Spacer()
                
                // MARK: - Логотип та Назва
                VStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.green]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 80, height: 80)
                        
                        Text("NT")
                            .font(.system(size: 32, weight: .black))
                            .foregroundColor(.white)
                    }
                    
                    Text("NutriTrack")
                        .font(.system(size: 30, weight: .bold))
                }
                .padding(.bottom, 30)
                
                // MARK: - Поля вводу
                VStack(spacing: 15) {
                    if viewModel.isRegistrationMode {
                        TextField("Ім'я", text: $viewModel.name)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    
                    TextField("Email", text: $viewModel.email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    
                    SecureField("Пароль", text: $viewModel.password)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
                .padding(.horizontal, 30)
                .animation(.easeInOut, value: viewModel.isRegistrationMode)
                
                // MARK: - Повідомлення про помилку (ТЕПЕР ТУТ)
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.system(size: 13, weight: .medium))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                        .padding(.top, 5) 
                }
                
                // MARK: - Основна кнопка (Увійти / Зареєструватися)
                Button(action: {
                    hideKeyboard()
                    Task {
                        await viewModel.authenticate()
                    }
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.blue)
                            .frame(height: 55)
                        
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text(viewModel.isRegistrationMode ? "Зареєструватися" : "Увійти")
                                .foregroundColor(.white)
                                .fontWeight(.bold)
                        }
                    }
                }
                .padding(.horizontal, 30)
                .disabled(viewModel.isLoading)
                
                // MARK: - Кнопка перемикання режимів
                Button(action: {
                    withAnimation {
                        viewModel.isRegistrationMode.toggle()
                        viewModel.errorMessage = nil
                    }
                }) {
                    Text(viewModel.isRegistrationMode ? "Вже є акаунт? Увійти" : "Немає акаунту? Зареєструватися")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                }
                
                // MARK: - Apple ID
                VStack(spacing: 15) {
                    Text("або")
                        .foregroundColor(.gray)
                        .font(.system(size: 14))
                    
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        Task {
                            await viewModel.handleAppleLogin(result: result)
                        }
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .cornerRadius(12)
                    .padding(.horizontal, 30)
                }
                
                Spacer()
                
            }
            .navigationBarHidden(true)
            .contentShape(Rectangle())
            .onTapGesture {
                hideKeyboard()
            }
            .fullScreenCover(isPresented: $viewModel.navigateToDashboard) {
                MainTabView()
            }
            .fullScreenCover(isPresented: $viewModel.navigateToOnboarding) {
                OnboardingView()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("Logout"))) { _ in
                viewModel.navigateToDashboard = false
                viewModel.navigateToOnboarding = false
                
                viewModel.email = ""
                viewModel.password = ""
                
                viewModel.isRegistrationMode = false
            }
        }
    }
}

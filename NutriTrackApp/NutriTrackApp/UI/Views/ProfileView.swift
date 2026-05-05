import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showingUpdateSheet = false
    @State private var weightInput = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // MARK: - Хедер
                    ZStack(alignment: .bottom) {
                        LinearGradient(gradient: Gradient(colors: [.blue, .green.opacity(0.8)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                            .frame(height: 180)
                        
                        HStack(spacing: 20) {
                            Circle().fill(Color.white.opacity(0.2)).frame(width: 70, height: 70)
                                .overlay(Text(String(viewModel.name.prefix(1))).font(.title).bold().foregroundColor(.white))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(viewModel.name).font(.title3).bold().foregroundColor(.white)
                                Text(viewModel.email).font(.subheadline).foregroundColor(.white.opacity(0.9))
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 30)
                        .padding(.bottom, 25)
                    }
                    
                    // MARK: - Показники (Єдиний білий блок)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("ПОТОЧНІ ПОКАЗНИКИ").font(.caption).foregroundColor(.gray).padding(.leading, 5)
                        HStack(spacing: 0) {
                            IndicatorItem(value: String(format: "%.1f", viewModel.currentWeight), unit: "кг", icon: "scalemass", color: .blue)
                            Divider().frame(height: 40).padding(.horizontal, 5)
                            IndicatorItem(value: "\(Int(viewModel.height))", unit: "см", icon: "waveform.path.ecg", color: .green)
                            Divider().frame(height: 40).padding(.horizontal, 5)
                            IndicatorItem(value: String(format: "%.1f", viewModel.goalWeight), unit: "ціль", icon: "target", color: .red)
                        }
                        .padding(.vertical, 20)
                        .background(Color.white)
                        .cornerRadius(15)
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal)
                    
                    // MARK: - Секції Меню
                    VStack(spacing: 20) {
                        profileSection(header: "МОЇ ДАНІ") {
                            ProfileMenuButton(title: "Оновити вагу / виміри", icon: "pencil.circle.fill", color: .blue) {
                                weightInput = String(format: "%.1f", viewModel.currentWeight).replacingOccurrences(of: ".", with: ",")
                                showingUpdateSheet = true
                            }
                        }
                        
                        profileSection(header: "ІНТЕГРАЦІЇ") {
                            HStack {
                                Image(systemName: "heart.fill").foregroundColor(.red)
                                VStack(alignment: .leading) {
                                    Text("Синхронізація з Apple Health").foregroundColor(.primary)
                                    Text("Автоматичний імпорт даних").font(.caption).foregroundColor(.gray)
                                }
                                Spacer()
                                Toggle("", isOn: Binding(
                                    get: { viewModel.isHealthSyncEnabled },
                                    set: { newValue in Task { await viewModel.toggleHealthSync(isOn: newValue) } }
                                )).labelsHidden()
                            }
                            .padding().background(Color.white).cornerRadius(15)
                        }
                        
                        profileSection(header: "ДАНІ") {
                            ProfileMenuButton(title: "Експорт даних", icon: "arrow.down.to.line.compact", color: .green) {
                                Task { await viewModel.exportData() }
                            }
                        }
                        
                        if viewModel.isAdmin {
                            NavigationLink(destination: AdminView()) {
                                Text("Панель Адміністратора")
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color(hex: "9C27B0"))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 55)
                                    .background(Color(hex: "9C27B0").opacity(0.08))
                                    .cornerRadius(12)
                            }
                        }
                        
                        Button(action: { Task { await viewModel.logout() } }) {
                            HStack {
                                Text("Вийти з акаунту")
                            }
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .frame(height: 55)
                            .background(Color.red.opacity(0.05))
                            .cornerRadius(12)
                        }
                        
                        Button(action: { viewModel.showDeleteConfirmation = true }) {
                            Text("Видалити акаунт").font(.caption).foregroundColor(.red).opacity(0.5)
                        }
                        .padding(.top, 10)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .background(
                EmptyView()
                    .sheet(isPresented: $viewModel.showExportShareSheet) {
                        if let url = viewModel.exportedFileURL { ShareSheet(activityItems: [url]) }
                    }
            )
            .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
            .navigationBarHidden(true)
            .contentShape(Rectangle())
            .onTapGesture { hideKeyboard() }
            .sheet(isPresented: $showingUpdateSheet) {
                UpdateMeasurementsSheet(viewModel: viewModel, weight: $weightInput)
            }
            .alert(isPresented: $viewModel.showDeleteConfirmation) {
                Alert(title: Text("Видалення акаунту"), message: Text("Ви впевнені? Дані будуть втрачені."),
                      primaryButton: .destructive(Text("Видалити")) { Task { await viewModel.deleteAccount() } },
                      secondaryButton: .cancel())
            }
            .onAppear { viewModel.loadProfile() }
        }
    }
    
    private func profileSection<Content: View>(header: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(header).font(.caption).foregroundColor(.gray).padding(.leading, 5)
            content()
        }
    }
}

// MARK: - ДОПОМІЖНІ КОМПОНЕНТИ

struct IndicatorItem: View {
    let value: String; let unit: String; let icon: String; let color: Color
    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: icon).foregroundColor(color).font(.system(size: 18))
            Text(value).font(.system(size: 20, weight: .bold))
            Text(unit).font(.system(size: 12)).foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ProfileMenuButton: View {
    let title: String; let icon: String; let color: Color; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack {
                Circle().fill(color.opacity(0.1)).frame(width: 32, height: 32)
                    .overlay(Image(systemName: icon).foregroundColor(color).font(.system(size: 14)))
                Text(title).foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 12, weight: .bold)).foregroundColor(.gray.opacity(0.5))
            }
            .padding().background(Color.white).cornerRadius(15)
        }
    }
}

struct UpdateMeasurementsSheet: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Binding var weight: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Вага")) {
                    TextField("Поточна вага (кг)", text: $weight).keyboardType(.decimalPad)
                }
                Section(header: Text("Виміри тіла (см)")) {
                    TextField("Обхват талії", text: $viewModel.waist).keyboardType(.decimalPad)
                    TextField("Обхват грудей", text: $viewModel.chest).keyboardType(.decimalPad)
                    TextField("Обхват стегон", text: $viewModel.hips).keyboardType(.decimalPad)
                }
                
                if let error = viewModel.errorMessage {
                    Text(error).foregroundColor(.red).font(.caption).listRowBackground(Color.clear)
                }
                
                Button(action: {
                    Task {
                        let success = await viewModel.updateBodyMeasurements(newWeight: weight)
                        if success { dismiss() }
                    }
                }) {
                    Text("Зберегти зміни").bold().frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderless)
            }
            .navigationTitle("Оновити дані")
            .navigationBarItems(trailing: Button("Закрити") { viewModel.errorMessage = nil; dismiss() })
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ ui: UIActivityViewController, context: Context) {}
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue:  Double(b) / 255, opacity: Double(a) / 255)
    }
}

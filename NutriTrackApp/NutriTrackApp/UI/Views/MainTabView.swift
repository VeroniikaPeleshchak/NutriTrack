import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            
            DashboardView(selectedTab: $selectedTab)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Головна")
                }
                .tag(0)
            
            DiaryView()
                .tabItem {
                    Image(systemName: "book.fill")
                    Text("Щоденник")
                }
                .tag(1)
            
            AnalyticsView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Аналітика")
                }
                .tag(2)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Профіль")
                }
                .tag(3)
        }
        .tint(.blue) 
    }
}

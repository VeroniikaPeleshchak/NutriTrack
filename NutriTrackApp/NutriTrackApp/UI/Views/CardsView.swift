import SwiftUI

struct CalorieCard: View {
    let consumed: Double
    let goal: Double
    let remaining: Double
    
    var progress: Double {
        guard goal > 0 else { return 0 }
        return min(consumed / goal, 1.0)
    }
    
    var body: some View {
        VStack(spacing: 15) {
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    Text("Спожито калорій").foregroundColor(.white.opacity(0.8)).font(.subheadline)
                    Text("\(Int(consumed))")
                        .font(.system(size: 36, weight: .bold)).foregroundColor(.white)
                    Text("з \(Int(goal)) ккал").foregroundColor(.white.opacity(0.8)).font(.caption)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Залишилось").foregroundColor(.white.opacity(0.8)).font(.subheadline)
                    Text("\(Int(remaining))")
                        .font(.system(size: 28, weight: .bold)).foregroundColor(.white)
                    Text("ккал").foregroundColor(.white.opacity(0.8)).font(.caption)
                }
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.3)).frame(height: 12)
                    RoundedRectangle(cornerRadius: 10).fill(Color.white)
                        .frame(width: geometry.size.width * CGFloat(progress), height: 12)
                }
            }
            .frame(height: 12)
        }
        .padding(20)
        .background(LinearGradient(gradient: Gradient(colors: [.blue, .green.opacity(0.8)]), startPoint: .topLeading, endPoint: .bottomTrailing))
        .cornerRadius(20)
    }
}

struct MacrosCard: View {
    let proteinConsumed: Double; let proteinGoal: Double
    let carbConsumed: Double; let carbGoal: Double
    let fatConsumed: Double; let fatGoal: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Макронутрієнти").font(.headline)
            MacroRow(title: "Білки", consumed: proteinConsumed, goal: proteinGoal, color: .blue)
            MacroRow(title: "Вуглеводи", consumed: carbConsumed, goal: carbGoal, color: .green)
            MacroRow(title: "Жири", consumed: fatConsumed, goal: fatGoal, color: .orange)
        }
        .padding(20).background(Color.white).cornerRadius(20).shadow(color: .gray.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct MacroRow: View {
    let title: String; let consumed: Double; let goal: Double; let color: Color
    var progress: Double { goal > 0 ? min(consumed / goal, 1.0) : 0 }
    var body: some View {
        VStack(spacing: 5) {
            HStack {
                Text(title).font(.subheadline)
                Spacer()
                Text("\(Int(consumed)) / \(Int(goal)) г").font(.subheadline).foregroundColor(.gray)
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5).fill(Color(.systemGray6)).frame(height: 8)
                    RoundedRectangle(cornerRadius: 5).fill(color).frame(width: geometry.size.width * CGFloat(progress), height: 8)
                }
            }.frame(height: 8)
        }
    }
}

struct ActivityCard: View {
    let steps: Int
    let burnedCalories: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Активність").font(.headline)
            HStack(spacing: 15) {
                Image(systemName: "figure.walk.circle.fill").resizable().frame(width: 40, height: 40).foregroundColor(.purple)
                VStack(alignment: .leading) {
                    Text("Кроки").font(.subheadline).foregroundColor(.gray)
                    Text("\(steps)").font(.headline)
                }
                Spacer()
            }
            Divider()
            HStack(spacing: 15) {
                Image(systemName: "flame.circle.fill").resizable().frame(width: 40, height: 40).foregroundColor(.orange)
                VStack(alignment: .leading) {
                    Text("Спалено калорій").font(.subheadline).foregroundColor(.gray)
                    Text("\(Int(burnedCalories)) ккал").font(.headline)
                }
                Spacer()
            }
        }
        .padding(20).background(Color.white).cornerRadius(20).shadow(color: .gray.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}


import Foundation

class NetworkManager {
    static let shared = NetworkManager()
    
//  private let baseURL = "http://192.168.0.159:8080"
    private let baseURL = "http://172.20.10.2:8080"
    
    private init() {}
    
    enum NetworkError: Error {
        case invalidURL
        case invalidResponse
        case decodingError
        case unauthorized
    }

    // MARK: - Допоміжний метод для Хедерів
        private func addHeaders(to request: inout URLRequest) {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            if let token = KeychainManager.shared.getToken() {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
        }
        
        // MARK: - 1. GET запити (Отримання масиву даних)
        func fetchData<T: Decodable>(from endpoint: String) async throws -> [T] {
            guard let url = URL(string: baseURL + endpoint) else {
                throw NetworkError.invalidURL
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            addHeaders(to: &request)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                throw NetworkError.invalidResponse
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode([T].self, from: data)
            } catch {
                print("Помилка декодування для \(endpoint): \(error)")
                throw NetworkError.decodingError
            }
        }
        
        // MARK: - 2. POST/PUT запити (Відправка DTO і отримання відповіді DTO)
        func sendData<T: Encodable, U: Decodable>(to endpoint: String, method: String, data: T) async throws -> U {
            guard let url = URL(string: baseURL + endpoint) else {
                throw NetworkError.invalidURL
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = method
            addHeaders(to: &request)
            
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                request.httpBody = try encoder.encode(data)
            } catch {
                throw NetworkError.decodingError
            }
            
            let (responseData, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                let serverMessage = String(data: responseData, encoding: .utf8) ?? "Немає тексту помилки"
                print("Помилка від бекенду (Статус \(statusCode)): \(serverMessage)")
                throw NetworkError.invalidResponse
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(U.self, from: responseData)
            } catch {
                throw NetworkError.decodingError
            }
        }
        
        // MARK: - 3. DELETE/PATCH запити (Коли не чекаємо JSON у відповідь, тільки статус)
        func sendRequest(to endpoint: String, method: String) async throws {
            guard let url = URL(string: baseURL + endpoint) else {
                throw NetworkError.invalidURL
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = method
            addHeaders(to: &request)
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                throw NetworkError.invalidResponse
            }
        }
        
        // MARK: - 4. Офлайн-Синхронізація (Відправка "сирих" JSON-даних з Core Data)
        func sendRawData(to endpoint: String, method: String, data: Data) async throws {
            guard let url = URL(string: baseURL + endpoint) else {
                throw NetworkError.invalidURL
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = method
            addHeaders(to: &request)
            request.httpBody = data
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                throw NetworkError.invalidResponse
            }
        }
    
        func fetchSingle<T: Decodable>(from endpoint: String) async throws -> T {
            guard let url = URL(string: baseURL + endpoint) else {
                throw NetworkError.invalidURL
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            addHeaders(to: &request)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                throw NetworkError.invalidResponse
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: data)
        }
    
}

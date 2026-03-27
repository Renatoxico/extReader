//
//  NetworkService.swift
//  extReader
//
//  Created by Renato Dias on 04/06/25.
//

import Foundation

struct ServerErrorResponse: Decodable {
    let errorCode: String?
    let message: String?
    let details: String?
}

class ExpenseService {
    private let baseUrl = "https://api.renatoxico.net/extract/"
   
    static let shared = ExpenseService()
    private init() {}
    
    private func authHeader() async -> String? {
        guard let token = try? await AuthService.shared.accessToken() else { return nil }
        return "Bearer \(token)"
    }

    func fetchExpenses(sessionId: String) async throws -> ExpenseResponse {
        let urlString = baseUrl + "summary/" + sessionId;

        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        if let auth = await authHeader() {
            request.setValue(auth, forHTTPHeaderField: "Authorization")
        }

        let (data, _) = try await URLSession.shared.data(for: request)

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(ExpenseResponse.self, from: data)
        } catch {
            throw NetworkError.decodingFailed(error.localizedDescription)
        }
    }
    
    func processFiles(_ files: [URL]) async throws -> ExpenseResponse {
        let boundary = UUID().uuidString
        var request = URLRequest(url: URL(string: baseUrl)!)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        if let auth = await authHeader() {
            request.setValue(auth, forHTTPHeaderField: "Authorization")
        }
        
        var body = Data()
        
        for fileURL in files {
            guard fileURL.startAccessingSecurityScopedResource() else {
                    throw NetworkError.fileAccessDenied(fileURL.lastPathComponent)
                }
                defer { fileURL.stopAccessingSecurityScopedResource() }
            let filename = fileURL.lastPathComponent
            let fileData = try Data(contentsOf: fileURL)
            let mimeType = "application/pdf"

            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
            body.append(fileData)
            body.append("\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        print("⚠️ HTTP Status Code: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let serverError = try? JSONDecoder().decode(ServerErrorResponse.self, from: data),
               let message = serverError.message {
                throw NetworkError.serverError(message)
            }
            throw NetworkError.invalidResponse
        }

            do {
                let decoder = JSONDecoder()
                // Configure date decoding if your JSON uses dates
                // decoder.dateDecodingStrategy = .formatted(DateFormatter.yourFormat)
                return try decoder.decode(ExpenseResponse.self, from: data)
            } catch {
                throw NetworkError.decodingFailed(error.localizedDescription)
            }
        
    }
    
    enum NetworkError: LocalizedError {
        case invalidURL
        case invalidResponse
        case decodingFailed(String)
        case fileAccessDenied(String)
        case serverError(String)

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid API endpoint URL"
            case .invalidResponse:
                return "Received invalid response from server"
            case .decodingFailed(let details):
                return "Failed to decode response: \(details)"
            case .fileAccessDenied(let fileName):
                return "Access denied to file: \(fileName)"
            case .serverError(let message):
                return message
            }
        }
    }
}

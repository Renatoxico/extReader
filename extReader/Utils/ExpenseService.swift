//
//  NetworkService.swift
//  extReader
//
//  Created by Renato Dias on 04/06/25.
//

import Foundation

class ExpenseService {
    private let baseUrl = "http://192.168.15.3:9090/extract/";
//    private let baseUrl = "https://poderdamudanca.com/extract/"
   
    static let shared = ExpenseService()
    private init() {}
    
    func fetchExpenses(sessionId: String) async throws -> ExpenseResponse {
        let urlString = baseUrl + "summary/" + sessionId;
        
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)

        do {
            let decoder = JSONDecoder()
            // Configure date decoding if your JSON uses dates
            // decoder.dateDecodingStrategy = .formatted(DateFormatter.yourFormat)
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
            let responseBody = String(data: data, encoding: .utf8) ?? "<no body>"
            print("❌ Server Error Response Body:\n\(responseBody)")
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
            }
        }
    }
}

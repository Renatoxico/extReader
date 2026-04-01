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
        let urlString = baseUrl + "summary/" + sessionId

        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        if let auth = await authHeader() {
            request.setValue(auth, forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 403,
               let serverError = try? JSONDecoder().decode(ServerErrorResponse.self, from: data),
               serverError.message == "Premium subscription required" {
                throw NetworkError.premiumRequired
            }
            if let serverError = try? JSONDecoder().decode(ServerErrorResponse.self, from: data),
               let message = serverError.message {
                throw NetworkError.serverError(message)
            }
            throw NetworkError.invalidResponse
        }

        do {
            return try JSONDecoder().decode(ExpenseResponse.self, from: data)
        } catch {
            throw NetworkError.decodingFailed(error.localizedDescription)
        }
    }

    func processFiles(_ files: [URL]) async throws -> ExpenseResponse {
        let boundary = UUID().uuidString
        guard let baseURL = URL(string: baseUrl) else {
            throw NetworkError.invalidURL
        }
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
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

            body.appendUTF8("--\(boundary)\r\n")
            body.appendUTF8("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n")
            body.appendUTF8("Content-Type: \(mimeType)\r\n\r\n")
            body.append(fileData)
            body.appendUTF8("\r\n")
        }

        body.appendUTF8("--\(boundary)--\r\n")
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 403,
               let serverError = try? JSONDecoder().decode(ServerErrorResponse.self, from: data),
               serverError.message == "Premium subscription required" {
                throw NetworkError.premiumRequired
            }
            if let serverError = try? JSONDecoder().decode(ServerErrorResponse.self, from: data),
               let message = serverError.message {
                throw NetworkError.serverError(message)
            }
            throw NetworkError.invalidResponse
        }

        do {
            return try JSONDecoder().decode(ExpenseResponse.self, from: data)
        } catch {
            throw NetworkError.decodingFailed(error.localizedDescription)
        }
    }

    func exportCSV(sessionId: String) async throws -> Data {
        let urlString = baseUrl + "export/" + sessionId
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        if let auth = await authHeader() {
            request.setValue(auth, forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        guard httpResponse.statusCode == 200 else {
            if let serverError = try? JSONDecoder().decode(ServerErrorResponse.self, from: data),
               let message = serverError.message {
                throw NetworkError.serverError(message)
            }
            throw NetworkError.invalidResponse
        }
        return data
    }

    // MARK: - Errors

    enum NetworkError: LocalizedError {
        case invalidURL
        case invalidResponse
        case decodingFailed(String)
        case fileAccessDenied(String)
        case serverError(String)
        case premiumRequired

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
            case .premiumRequired:
                return "Assinatura Premium necessária"
            }
        }
    }
}

private extension Data {
    mutating func appendUTF8(_ string: String) {
        if let data = string.data(using: .utf8) { append(data) }
    }
}

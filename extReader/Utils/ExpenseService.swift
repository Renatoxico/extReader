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
    static let shared = ExpenseService()
    private init() {}

    private func authHeader() async throws -> String {
        let token = try await AuthService.shared.accessToken()
        return "Bearer \(token)"
    }

    func changeCategory(reportId: String, expenseName: String, newCategory: String) async throws -> ExpenseResponse {
        struct Body: Encodable { let expenseName: String; let newCategory: String }
        return try await editReport(reportId: reportId, path: "category", method: "PATCH",
                                    body: JSONEncoder().encode(Body(expenseName: expenseName, newCategory: newCategory)))
    }

    func deleteExpense(reportId: String, expenseId: Int64) async throws -> ExpenseResponse {
        try await editReport(reportId: reportId, path: String(expenseId), method: "DELETE")
    }

    func addExpense(reportId: String, name: String, amount: Decimal, date: String, category: String) async throws -> ExpenseResponse {
        struct Body: Encodable { let name: String; let amount: Decimal; let date: String; let category: String }
        return try await editReport(reportId: reportId, method: "POST",
                                    body: JSONEncoder().encode(Body(name: name, amount: amount, date: date, category: category)))
    }

    private func editReport(reportId: String, path: String? = nil, method: String, body: Data? = nil) async throws -> ExpenseResponse {
        var url = AppConfig.apiBaseURL.appending(path: "v2/reports").appending(path: reportId).appending(path: "expenses")
        if let path { url = url.appending(path: path) }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 30
        request.setValue(try await authHeader(), forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let response = response as? HTTPURLResponse else { throw NetworkError.invalidResponse }
        guard response.statusCode == (method == "POST" ? 201 : 200) else {
            let code = (try? JSONDecoder().decode(ServerErrorResponse.self, from: data))?.errorCode
            let message: String
            switch response.statusCode {
            case 401: message = "Sua sessão expirou. Entre novamente para continuar."
            case 400: message = "Confira o nome, o valor, a data e a categoria da despesa e tente novamente."
            case 404:
                message = code == "EXPENSE_NOT_FOUND"
                    ? "Esta despesa não foi encontrada. Abra o relatório novamente."
                    : "Este relatório não foi encontrado. Volte ao histórico e tente novamente."
            default: message = "Não foi possível salvar a alteração. Tente novamente em alguns instantes."
            }
            throw NetworkError.serverError(message)
        }
        do { return try JSONDecoder().decode(ExpenseResponse.self, from: data) }
        catch { throw NetworkError.serverError("Não foi possível atualizar o relatório. Abra o relatório novamente para conferir a alteração.") }
    }

    func fetchReports() async throws -> [ReportSummary] {
        let url = AppConfig.apiBaseURL
            .appending(path: "v2")
            .appending(path: "extract")
            .appending(path: "reports")

        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        request.setValue(try await authHeader(), forHTTPHeaderField: "Authorization")

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

        do {
            return try JSONDecoder().decode([ReportSummary].self, from: data)
        } catch {
            throw NetworkError.decodingFailed(error.localizedDescription)
        }
    }

    func fetchExpenses(sessionId: String) async throws -> ExpenseResponse {
        let url = AppConfig.apiBaseURL
            .appending(path: "v2")
            .appending(path: "extract")
            .appending(path: "summary")
            .appending(path: sessionId)

        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        request.setValue(try await authHeader(), forHTTPHeaderField: "Authorization")

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

        do {
            return try JSONDecoder().decode(ExpenseResponse.self, from: data)
        } catch {
            throw NetworkError.decodingFailed(error.localizedDescription)
        }
    }

    func processFiles(_ files: [URL]) async throws -> ExpenseResponse {
        let boundary = UUID().uuidString
        let baseURL = AppConfig.apiBaseURL
            .appending(path: "v2")
            .appending(path: "extract")
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue(try await authHeader(), forHTTPHeaderField: "Authorization")

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
        let url = AppConfig.apiBaseURL
            .appending(path: "v2")
            .appending(path: "extract")
            .appending(path: "export")
            .appending(path: sessionId)
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        request.setValue(try await authHeader(), forHTTPHeaderField: "Authorization")

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

private extension Data {
    mutating func appendUTF8(_ string: String) {
        if let data = string.data(using: .utf8) { append(data) }
    }
}

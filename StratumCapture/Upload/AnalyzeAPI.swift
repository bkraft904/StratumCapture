import Foundation
import UIKit

/// Talks to the SAME `/analyze` Lambda the web app already uses — same JSON
/// contract, so this works against the endpoint that's already deployed.
/// No new backend work needed for the findings part of this flow.
enum AnalyzeAPI {
    struct Finding: Decodable {
        let category: String
        let label: String
        let description: String
        let evidence: String
        let confidence: String
    }

    struct Usage: Decodable {
        let inputTokens: Int
        let outputTokens: Int

        enum CodingKeys: String, CodingKey {
            case inputTokens = "input_tokens"
            case outputTokens = "output_tokens"
        }
    }

    struct AnalysisResult: Decodable {
        let imageType: String
        let scopeNote: String
        let summary: String
        let findings: [Finding]
        let caveats: String
        let model: String
        let usage: Usage
    }

    struct APIError: Decodable {
        let error: String
    }

    enum RequestError: LocalizedError {
        case notConfigured
        case server(String)
        case decoding

        var errorDescription: String? {
            switch self {
            case .notConfigured:
                return "AppConfig.analyzeAPIURL isn't set yet — see Support/AppConfig.swift."
            case .server(let message):
                return message
            case .decoding:
                return "The server response couldn't be parsed."
            }
        }
    }

    static func analyze(images: [UIImage]) async throws -> AnalysisResult {
        guard let url = AppConfig.analyzeAPIURL else {
            throw RequestError.notConfigured
        }

        let payload = images.compactMap { image -> [String: String]? in
            guard let data = image.jpegData(compressionQuality: 0.85) else { return nil }
            return ["data": data.base64EncodedString(), "mediaType": "image/jpeg"]
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["images": payload])

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw RequestError.decoding
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let apiError = try? JSONDecoder().decode(APIError.self, from: data) {
                throw RequestError.server(apiError.error)
            }
            throw RequestError.server("Request failed (\(httpResponse.statusCode)).")
        }

        do {
            return try JSONDecoder().decode(AnalysisResult.self, from: data)
        } catch {
            throw RequestError.decoding
        }
    }
}

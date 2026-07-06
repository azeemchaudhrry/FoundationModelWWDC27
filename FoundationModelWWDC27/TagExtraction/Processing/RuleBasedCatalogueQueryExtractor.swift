import Foundation

public struct RuleBasedCatalogueQueryExtractor: Sendable {
    private let fillerPhrases: [String] = [
        "i am looking for",
        "looking for",
        "i want",
        "i need",
        "show me",
        "find me",
        "please",
        "preferably"
    ]

    private let timingPhrases: [String] = [
        "this weekend",
        "today",
        "tomorrow",
        "asap",
        "quickly",
        "soon"
    ]

    private let knownProductTypes: [String] = [
        "school uniform",
        "crossbody bag",
        "formal shoes",
        "gym shorts",
        "linen shirt",
        "running shorts",
        "swimsuit",
        "swimwear",
        "sneakers",
        "backpack",
        "jacket",
        "hoodie",
        "dress",
        "shirt",
        "shoes",
        "shorts",
        "bag",
        "uniform"
    ]

    private let colorTerms: [String] = ["black", "brown", "blue", "red", "green", "white"]
    private let sizeTerms: [String] = ["small", "large", "medium"]
    private let materialTerms: [String] = ["leather", "linen", "cotton", "wool", "waterproof"]
    private let styleTerms: [String] = ["oversized", "formal", "comfortable", "lightweight", "breathable", "soft", "running"]

    public init() {}

    public func extract(from originalQuery: String) -> ProductSearchQueryPlan {
        let cleaned = stripFillerAndTiming(from: originalQuery)
        let normalized = normalizedText(cleaned)

        let productType = detectProductType(in: normalized) ?? inferProductType(from: normalized)

        switch productType {
        case "shirt":
            return buildShirtPlan(from: normalized)
        case "linen shirt":
            return buildLinenShirtPlan(from: normalized)
        case "dress":
            return buildDressPlan(from: normalized)
        case "sneakers":
            return buildSneakersPlan(from: normalized)
        case "backpack":
            return buildBackpackPlan(from: normalized)
        case "jacket":
            return buildJacketPlan(from: normalized)
        case "swimsuit":
            return buildSwimsuitPlan(from: normalized)
        case "formal shoes":
            return buildFormalShoesPlan(from: normalized)
        case "gym shorts":
            return buildGymShortsPlan(from: normalized)
        case "hoodie":
            return buildHoodiePlan(from: normalized)
        case "crossbody bag":
            return buildCrossbodyBagPlan(from: normalized)
        case "school uniform", "uniform":
            return buildSchoolUniformPlan(from: normalized)
        default:
            return buildGenericPlan(from: normalized, productType: productType)
        }
    }

    private func buildShirtPlan(from query: String) -> ProductSearchQueryPlan {
        let color = firstTerm(in: query, candidates: colorTerms)
        let hasTropicalWeather = query.contains(" tropical weather ")

        let primary = joinQuery([color, hasTropicalWeather ? "breathable" : nil, "shirt"])
        let fallback = joinQuery([color, "shirt"])

        return ProductSearchQueryPlan(productType: "shirt", primaryQuery: primary, fallbackQuery: fallback)
    }

    private func buildLinenShirtPlan(from query: String) -> ProductSearchQueryPlan {
        let color = firstTerm(in: query, candidates: colorTerms)
        let primary = joinQuery([color, "linen shirt"])
        return ProductSearchQueryPlan(productType: "linen shirt", primaryQuery: primary, fallbackQuery: "linen shirt")
    }

    private func buildDressPlan(from query: String) -> ProductSearchQueryPlan {
        let color = firstTerm(in: query, candidates: colorTerms)
        let hasCocktail = query.contains(" cocktail party ")

        let primary = joinQuery([color, hasCocktail ? "cocktail" : nil, "dress"])
        let fallback = joinQuery([color, "dress"])

        return ProductSearchQueryPlan(productType: "dress", primaryQuery: primary, fallbackQuery: fallback)
    }

    private func buildSneakersPlan(from query: String) -> ProductSearchQueryPlan {
        let color = firstTerm(in: query, candidates: colorTerms)
        let hasWalking = query.contains(" walking all day ") || query.contains(" walking ")
        let hasComfortable = query.contains(" comfortable ")

        let primary = joinQuery([
            hasComfortable ? "comfortable" : nil,
            color,
            hasWalking ? "walking" : nil,
            "sneakers"
        ])
        let fallback = joinQuery([color, "sneakers"])

        return ProductSearchQueryPlan(productType: "sneakers", primaryQuery: primary, fallbackQuery: fallback)
    }

    private func buildBackpackPlan(from query: String) -> ProductSearchQueryPlan {
        let hasWaterproof = query.contains(" waterproof ")
        let hasCommutingContext = query.contains(" commuting ") || query.contains(" college ")

        let primary = joinQuery([hasWaterproof ? "waterproof" : nil, hasCommutingContext ? "commuter" : nil, "backpack"])
        let fallback = joinQuery([hasWaterproof ? "waterproof" : nil, "backpack"])

        return ProductSearchQueryPlan(productType: "backpack", primaryQuery: primary, fallbackQuery: fallback)
    }

    private func buildJacketPlan(from query: String) -> ProductSearchQueryPlan {
        let hasTransitionWeather = query.contains(" cold mornings but warm afternoons ")
        let hasLightweight = query.contains(" lightweight ") || hasTransitionWeather

        let primary = joinQuery([hasLightweight ? "lightweight" : nil, hasTransitionWeather ? "transitional" : nil, "jacket"])
        let fallback = joinQuery([hasLightweight ? "lightweight" : nil, "jacket"])

        return ProductSearchQueryPlan(productType: "jacket", primaryQuery: primary, fallbackQuery: fallback)
    }

    private func buildSwimsuitPlan(from query: String) -> ProductSearchQueryPlan {
        let color = firstTerm(in: query, candidates: colorTerms)
        let hasBeachVacation = query.contains(" beach vacation ")

        let primary = joinQuery([color, "swimsuit"])
        let fallback = joinQuery([color, hasBeachVacation ? "swimwear" : "swimsuit"])

        return ProductSearchQueryPlan(productType: "swimsuit", primaryQuery: primary, fallbackQuery: fallback)
    }

    private func buildFormalShoesPlan(from query: String) -> ProductSearchQueryPlan {
        let color = firstTerm(in: query, candidates: colorTerms)
        let hasLeather = query.contains(" leather ")

        let primary = joinQuery([color, hasLeather ? "leather" : nil, "formal shoes"])
        return ProductSearchQueryPlan(productType: "formal shoes", primaryQuery: primary, fallbackQuery: "formal shoes")
    }

    private func buildGymShortsPlan(from query: String) -> ProductSearchQueryPlan {
        let hasBreathable = query.contains(" breathable ") || query.contains(" hot weather ")
        let hasRunning = query.contains(" running ")

        let primary = joinQuery([hasBreathable ? "breathable" : nil, hasRunning ? "running" : nil, "gym shorts"])
        let fallback = hasRunning ? "running shorts" : "gym shorts"

        return ProductSearchQueryPlan(productType: "gym shorts", primaryQuery: primary, fallbackQuery: fallback)
    }

    private func buildHoodiePlan(from query: String) -> ProductSearchQueryPlan {
        let hasSoft = query.contains(" soft ")
        let hasOversized = query.contains(" oversized ")

        let primary = joinQuery([hasSoft ? "soft" : nil, hasOversized ? "oversized" : nil, "hoodie"])
        let fallback = joinQuery([hasOversized ? "oversized" : nil, "hoodie"])

        return ProductSearchQueryPlan(productType: "hoodie", primaryQuery: primary, fallbackQuery: fallback)
    }

    private func buildCrossbodyBagPlan(from query: String) -> ProductSearchQueryPlan {
        let size = firstTerm(in: query, candidates: sizeTerms)
        let hasTravel = query.contains(" traveling ") || query.contains(" travel ") || query.contains(" passport ")

        let primary = joinQuery([size, hasTravel ? "travel" : nil, "crossbody bag"])
        let fallback = joinQuery([size, "crossbody bag"])

        return ProductSearchQueryPlan(productType: "crossbody bag", primaryQuery: primary, fallbackQuery: fallback)
    }

    private func buildSchoolUniformPlan(from query: String) -> ProductSearchQueryPlan {
        let color = firstTerm(in: query, candidates: colorTerms)
        let age = extractAge(from: query)

        let primary = joinQuery([color, "school uniform", age])
        let fallback = joinQuery(["kids", color, "school uniform"])

        return ProductSearchQueryPlan(productType: "school uniform", primaryQuery: primary, fallbackQuery: fallback)
    }

    private func buildGenericPlan(from query: String, productType: String) -> ProductSearchQueryPlan {
        let color = firstTerm(in: query, candidates: colorTerms)
        let size = firstTerm(in: query, candidates: sizeTerms)
        let material = firstTerm(in: query, candidates: materialTerms)
        let style = firstTerm(in: query, candidates: styleTerms)

        let primary = joinQuery([color, size, material, style, productType])
        let fallback = joinQuery([color, size, productType])

        return ProductSearchQueryPlan(productType: productType, primaryQuery: primary, fallbackQuery: fallback)
    }

    private func detectProductType(in query: String) -> String? {
        for productType in knownProductTypes {
            if query.contains(" \(productType) ") {
                return productType
            }
        }
        return nil
    }

    private func inferProductType(from query: String) -> String {
        let stopwords: Set<String> = [
            "for", "and", "the", "a", "an", "my", "in", "on", "to", "of", "with", "but", "or", "all", "day", "old", "years", "year"
        ]

        let tokens = query
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: " ")
            .map(String.init)
            .filter { !stopwords.contains($0) }

        if tokens.count >= 2 {
            return tokens.suffix(2).joined(separator: " ")
        }

        if let token = tokens.last {
            return token
        }

        return "item"
    }

    private func stripFillerAndTiming(from query: String) -> String {
        var updated = query.lowercased()

        for phrase in fillerPhrases {
            updated = updated.replacingOccurrences(of: phrase, with: " ")
        }

        for phrase in timingPhrases {
            updated = updated.replacingOccurrences(of: phrase, with: " ")
        }

        return updated.replacingOccurrences(
            of: #"\s+"#,
            with: " ",
            options: .regularExpression
        )
    }

    private func normalizedText(_ text: String) -> String {
        let replaced = text.replacingOccurrences(
            of: #"[^a-z0-9]+"#,
            with: " ",
            options: .regularExpression
        )
        let collapsed = replaced.replacingOccurrences(
            of: #"\s+"#,
            with: " ",
            options: .regularExpression
        )
        return " \(collapsed.trimmingCharacters(in: .whitespacesAndNewlines)) "
    }

    private func firstTerm(in query: String, candidates: [String]) -> String? {
        for candidate in candidates where query.contains(" \(candidate) ") {
            return candidate
        }
        return nil
    }

    private func extractAge(from query: String) -> String? {
        let pattern = #"\b(\d{1,2})\s*(?:years?|year|yrs?)\b|\b(\d{1,2})\s*years\s*old\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }

        let nsRange = NSRange(query.startIndex..<query.endIndex, in: query)
        guard let match = regex.firstMatch(in: query, options: [], range: nsRange) else {
            return nil
        }

        for index in 1..<match.numberOfRanges {
            let range = match.range(at: index)
            guard range.location != NSNotFound, let swiftRange = Range(range, in: query) else {
                continue
            }
            let value = query[swiftRange]
            return "\(value) years"
        }

        return nil
    }

    private func joinQuery(_ pieces: [String?]) -> String {
        var seen = Set<String>()
        var output: [String] = []

        for piece in pieces {
            guard let piece else {
                continue
            }

            let trimmed = piece.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                continue
            }

            let key = trimmed.lowercased()
            guard seen.insert(key).inserted else {
                continue
            }

            output.append(trimmed)
        }

        return output.joined(separator: " ")
    }
}
//
//  EnhancedKeywordExtractor.swift
//  OurNews
//
//  Enhanced NLP keyword extraction using NLEmbedding (Word Vectors)
//  New Pipeline: Scan N-grams → NLTagger per section → Merge → Score → Rank
//

import Foundation
import NaturalLanguage

/// Enhanced keyword extraction using word embeddings and multi-factor scoring
class EnhancedKeywordExtractor {
    
    static let shared = EnhancedKeywordExtractor()
    
    // NLEmbedding for word vectors
    private let embedding: NLEmbedding?
    
    // Common bigrams for news domain
    private let commonBigrams: Set<String>
    
    // Common trigrams for news domain
    private let commonTrigrams: Set<String>
    
    // Stop words loaded from file
    private let stopWords: Set<String>
    
    private init() {
        // Load English word embedding model
        self.embedding = NLEmbedding.wordEmbedding(for: .english)
        
        if embedding == nil {
            print("⚠️ [增强关键词提取] NLEmbedding 模型不可用 → 使用降级方案（无词向量）")
        } else {
            print("✅ [增强关键词提取] NLEmbedding 模型已加载 → 使用完整方案（含词向量）")
        }
        
        // Load common phrases from files
        self.commonBigrams = Self.loadPhrases("news_bigrams")
        print("📚 [增强关键词提取] 已加载 \(commonBigrams.count) 个 2-gram 短语")
        
        self.commonTrigrams = Self.loadPhrases("news_trigrams")
        print("📚 [增强关键词提取] 已加载 \(commonTrigrams.count) 个 3-gram 短语")
        
        // Load stop words from file
        self.stopWords = Self.loadStopWords()
        print("🚫 [增强关键词提取] 已加载 \(stopWords.count) 个停用词")
    }
    
    /// Load common phrases from external file (works for bigrams, trigrams, etc.)
    private static func loadPhrases(_ resourceName: String) -> Set<String> {
        guard let path = Bundle.main.path(forResource: resourceName, ofType: "txt"),
              let content = try? String(contentsOfFile: path, encoding: .utf8) else {
            print("⚠️ [增强关键词提取] 未找到 \(resourceName).txt，使用空列表")
            return []
        }
        
        var phrases = Set<String>()
        let lines = content.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            // Skip empty lines and comments
            if !trimmed.isEmpty && !trimmed.hasPrefix("#") {
                phrases.insert(trimmed.lowercased())
            }
        }
        
        return phrases
    }
    
    /// Load stop words from external file
    private static func loadStopWords() -> Set<String> {
        guard let path = Bundle.main.path(forResource: "stop_words", ofType: "txt"),
              let content = try? String(contentsOfFile: path, encoding: .utf8) else {
            print("⚠️ [增强关键词提取] 未找到 stop_words.txt，使用默认列表")
            // Fallback to minimal set if file not found
            return ["a", "an", "the", "is", "are", "was", "were", "be", "been", "being",
                    "and", "or", "but", "if", "in", "on", "at", "to", "for", "of", "with"]
        }
        
        var words = Set<String>()
        let lines = content.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            // Skip empty lines and comments
            if !trimmed.isEmpty && !trimmed.hasPrefix("#") {
                words.insert(trimmed.lowercased())
            }
        }
        
        return words
    }
    
    // MARK: - Main Extraction Method
    
    /// Extract keywords using enhanced NLP pipeline with word embeddings
    /// - Parameters:
    ///   - title: Article title
    ///   - description: Article description
    ///   - content: Article content
    ///   - maxKeywords: Maximum number of keywords to return
    /// - Returns: Array of extracted keywords with their scores
    func extractKeywords(
        title: String,
        description: String?,
        content: String?,
        maxKeywords: Int = 5
    ) -> [(keyword: String, score: Double)] {
        
        // Process each section independently
        var allTokens: [TaggedToken] = []
        
        // Step 1+2: Process title section (N-gram scan + NLTagger)
        allTokens += processSection(text: title, source: .title, weight: 5.0)
        
        // Step 1+2: Process description section
        if let description = description, !description.isEmpty {
            allTokens += processSection(text: description, source: .description, weight: 2.5)
        }
        
        // Step 1+2: Process content section
        if let content = content, !content.isEmpty {
            allTokens += processSection(text: content, source: .content, weight: 1.0)
        }
        
        // Step 3: Merge by lemma and remove duplicates
        let normalizedTokens = mergeByLemma(tokens: allTokens)
        
        // Step 4: Vectorize & Score - Use semantic similarity to score keywords
        let scoredKeywords = vectorizeAndScore(tokens: normalizedTokens, title: title)
        
        // Step 5: Rank → Top-K - Sort and return top keywords
        return rankAndSelect(scoredKeywords: scoredKeywords, maxKeywords: maxKeywords)
    }
    
    // MARK: - Data Structures
    
    private enum TokenSource {
        case title, description, content
    }
    
    private struct TaggedToken {
        let originalWord: String  // Keep original word for display
        let lemma: String         // Use lemma for grouping
        let positionWeight: Double
        let positionIndex: Int    // Position within section
        let source: TokenSource
        let isEntity: Bool
        let entityType: NLTag?
        let isProperNoun: Bool
    }
    
    // MARK: - Step 1+2: Process Section (N-gram Scan + NLTagger)
    
    /// Process a single section: scan n-grams, analyze with NLTagger, merge phrases
    private func processSection(text: String, source: TokenSource, weight: Double) -> [TaggedToken] {
        guard !text.isEmpty else { return [] }
        
        // Step 1a: Scan and mark n-gram phrases (without modifying text)
        let markedPhrases = scanNGrams(in: text)
        
        // Step 1b: Use NLTagger to analyze the complete original text
        let tagger = NLTagger(tagSchemes: [.lexicalClass, .nameType, .lemma])
        tagger.string = text
        
        var tokens: [TaggedToken] = []
        var processedRanges: [Range<String.Index>] = []
        
        // Step 1c: Extract named entities (NER with multi-word support)
        tagger.enumerateTags(
            in: text.startIndex..<text.endIndex,
            unit: .word,
            scheme: .nameType,
            options: [.omitWhitespace, .omitPunctuation, .joinNames]
        ) { tag, range in
            if let tag = tag,
               (tag == .personalName || tag == .organizationName || tag == .placeName) {
                let entityText = String(text[range])
                let lemma = entityText.lowercased()
                
                // Add entity token (NER has priority)
                tokens.append(TaggedToken(
                    originalWord: entityText,
                    lemma: lemma,
                    positionWeight: weight,
                    positionIndex: tokens.count,
                    source: source,
                    isEntity: true,
                    entityType: tag,
                    isProperNoun: true
                ))
                
                processedRanges.append(range)
            }
            return true
        }
        
        // Step 1d: Process marked n-gram phrases (if not already covered by NER)
        for marked in markedPhrases {
            // Skip if already processed by NER
            let alreadyProcessed = processedRanges.contains { $0.overlaps(marked.0) }
            if !alreadyProcessed {
                let phraseText = String(text[marked.0])
                tokens.append(TaggedToken(
                    originalWord: phraseText,
                    lemma: marked.1,
                    positionWeight: weight * 1.2,  // Boost for dictionary phrases
                    positionIndex: tokens.count,
                    source: source,
                    isEntity: true,  // Treat as entity-like
                    entityType: nil,
                    isProperNoun: false
                ))
                
                processedRanges.append(marked.0)
            }
        }
        
        // Step 1e: Extract remaining single words (with POS filtering and stop word removal)
        tagger.enumerateTags(
            in: text.startIndex..<text.endIndex,
            unit: .word,
            scheme: .lexicalClass,
            options: [.omitWhitespace, .omitPunctuation]
        ) { posTag, range in
            // Skip if already processed
            let alreadyProcessed = processedRanges.contains { $0.overlaps(range) }
            guard !alreadyProcessed else { return true }
            
            let originalWord = String(text[range])
            let word = originalWord.lowercased()
            
            // Early filtering: stop words and short hyphenated words
            if isStopWord(word) {
                return true
            }
            
            // Filter short hyphenated words (e.g., "ex-", "re-")
            if word.count <= 3 && word.contains("-") {
                return true
            }
            
            // Minimum length check (allow 2-letter uppercase acronyms)
            let isAcronym = originalWord.count == 2 && originalWord.uppercased() == originalWord
            let minLength = isAcronym ? 2 : 3
            guard word.count >= minLength else { return true }
            
            // Must have at least some letters
            guard word.rangeOfCharacter(from: .letters) != nil else { return true }
            
            // POS filtering: keep nouns, adjectives, verbs
            let relevantPOS: Set<NLTag> = [.noun, .adjective, .verb]
            guard let pos = posTag, relevantPOS.contains(pos) else { return true }
            
            // Get lemma
            let (lemmaTag, _) = tagger.tag(at: range.lowerBound, unit: .word, scheme: .lemma)
            var lemma = lemmaTag?.rawValue.lowercased() ?? word
            
            // Protect certain words from over-lemmatization
            // Keep original if lemma is much shorter (>30% reduction)
            if lemma.count < Int(Double(word.count) * 0.7) {
                lemma = word
            }
            
            // Boost proper nouns in title (check if first letter is uppercase and it's a noun)
            let isProperNoun = originalWord.first?.isUppercase == true && pos == .noun
            let finalWeight = (isProperNoun && source == .title) ? weight * 1.3 : weight
            
            tokens.append(TaggedToken(
                originalWord: originalWord,
                lemma: lemma,
                positionWeight: finalWeight,
                positionIndex: tokens.count,
                source: source,
                isEntity: false,
                entityType: nil,
                isProperNoun: isProperNoun
            ))
            
            processedRanges.append(range)
            return true
        }
        
        return tokens
    }
    
    /// Scan text for n-gram phrases without modifying the text
    private func scanNGrams(in text: String) -> [(range: Range<String.Index>, phrase: String)] {
        var marked: [(Range<String.Index>, String)] = []
        
        // Scan trigrams first (longer phrases have priority)
        for trigram in commonTrigrams {
            let pattern = trigram.replacingOccurrences(of: " ", with: "\\s+")
            let regex = try? NSRegularExpression(
                pattern: "\\b\(pattern)\\b",
                options: .caseInsensitive
            )
            
            if let regex = regex {
                let nsRange = NSRange(text.startIndex..., in: text)
                let matches = regex.matches(in: text, range: nsRange)
                
                for match in matches {
                    if let range = Range(match.range, in: text) {
                        marked.append((range, trigram))
                    }
                }
            }
        }
        
        // Scan bigrams (skip ranges already covered by trigrams)
        for bigram in commonBigrams {
            let pattern = bigram.replacingOccurrences(of: " ", with: "\\s+")
            let regex = try? NSRegularExpression(
                pattern: "\\b\(pattern)\\b",
                options: .caseInsensitive
            )
            
            if let regex = regex {
                let nsRange = NSRange(text.startIndex..., in: text)
                let matches = regex.matches(in: text, range: nsRange)
                
                for match in matches {
                    if let range = Range(match.range, in: text) {
                        // Skip if overlaps with existing trigram
                        let overlaps = marked.contains { $0.0.overlaps(range) }
                        if !overlaps {
                            marked.append((range, bigram))
                        }
                    }
                }
            }
        }
        
        return marked
    }
    
    // MARK: - Step 3: Merge by Lemma
    
    private struct NormalizedToken {
        let originalWord: String  // For display
        let lemma: String         // For grouping
        let positionWeight: Double
        let frequency: Int
        let source: TokenSource
        let firstPosition: Int
        let isEntity: Bool
        let wordLength: Int
    }
    
    /// Merge tokens by lemma and track frequency
    private func mergeByLemma(tokens: [TaggedToken]) -> [NormalizedToken] {
        var lemmaGroups: [String: (
            originalWord: String,
            totalWeight: Double,
            count: Int,
            source: TokenSource,
            position: Int,
            isEntity: Bool
        )] = [:]
        
        for token in tokens {
            if let existing = lemmaGroups[token.lemma] {
                // Update existing: accumulate weight and count, keep first occurrence
                lemmaGroups[token.lemma] = (
                    originalWord: existing.originalWord,  // Keep first occurrence
                    totalWeight: existing.totalWeight + token.positionWeight,
                    count: existing.count + 1,
                    source: existing.source,  // Keep first source
                    position: existing.position,  // Keep first position
                    isEntity: existing.isEntity || token.isEntity
                )
            } else {
                // First occurrence
                lemmaGroups[token.lemma] = (
                    originalWord: token.originalWord,
                    totalWeight: token.positionWeight,
                    count: 1,
                    source: token.source,
                    position: token.positionIndex,
                    isEntity: token.isEntity
                )
            }
        }
        
        // Convert to array
        return lemmaGroups.map { lemma, data in
            NormalizedToken(
                originalWord: data.originalWord,
                lemma: lemma,
                positionWeight: data.totalWeight,
                frequency: data.count,
                source: data.source,
                firstPosition: data.position,
                isEntity: data.isEntity,
                wordLength: lemma.count
            )
        }
    }
    
    // MARK: - Step 4: Vectorize & Score
    
    private struct ScoredKeyword {
        let keyword: String
        let score: Double
        let source: TokenSource
        let position: Int
    }
    
    /// Calculate semantic similarity and multi-factor scores
    private func vectorizeAndScore(tokens: [NormalizedToken], title: String) -> [ScoredKeyword] {
        var scoredKeywords: [ScoredKeyword] = []
        
        // Calculate title vector for semantic similarity
        let titleVector = getTitleVector(title: title)
        
        for token in tokens {
            var score = 0.0
            
            // Factor 1: Position weight (title=5.0, desc=2.5, content=1.0)
            let positionScore = token.positionWeight
            
            // Factor 2: Frequency (logarithmic scaling)
            let frequencyScore = log2(Double(token.frequency) + 1.0)
            
            // Factor 3: Entity boost
            let entityBoost = token.isEntity ? 1.0 : 0.0
            
            // Factor 4: Semantic similarity with title
            var semanticScore = 0.0
            if let embedding = embedding,
               let candidateVector = embedding.vector(for: token.lemma),
               let titleVec = titleVector {
                semanticScore = cosineSimilarity(candidateVector, titleVec)
            }
            
            // Factor 5: Length bonus (longer = more specific)
            let lengthBonus = min(Double(token.wordLength) / 10.0, 2.0)
            
            // Combined scoring formula
            let alpha = 1.5    // Position weight
            let beta = 1.0     // Frequency weight
            let gamma = 2.0    // Semantic similarity
            let delta = 2.5    // Entity boost
            let epsilon = 1.2  // Length bonus
            
            score = alpha * positionScore +
                    beta * frequencyScore +
                    gamma * semanticScore +
                    delta * entityBoost +
                    epsilon * lengthBonus
            
            scoredKeywords.append(ScoredKeyword(
                keyword: token.originalWord,  // Use original word for display
                score: score,
                source: token.source,
                position: token.firstPosition
            ))
        }
        
        return scoredKeywords
    }
    
    /// Calculate average title vector
    private func getTitleVector(title: String) -> [Double]? {
        guard let embedding = embedding else { return nil }
        
        var vectors: [[Double]] = []
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = title
        
        tokenizer.enumerateTokens(in: title.startIndex..<title.endIndex) { range, _ in
            let word = String(title[range]).lowercased()
            
            if !isStopWord(word), word.count > 2,
               let vector = embedding.vector(for: word) {
                vectors.append(vector)
            }
            return true
        }
        
        guard !vectors.isEmpty else { return nil }
        
        // Calculate average
        let dimension = vectors[0].count
        var avgVector = [Double](repeating: 0.0, count: dimension)
        
        for vector in vectors {
            for i in 0..<dimension {
                avgVector[i] += vector[i]
            }
        }
        
        for i in 0..<dimension {
            avgVector[i] /= Double(vectors.count)
        }
        
        return avgVector
    }
    
    /// Cosine similarity between two vectors
    private func cosineSimilarity(_ vec1: [Double], _ vec2: [Double]) -> Double {
        guard vec1.count == vec2.count, !vec1.isEmpty else { return 0.0 }
        
        var dotProduct = 0.0
        for i in 0..<vec1.count {
            dotProduct += vec1[i] * vec2[i]
        }
        
        let mag1 = sqrt(vec1.reduce(0.0) { $0 + $1 * $1 })
        let mag2 = sqrt(vec2.reduce(0.0) { $0 + $1 * $1 })
        
        guard mag1 > 0, mag2 > 0 else { return 0.0 }
        
        return dotProduct / (mag1 * mag2)
    }
    
    // MARK: - Step 5: Rank & Select
    
    /// Two-stage ranking: score-based selection + position-based reordering
    private func rankAndSelect(
        scoredKeywords: [ScoredKeyword],
        maxKeywords: Int
    ) -> [(keyword: String, score: Double)] {
        // Stage 1: Select top-K by score
        let topKeywords = scoredKeywords
            .sorted { $0.score > $1.score }
            .prefix(maxKeywords)
        
        // Stage 2: Reorder by source priority + position
        let reordered = topKeywords.sorted { kw1, kw2 in
            let sourcePriority: [TokenSource: Int] = [
                .title: 0,
                .description: 1,
                .content: 2
            ]
            
            let p1 = sourcePriority[kw1.source] ?? 3
            let p2 = sourcePriority[kw2.source] ?? 3
            
            if p1 != p2 {
                return p1 < p2
            }
            
            return kw1.position < kw2.position
        }
        
        return reordered.map { ($0.keyword, $0.score) }
    }
    
    // MARK: - Helper Methods
    
    /// Check if a word is a stop word
    private func isStopWord(_ word: String) -> Bool {
        return stopWords.contains(word.lowercased())
    }
    
    // MARK: - Convenience Method (returns only keywords without scores)
    
    /// Extract keywords and return only the keyword strings (for UI compatibility)
    func extractKeywordsSimple(
        title: String,
        description: String?,
        content: String?,
        maxKeywords: Int = 5
    ) -> [String] {
        print("🔍 [关键词提取] 开始提取: \(title.prefix(40))...")
        
        let results = extractKeywords(
            title: title,
            description: description,
            content: content,
            maxKeywords: maxKeywords
        )
        
        // Debug: show scores with details
        print("   排序策略: 按来源优先级(Title>Desc>Content) + 位置")
        for (index, result) in results.enumerated() {
            print("   \(index+1). \(result.keyword) (分数: \(String(format: "%.2f", result.score)))")
        }
        
        let keywords = results.map { $0.keyword }
        return keywords
    }
}

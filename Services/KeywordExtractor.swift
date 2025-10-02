//
//  KeywordExtractor.swift
//
//  Created on 11/02/25.
//

import Foundation
import NaturalLanguage

class KeywordExtractor {
    
    static let shared = KeywordExtractor()
    private init() {}
    
    /// Extract keywords from text using NLP
    /// - Parameters:
    ///   - text: The text to analyze
    ///   - maxKeywords: Maximum number of keywords to extract (default: 5)
    /// - Returns: Array of extracted keywords
    func extractKeywords(from text: String, maxKeywords: Int = 5) -> [String] {
        // Remove common stop words and punctuation
        let tagger = NLTagger(tagSchemes: [.lexicalClass, .nameType])
        tagger.string = text
        
        var keywords: [String] = []
        var wordFrequency: [String: Int] = [:]
        
        // Extract nouns and proper nouns as they are usually the most meaningful
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, 
                            unit: .word,
                            scheme: .lexicalClass,
                            options: [.omitWhitespace, .omitPunctuation]) { tag, tokenRange in
            
            let word = String(text[tokenRange]).lowercased()
            
            // Filter by tag: nouns and significant words
            if let tag = tag,
               tag == .noun,
               word.count > 3,  // Ignore very short words
               !self.isStopWord(word) {
                
                wordFrequency[word, default: 0] += 1
            }
            return true
        }
        
        // Also check for named entities (people, organizations, places)
        tagger.enumerateTags(in: text.startIndex..<text.endIndex,
                            unit: .word,
                            scheme: .nameType,
                            options: [.omitWhitespace, .omitPunctuation, .joinNames]) { tag, tokenRange in
            
            let entity = String(text[tokenRange])
            
            if let tag = tag,
               (tag == .organizationName || tag == .placeName || tag == .personalName),
               entity.count > 2 {
                
                wordFrequency[entity, default: 0] += 3  // Give entities higher weight
            }
            return true
        }
        
        // Sort by frequency and take top keywords
        keywords = wordFrequency.sorted { $0.value > $1.value }
            .prefix(maxKeywords)
            .map { $0.key.capitalized }
        
        return keywords
    }
    
    /// Extract keywords from article (title + description + content)
    /// - Parameters:
    ///   - title: Article title
    ///   - description: Article description
    ///   - content: Article content (partial)
    ///   - maxKeywords: Maximum number of keywords
    /// - Returns: Array of extracted keywords
    func extractKeywords(title: String, description: String?, content: String?, maxKeywords: Int = 5) -> [String] {
        // Combine all available text, giving priority to title and description
        var combinedText = title + " " + (description ?? "")
        
        // Add content if available (usually partial article text)
        if let content = content, !content.isEmpty {
            combinedText += " " + content
        }
        
        return extractKeywords(from: combinedText, maxKeywords: maxKeywords)
    }
    
    // Common English stop words to filter out
    private func isStopWord(_ word: String) -> Bool {
        let stopWords: Set<String> = [
            "the", "and", "for", "that", "this", "with", "from", "have",
            "has", "been", "will", "their", "what", "when", "where", "which",
            "there", "these", "those", "about", "after", "before", "could",
            "would", "should", "more", "most", "some", "such", "than", "then",
            "them", "they", "into", "over", "only", "also", "just", "being",
            "were", "been", "your", "says", "said", "make", "made", "does"
        ]
        return stopWords.contains(word)
    }
}

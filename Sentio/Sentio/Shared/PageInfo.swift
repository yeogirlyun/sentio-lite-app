//
//  PageInfo.swift
//  Sentio
//
//  Created by BeeJay on 11/7/25.
//

import Foundation

struct PageInfo: Codable, Hashable {
    let EndCursor: String?
    let HasNextPage: Bool
    let HasPrevPage: Bool
    let StartCursor: String?
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case EndCursor = "end_cursor"
        case HasNextPage = "has_next_page"
        case HasPrevPage = "has_previous_page"
        case StartCursor = "start_cursor"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        EndCursor = try container.decodeIfPresent(String.self, forKey: .EndCursor)
        HasNextPage = try container.decode(Bool.self, forKey: .HasNextPage)
        HasPrevPage = try container.decode(Bool.self, forKey: .HasPrevPage)
        StartCursor = try container.decodeIfPresent(String.self, forKey: .StartCursor)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(EndCursor, forKey: .EndCursor)
        try container.encode(HasNextPage, forKey: .HasNextPage)
        try container.encode(HasPrevPage, forKey: .HasPrevPage)
        try container.encodeIfPresent(StartCursor, forKey: .StartCursor)
    }
    
    // MARK: - Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(EndCursor)
        hasher.combine(HasNextPage)
        hasher.combine(HasPrevPage)
        hasher.combine(StartCursor)
    }
    
    static func == (lhs: PageInfo, rhs: PageInfo) -> Bool {
        lhs.EndCursor == rhs.EndCursor &&
        lhs.HasNextPage == rhs.HasNextPage &&
        lhs.HasPrevPage == rhs.HasPrevPage &&
        lhs.StartCursor == rhs.StartCursor
    }
}

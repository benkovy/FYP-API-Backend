//
//  StringExtension.swift
//  App
//
//  Created by Ben Kovacs on 2018-02-06.
//

import Foundation
import Vapor

extension String {
    func stringToDate(withFormat format: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.date(from: self)
    }
}

extension String: Error {}

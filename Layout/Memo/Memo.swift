//
//  Memo.swift
//  Layout
//
//  Created by Byeongjo Koo.
//

import Foundation

struct Memo: Hashable, Identifiable, Sendable {
  let id: String
  var content: String
  var date: Date
  var isPinned: Bool
}

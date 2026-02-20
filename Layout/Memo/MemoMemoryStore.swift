//
//  MemoMemoryStore.swift
//  Layout
//
//  Created by Byeongjo Koo.
//

import Foundation

final class MemoMemoryStore {
  
  // MARK: Shared
  
  static let shared = MemoMemoryStore()
  
  // MARK: Properties
  
  private let lock = NSLock()
  private var memos: [Memo.ID: Memo] = [:]
  
  // MARK: CRUD
  
  func upsert(_ memo: Memo) {
    lock.lock()
    memos[memo.id] = memo
    lock.unlock()
  }
  
  func updateMemo(
    id: Memo.ID,
    content: String,
    date: Date,
    isPinned: Bool
  ) -> Bool {
    lock.lock()
    defer { lock.unlock() }
    
    guard var memo = memos[id] else { return false }
    memo.content = content
    memo.date = date
    memo.isPinned = isPinned
    memos[id] = memo
    return true
  }
  
  func deleteMemo(id: Memo.ID) -> Bool {
    lock.lock()
    defer { lock.unlock() }
    return memos.removeValue(forKey: id) != nil
  }
  
  func memo(with id: Memo.ID) -> Memo? {
    lock.lock()
    defer { lock.unlock() }
    return memos[id]
  }
  
  func fetchMemos() -> [Memo] {
    lock.lock()
    defer { lock.unlock() }
    return sortedMemos(memos.values)
  }
  
  // MARK: Helpers
  
  private func sortedMemos(_ memos: Dictionary<Memo.ID, Memo>.Values) -> [Memo] {
    memos.sorted {
      if $0.isPinned != $1.isPinned { return $0.isPinned && $1.isPinned == false }
      if $0.date != $1.date { return $0.date > $1.date }
      if $0.content != $1.content { return $0.content > $1.content }
      return $0.id < $1.id
    }
  }
}

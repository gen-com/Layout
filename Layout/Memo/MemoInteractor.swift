//
//  MemoInteractor.swift
//  Layout
//
//  Created by Byeongjo Koo.
//

import Foundation

struct MemoInteractor {
  
  // MARK: Dependencies
  
  private let store: MemoMemoryStore
  
  // MARK: Initialization
  
  init(store: MemoMemoryStore = .shared) {
    self.store = store
  }
  
  // MARK: CRUD
  
  @discardableResult
  func createMemoShiftEvent(content: String, on date: Date, pinned: Bool) -> Memo {
    let memo = Memo(
      id: UUID().uuidString,
      content: content,
      date: date,
      isPinned: pinned
    )
    store.upsert(memo)
    return memo
  }
  
  func updateMemoShiftEvent(
    memoID: Memo.ID,
    content: String,
    isPinned: Bool,
    on date: Date
  ) throws(Error) {
    let didUpdate = store.updateMemo(
      id: memoID,
      content: content,
      date: date,
      isPinned: isPinned
    )
    if didUpdate == false {
      throw Error.failedToUpdate
    }
  }
  
  func deleteMemoShiftEvent(memoID: Memo.ID) throws(Error) {
    let didDelete = store.deleteMemo(id: memoID)
    if didDelete == false {
      throw Error.failedToDelete
    }
  }
  
  func memo(with id: Memo.ID) -> Memo? {
    store.memo(with: id)
  }
  
  func fetchMemos() -> [Memo] {
    store.fetchMemos()
  }
}

// MARK: - Error

extension MemoInteractor {
  enum Error: Swift.Error {
    case failedToUpdate
    case failedToDelete
  }
}

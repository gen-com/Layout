//
//  MemoViewModel.swift
//  Layout
//
//  Created by Byeongjo Koo.
//

import Foundation

@MainActor
final class MemoViewModel {
  
  // MARK: Dependencies
  
  private let stickyMemoInteractor: MemoInteractor
  
  // MARK: Initialization
  
  init(
    stickyMemoInteractor: MemoInteractor = .init()
  ) {
    self.stickyMemoInteractor = stickyMemoInteractor
  }
  
  // MARK: Create
  
  func createMemo(with content: String, on date: Date, pinned: Bool) {
    _ = stickyMemoInteractor.createMemoShiftEvent(content: content, on: date, pinned: pinned)
  }
  
  // MARK: Update
  
  func updateMemo(_ memo: Memo, to updated: Memo) {
    do {
      try stickyMemoInteractor.updateMemoShiftEvent(
        memoID: memo.id,
        content: updated.content,
        isPinned: updated.isPinned,
        on: updated.date
      )
    } catch {
      // TODO: Error logging
      print(error)
    }
  }
  
  // MARK: Delete
  
  func deleteMemo(_ memo: Memo) {
    do {
      try stickyMemoInteractor.deleteMemoShiftEvent(memoID: memo.id)
    } catch {
      // TODO: Error logging
      print(error)
    }
  }
  
  // MARK: Query
  
  func fetchMemos(showPinnedOnly: Bool) -> [Memo] {
    stickyMemoInteractor.fetchMemos()
      .filter { showPinnedOnly == false || $0.isPinned }
  }
}

extension Memo {
  private var normalizedLines: [String] {
    content
      .components(separatedBy: .newlines)
      .map { $0.trimmingCharacters(in: .whitespaces) }
      .filter { $0.isEmpty == false }
  }
  
  var title: String {
    normalizedLines.first ?? "Untitled"
  }
  
  var bodyContent: String {
    normalizedLines.dropFirst().joined(separator: "\n")
  }
  
  var pinToggled: Memo {
    Memo(
      id: id,
      content: content,
      date: date,
      isPinned: !isPinned
    )
  }
  
  func updating(date: Date, content: String) -> Memo {
    Memo(
      id: id,
      content: content,
      date: date,
      isPinned: isPinned
    )
  }
}

//
//  WaterfallCollectionViewLayoutAttributes.swift
//  Layout
//
//  Created by Byeongjo Koo.
//

import UIKit

final class WaterfallCollectionViewLayoutAttributes: UICollectionViewLayoutAttributes {
  
  // MARK: Layout metadata
  
  nonisolated(unsafe) var column = 0
  
  // MARK: Update
  
  func apply(_ columnFrame: WaterfallCollectionViewLayout.ColumnLayoutFrame) {
    column = columnFrame.column
    frame = CGRect(origin: columnFrame.origin, size: columnFrame.size)
  }

  override func copy(with zone: NSZone? = nil) -> Any {
    guard let copiedAttributes = super.copy(with: zone) as? WaterfallCollectionViewLayoutAttributes
    else { return super.copy(with: zone) }

    copiedAttributes.column = column
    return copiedAttributes
  }

  nonisolated override func isEqual(_ object: Any?) -> Bool {
    guard let targetAttributes = object as? WaterfallCollectionViewLayoutAttributes,
          targetAttributes.column == column
    else { return false }

    return super.isEqual(object)
  }
}

//
//  WaterfallCollectionViewLayoutInvalidationContext.swift
//  Layout
//
//  Created by Byeongjo Koo.
//

import UIKit

final class WaterfallCollectionViewLayoutInvalidationContext: UICollectionViewLayoutInvalidationContext {
  enum Reason: Hashable {
    case fullReset
    case dataChanged(minIndexPath: IndexPath)
    case selfSizingChanged(indexPath: IndexPath, newHeight: CGFloat)
    case reconcile
  }
  
  var reasons = Set<Reason>()
}

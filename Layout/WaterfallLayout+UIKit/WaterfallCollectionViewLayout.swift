//
//  WaterfallCollectionViewLayout.swift
//  Layout
//
//  Created by Byeongjo Koo.
//

import UIKit

final class WaterfallCollectionViewLayout: UICollectionViewLayout {
  
  // MARK: Typealias
  
  fileprivate typealias InvalidationReason = WaterfallCollectionViewLayoutInvalidationContext.Reason
  
  // MARK: Layout state
  
  private let numberOfColumns: Int
  
  private var contentSize = CGSize.zero
  
  private var layoutAttributesDictionary = [IndexPath: WaterfallCollectionViewLayoutAttributes]()
  private var supplementaryAttributesDictionary = [IndexPath: UICollectionViewLayoutAttributes]()
  
  private var pendingReasons = Set<InvalidationReason>()
  
  // MARK: Creating the collection view layout
  
  init(numberOfColumns: Int = 2) {
    self.numberOfColumns = max(1, numberOfColumns)
    
    super.init()
  }
  
  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: Getting the collection view information
  
  override var collectionViewContentSize: CGSize {
    contentSize
  }
  
  private var collectionViewWidth: CGFloat {
    collectionView?.bounds.width ?? 0
  }
  
  private var numberOfSections: Int {
    collectionView?.numberOfSections ?? 0
  }
  
  private func numberOfItems(in section: Int) -> Int {
    collectionView?.numberOfItems(inSection: section) ?? 0
  }
  
  private var padding: CGFloat {
    scaledMetric(base: 8, minimum: 8, maximum: 16)
  }
  
  private var interItemSpacing: CGFloat {
    scaledMetric(base: 8, minimum: 8, maximum: 16)
  }
  
  private var estimatedItemHeight: CGFloat {
    scaledMetric(base: 160, minimum: 100, maximum: 240)
  }
  
  private var minimumItemHeight: CGFloat {
    scaledMetric(base: 64, minimum: 40, maximum: 80)
  }
  
  private var sectionHeaderHeight: CGFloat {
    scaledMetric(base: 32, minimum: 24, maximum: 54)
  }
  
  private var totalSpacingWidth: CGFloat {
    2 * padding + CGFloat(numberOfColumns - 1) * interItemSpacing
  }
  
  private var columnWidth: CGFloat {
    (collectionViewWidth - totalSpacingWidth) / CGFloat(numberOfColumns)
  }
  
  // MARK: Providing layout attributes
  
  override func prepare() {
    super.prepare()
    
    let width = collectionViewWidth
    guard width > 0
    else { return }
    
    let reasons = pendingReasons
    pendingReasons.removeAll()
    
    prepareCaches(for: reasons, width: width)
    rebuildAttributesIfNeeded(for: reasons)
    updateContentSize()
  }
  
  override class var layoutAttributesClass: AnyClass {
    WaterfallCollectionViewLayoutAttributes.self
  }
  
  override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
    var intersectedLayoutAttributes = layoutAttributesDictionary.values
      .filter { $0.frame.intersects(rect) }
      .compactMap { $0.copy() as? UICollectionViewLayoutAttributes }
    
    if let firstUncachedIndexPath {
      let extraIntersectedLayoutAttributes = buildAndCacheAttributes(
        startingAt: firstUncachedIndexPath,
        within: rect
      )
      intersectedLayoutAttributes += extraIntersectedLayoutAttributes
        .compactMap { $0.copy() as? UICollectionViewLayoutAttributes }
    }
    intersectedLayoutAttributes += intersectedSupplementaryAttributes(in: rect)
      .compactMap { $0.copy() as? UICollectionViewLayoutAttributes }
    return intersectedLayoutAttributes
  }
  
  override func layoutAttributesForItem(at indexPath: IndexPath) -> WaterfallCollectionViewLayoutAttributes? {
    layoutAttributesDictionary[indexPath]?.copy() as? WaterfallCollectionViewLayoutAttributes
  }
  
  override func layoutAttributesForSupplementaryView(
    ofKind elementKind: String,
    at indexPath: IndexPath
  ) -> UICollectionViewLayoutAttributes? {
    guard elementKind == UICollectionView.elementKindSectionHeader
    else { return nil }
    
    return supplementaryAttributesDictionary[indexPath]?.copy() as? UICollectionViewLayoutAttributes
  }
  
  // MARK: Responding to collection view updates
  
  override func prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) {
    super.prepare(forCollectionViewUpdates: updateItems)
    
    guard let minimumUpdatedIndexPath = minimumUpdatedIndexPath(in: updateItems)
    else {
      pendingReasons.insert(.reconcile)
      return
    }
    
    pendingReasons.insert(.dataChanged(minIndexPath: minimumUpdatedIndexPath))
  }
  
  // MARK: Invalidating the layout
  
  override func invalidateLayout() {
    pendingReasons.insert(.reconcile)
    
    super.invalidateLayout()
  }
  
  override func invalidationContext(
    forBoundsChange newBounds: CGRect
  ) -> UICollectionViewLayoutInvalidationContext {
    let baseContext = super.invalidationContext(forBoundsChange: newBounds)
    guard let context = baseContext as? WaterfallCollectionViewLayoutInvalidationContext
    else { return baseContext }
    
    let oldSize = collectionView?.bounds.size ?? CGSize.zero
    if oldSize != newBounds.size {
      let reason: InvalidationReason = (oldSize.width != newBounds.size.width)
      ? .fullReset
      : .reconcile
      context.reasons.insert(reason)
    }
    return context
  }
  
  override class var invalidationContextClass: AnyClass {
    WaterfallCollectionViewLayoutInvalidationContext.self
  }
  
  override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
    guard let oldBounds = collectionView?.bounds
    else { return true }
    
    return oldBounds.size != newBounds.size
  }
  
  override func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
    if let waterfallContext = context as? WaterfallCollectionViewLayoutInvalidationContext {
      pendingReasons.formUnion(waterfallContext.reasons)
    }
    
    super.invalidateLayout(with: context)
  }
  
  override func shouldInvalidateLayout(
    forPreferredLayoutAttributes preferredAttributes: UICollectionViewLayoutAttributes,
    withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes
  ) -> Bool {
    guard originalAttributes.representedElementCategory == .cell
    else { return false }
    
    let targetAttributes = layoutAttributesDictionary[originalAttributes.indexPath] ?? originalAttributes
    return preferredAttributes.frame.height != targetAttributes.frame.height
  }
  
  override func invalidationContext(
    forPreferredLayoutAttributes preferredAttributes: UICollectionViewLayoutAttributes,
    withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes
  ) -> WaterfallCollectionViewLayoutInvalidationContext {
    guard originalAttributes.representedElementCategory == .cell,
          let context = super.invalidationContext(
            forPreferredLayoutAttributes: preferredAttributes,
            withOriginalAttributes: originalAttributes
          ) as? WaterfallCollectionViewLayoutInvalidationContext
    else {
      return WaterfallCollectionViewLayoutInvalidationContext()
    }
    
    context.reasons.insert(
      .selfSizingChanged(
        indexPath: originalAttributes.indexPath,
        newHeight: preferredAttributes.frame.height
      )
    )
    return context
  }
  
  // MARK: External cache control
  
  func resetCache() {
    let context = WaterfallCollectionViewLayoutInvalidationContext()
    context.reasons.insert(.fullReset)
    invalidateLayout(with: context)
  }
}

// MARK: - Update and Invalidation Helpers

fileprivate extension WaterfallCollectionViewLayout {
  /// 지정 rect와 교차하는 supplementary attributes를 반환합니다.
  private func intersectedSupplementaryAttributes(in rect: CGRect) -> [UICollectionViewLayoutAttributes] {
    supplementaryAttributesDictionary.values.filter { $0.frame.intersects(rect) }
  }
  
  /// 업데이트 목록에서 재계산 시작에 사용할 최소 indexPath를 계산합니다.
  ///
  /// - Parameter updateItems: 컬렉션 뷰가 전달한 삽입/삭제/이동/리로드 업데이트 목록입니다.
  /// - Returns: 변경 영향이 시작되는 가장 작은 indexPath입니다.
  private func minimumUpdatedIndexPath(in updateItems: [UICollectionViewUpdateItem]) -> IndexPath? {
    let minimumBefore = updateItems.compactMap(\.indexPathBeforeUpdate).min()
    let minimumAfter = updateItems.compactMap(\.indexPathAfterUpdate).min()
    
    switch (minimumBefore, minimumAfter) {
    case let (before?, after?):
      return min(before, after)
    case let (before?, nil):
      return before
    case let (nil, after?):
      return after
    case (nil, nil):
      return nil
    }
  }
  
  /// `prepare` 시작 단계에서 캐시/폭/기본 contentSize 상태를 맞춥니다.
  ///
  /// - Parameters:
  ///   - reasons: 이번 prepare 사이클에서 적용할 무효화 이유 집합입니다.
  ///   - width: 현재 컬렉션 뷰의 유효 폭입니다.
  private func prepareCaches(for reasons: Set<InvalidationReason>, width: CGFloat) {
    if reasons.contains(.fullReset) {
      layoutAttributesDictionary.removeAll()
      supplementaryAttributesDictionary.removeAll()
      contentSize = CGSize(width: width, height: 0)
    } else {
      contentSize.width = width
      pruneInvalidCachedAttributes()
      pruneInvalidSupplementaryAttributes()
    }
  }
  
  /// 무효화 이유를 기반으로 필요한 범위만 재계산합니다.
  ///
  /// - Parameter reasons: 이번 prepare 사이클에서 처리할 무효화 이유 집합입니다.
  private func rebuildAttributesIfNeeded(for reasons: Set<InvalidationReason>) {
    if reasons.contains(.fullReset), let firstUncachedIndexPath {
      _ = buildAndCacheAttributes(startingAt: firstUncachedIndexPath, within: nil)
      return
    }
    
    if let minimumDataChangedIndexPath = minimumDataChangedIndexPath(from: reasons) {
      removeCachedAttributes(startingAt: minimumDataChangedIndexPath)
      _ = buildAndCacheAttributes(startingAt: minimumDataChangedIndexPath, within: nil)
      return
    }
    
    if let minimumSelfSizingChangedIndexPath = minimumSelfSizingChangedIndexPath(from: reasons) {
      applySelfSizingChanges(from: reasons)
      recalculateLayoutAttributes(after: minimumSelfSizingChangedIndexPath)
      return
    }
    
    guard reasons.contains(.reconcile)
    else { return }
    
    pruneInvalidCachedAttributes()
    pruneInvalidSupplementaryAttributes()
    if let firstUncachedIndexPath {
      _ = buildAndCacheAttributes(startingAt: firstUncachedIndexPath, within: nil)
    }
  }
  
  /// 데이터 변경 이유들 중 가장 앞선 indexPath를 찾아 부분 재계산 시작점으로 사용합니다.
  ///
  /// - Parameter reasons: 데이터 변경 관련 무효화 이유 집합입니다.
  /// - Returns: 부분 재계산 시작에 사용할 가장 작은 indexPath입니다.
  private func minimumDataChangedIndexPath(from reasons: Set<InvalidationReason>) -> IndexPath? {
    reasons.compactMap { reason in
      guard case let .dataChanged(minIndexPath) = reason
      else { return nil }
      
      return minIndexPath
    }.min()
  }
  
  /// self-sizing 이유들 중 가장 앞선 indexPath를 찾아 연쇄 재배치 시작점으로 사용합니다.
  ///
  /// - Parameter reasons: self-sizing 관련 무효화 이유 집합입니다.
  /// - Returns: 연쇄 재배치 시작에 사용할 가장 작은 indexPath입니다.
  private func minimumSelfSizingChangedIndexPath(from reasons: Set<InvalidationReason>) -> IndexPath? {
    reasons.compactMap { reason in
      guard case let .selfSizingChanged(indexPath, _) = reason
      else { return nil }
      
      return indexPath
    }.min()
  }
  
  /// self-sizing reason에 기록된 높이를 캐시 attributes에 우선 반영합니다.
  ///
  /// - Parameter reasons: self-sizing으로 전달된 indexPath/높이 정보 집합입니다.
  private func applySelfSizingChanges(from reasons: Set<InvalidationReason>) {
    for reason in reasons {
      guard case let .selfSizingChanged(indexPath, newHeight) = reason,
            let cachedAttributes = layoutAttributesDictionary[indexPath]
      else { continue }
      
      cachedAttributes.frame.size.height = max(minimumItemHeight, newHeight)
    }
  }
  
  /// 지정된 indexPath 이상에 해당하는 캐시 attributes를 제거합니다.
  ///
  /// - Parameter indexPath: 캐시 제거 시작 기준이 되는 indexPath입니다.
  private func removeCachedAttributes(startingAt indexPath: IndexPath) {
    for cachedIndexPath in layoutAttributesDictionary.keys where indexPath <= cachedIndexPath {
      layoutAttributesDictionary.removeValue(forKey: cachedIndexPath)
    }
  }
  
  /// 현재 데이터 소스에서 유효하지 않은 셀 캐시 key를 제거합니다.
  private func pruneInvalidCachedAttributes() {
    let invalidKeys = layoutAttributesDictionary.keys.filter { isValid(indexPath: $0) == false }
    for invalidKey in invalidKeys {
      layoutAttributesDictionary.removeValue(forKey: invalidKey)
    }
  }
  
  /// 존재하지 않는 섹션의 supplementary 캐시를 제거합니다.
  private func pruneInvalidSupplementaryAttributes() {
    let invalidKeys = supplementaryAttributesDictionary.keys.filter { indexPath in
      guard indexPath.section >= 0
      else { return true }
      
      return indexPath.section >= numberOfSections
    }
    for invalidKey in invalidKeys {
      supplementaryAttributesDictionary.removeValue(forKey: invalidKey)
    }
  }
  
  /// indexPath가 현재 데이터 소스 범위 내에 있는지 검증합니다.
  private func isValid(indexPath: IndexPath) -> Bool {
    guard indexPath.section >= 0,
          indexPath.item >= 0,
          indexPath.section < numberOfSections
    else { return false }
    
    return indexPath.item < numberOfItems(in: indexPath.section)
  }
}

// MARK: - Attribute Builders

fileprivate extension WaterfallCollectionViewLayout {
  /// 지정된 범위(`rect`) 내에 새로 표시되어야 할 아이템들의 레이아웃 속성을 계산하고 추가합니다.
  ///
  /// 기존 레이아웃 속성(`layoutAttributesDictionary`) 이후부터 시작하여,
  /// 주어진 범위와 교차하는 아이템에 대해 레이아웃 속성을 생성합니다.
  ///
  /// - Parameters:
  ///   - startIndexPath: 레이아웃 생성을 시작할 `indexPath`
  ///   - rect: 새로 레이아웃을 계산할 화면 영역
  /// - Returns: 새롭게 추가된 레이아웃 속성 배열
  func buildAndCacheAttributes(
    startingAt startIndexPath: IndexPath,
    within rect: CGRect?
  ) -> [WaterfallCollectionViewLayoutAttributes] {
    guard let normalizedStartIndexPath = firstExistingIndexPath(atOrAfter: startIndexPath)
    else { return [] }
    
    var addedLayoutAttributes = [WaterfallCollectionViewLayoutAttributes]()
    var currentIndexPath: IndexPath? = normalizedStartIndexPath
    var didAddAttributes = false
    var stateBySection = [Int: SectionLayoutState]()
    
    while let indexPath = currentIndexPath {
      defer { currentIndexPath = nextIndexPath(after: indexPath) }
      
      var sectionState = stateBySection[indexPath.section]
      ?? buildSectionLayoutState(for: indexPath.section, before: indexPath.item)
      
      if let cachedAttributes = layoutAttributesDictionary[indexPath] {
        sectionState.columnHeights[cachedAttributes.column] = max(
          sectionState.columnHeights[cachedAttributes.column],
          cachedAttributes.frame.maxY
        )
        stateBySection[indexPath.section] = sectionState
        continue
      }
      
      let layoutAttributes = buildAndCacheItemLayoutAttributes(
        at: indexPath,
        sectionState: &sectionState
      )
      stateBySection[indexPath.section] = sectionState
      didAddAttributes = true
      if let rect, layoutAttributes.frame.intersects(rect) == false {
        continue
      }
      addedLayoutAttributes.append(layoutAttributes)
    }
    
    if didAddAttributes {
      updateContentSize()
    }
    return addedLayoutAttributes
  }
  
  /// 하나의 아이템에 대한 레이아웃 attributes를 생성하고 캐시에 저장합니다.
  ///
  /// - Parameters:
  ///   - indexPath: attributes를 생성할 대상 아이템의 indexPath입니다.
  ///   - sectionState: 해당 섹션의 현재 컬럼 높이 상태입니다.
  /// - Returns: 생성되어 캐시에 저장된 아이템 attributes입니다.
  private func buildAndCacheItemLayoutAttributes(
    at indexPath: IndexPath,
    sectionState: inout SectionLayoutState
  ) -> WaterfallCollectionViewLayoutAttributes {
    let rawHeight = layoutAttributesDictionary[indexPath]?.frame.height ?? estimatedItemHeight
    let itemHeight = max(minimumItemHeight, rawHeight)
    let nextColumnFrame = placeNextItem(itemHeight: itemHeight, in: &sectionState)
    let layoutAttributes = WaterfallCollectionViewLayoutAttributes(forCellWith: indexPath)
    layoutAttributes.apply(nextColumnFrame)
    layoutAttributesDictionary[indexPath] = layoutAttributes
    return layoutAttributes
  }
  
  /// 특정 섹션의 특정 item 이전까지 반영된 컬럼 높이 상태를 복원합니다.
  ///
  /// - Parameters:
  ///   - section: 복원 대상 섹션 번호입니다.
  ///   - item: 기준 아이템 인덱스입니다. 이 인덱스 이전 아이템까지 반영합니다.
  /// - Returns: 기준 시점까지 복원된 섹션 레이아웃 상태입니다.
  func buildSectionLayoutState(for section: Int, before item: Int) -> SectionLayoutState {
    let sectionTop = sectionStartY(for: section)
    let itemTop = ensureSectionHeaderIfNeeded(at: section, sectionTop: sectionTop)
    var columnHeights = [CGFloat](repeating: itemTop, count: numberOfColumns)
    for attributes in layoutAttributesDictionary.values
    where
    attributes.indexPath.section == section &&
    attributes.indexPath.item < item {
      columnHeights[attributes.column] = max(columnHeights[attributes.column], attributes.frame.maxY)
    }
    return SectionLayoutState(sectionTop: itemTop, columnHeights: columnHeights)
  }
  
  /// 가장 낮은 컬럼을 선택해 다음 아이템 프레임을 계산하고 상태를 전진시킵니다.
  ///
  /// - Parameters:
  ///   - itemHeight: 배치할 아이템 높이입니다.
  ///   - state: 배치 전 컬럼 높이 상태이며, 배치 후 상태로 갱신됩니다.
  /// - Returns: 선택된 컬럼과 계산된 프레임 정보입니다.
  func placeNextItem(itemHeight: CGFloat, in state: inout SectionLayoutState) -> ColumnLayoutFrame {
    var shortestColumn = 0
    var minColumnHeight = CGFloat.greatestFiniteMagnitude
    for (column, columnHeight) in state.columnHeights.enumerated() where columnHeight < minColumnHeight {
      minColumnHeight = columnHeight
      shortestColumn = column
    }
    
    let xOffset = padding + CGFloat(shortestColumn) * (columnWidth + interItemSpacing)
    let yOffset = (minColumnHeight == state.sectionTop) ? state.sectionTop : (minColumnHeight + interItemSpacing)
    let frame = CGRect(x: xOffset, y: yOffset, width: columnWidth, height: itemHeight)
    state.columnHeights[shortestColumn] = frame.maxY
    return ColumnLayoutFrame(column: shortestColumn, frame: frame)
  }
  
  /// 특정 `indexPath` 이후의 아이템들에 대해 레이아웃 속성을 재계산합니다.
  ///
  /// - Parameter indexPath: 기준이 되는 아이템의 `indexPath`
  ///
  /// 이 메서드는 아이템의 레이아웃이 바뀌었을 때, 연쇄적인 영향을 반영하기 위해 사용됩니다.
  func recalculateLayoutAttributes(after indexPath: IndexPath) {
    var followingIndexPath = nextIndexPath(after: indexPath)
    var stateBySection = [Int: SectionLayoutState]()
    while let currentIndexPath = followingIndexPath {
      defer { followingIndexPath = nextIndexPath(after: currentIndexPath) }
      
      guard let targetAttributes = layoutAttributesDictionary[currentIndexPath]
      else { continue }
      
      var sectionState = stateBySection[currentIndexPath.section]
      ?? buildSectionLayoutState(for: currentIndexPath.section, before: currentIndexPath.item)
      
      let nextColumnFrame = placeNextItem(
        itemHeight: targetAttributes.frame.height,
        in: &sectionState
      )
      targetAttributes.apply(nextColumnFrame)
      stateBySection[currentIndexPath.section] = sectionState
    }
    updateContentSize()
  }
  
  /// 현재 레이아웃 속성들을 기준으로 컬렉션 뷰의 전체 콘텐츠 크기를 업데이트합니다.
  ///
  /// 모든 아이템의 최대 Y값을 기준으로 `contentSize.height`를 갱신합니다.
  func updateContentSize() {
    if layoutAttributesDictionary.isEmpty {
      contentSize.height = 0
    } else {
      let layoutAttributesMaxY = layoutAttributesDictionary.values.map(\.frame.maxY).max() ?? contentSize.height
      contentSize.height = layoutAttributesMaxY + padding
    }
  }
}

// MARK: - Layout Navigation and Geometry Helpers

fileprivate extension WaterfallCollectionViewLayout {
  /// 기준 폭 대비 비율로 크기를 스케일링합니다.
  ///
  /// - Parameters:
  ///   - base: 기준 폭에서의 기본 값입니다.
  ///   - minimum: 허용 가능한 최소 값입니다.
  ///   - maximum: 허용 가능한 최대 값입니다.
  /// - Returns: 현재 컬렉션 뷰 폭에 맞게 스케일링된 값입니다.
  private func scaledMetric(base: CGFloat, minimum: CGFloat, maximum: CGFloat) -> CGFloat {
    let referenceWidth: CGFloat = 390
    let width = max(320, collectionViewWidth)
    let scaled = base * (width / referenceWidth)
    return min(maximum, max(minimum, scaled.rounded()))
  }
  
  // MARK: IndexPath traversal
  
  /// 아직 캐시되지 않은 가장 앞 indexPath를 찾습니다.
  private var firstUncachedIndexPath: IndexPath? {
    for section in 0..<numberOfSections {
      for item in 0..<numberOfItems(in: section) {
        let indexPath = IndexPath(item: item, section: section)
        if layoutAttributesDictionary[indexPath] == nil {
          return indexPath
        }
      }
    }
    return nil
  }
  
  /// 주어진 indexPath 이상에서 실제로 존재하는 첫 아이템 indexPath를 반환합니다.
  ///
  /// - Parameter indexPath: 탐색 시작 기준 indexPath입니다.
  /// - Returns: 데이터 소스에 실제로 존재하는 첫 indexPath입니다. 없으면 nil입니다.
  private func firstExistingIndexPath(atOrAfter indexPath: IndexPath) -> IndexPath? {
    guard numberOfSections > 0,
          indexPath.section < numberOfSections
    else { return nil }
    
    for section in indexPath.section..<numberOfSections {
      let sectionItemCount = numberOfItems(in: section)
      guard sectionItemCount > 0
      else { continue }
      
      let startItem = (section == indexPath.section) ? indexPath.item : 0
      if startItem < sectionItemCount {
        return IndexPath(item: startItem, section: section)
      }
    }
    return nil
  }
  
  /// 현재 indexPath 다음 순회 대상 indexPath를 반환합니다(섹션 경계 포함).
  ///
  /// - Parameter indexPath: 현재 기준 indexPath입니다.
  /// - Returns: 다음 아이템 indexPath입니다. 더 이상 없으면 nil입니다.
  private func nextIndexPath(after indexPath: IndexPath) -> IndexPath? {
    guard indexPath.section < numberOfSections
    else { return nil }
    
    let nextItem = indexPath.item + 1
    if nextItem < numberOfItems(in: indexPath.section) {
      return IndexPath(item: nextItem, section: indexPath.section)
    }
    
    guard indexPath.section + 1 < numberOfSections
    else { return nil }
    
    return firstExistingIndexPath(atOrAfter: IndexPath(item: 0, section: indexPath.section + 1))
  }
  
  /// 섹션 헤더가 활성화된 경우 attributes를 보장하고, 실제 아이템 시작 Y를 반환합니다.
  ///
  /// - Parameters:
  ///   - section: 헤더를 보장할 섹션 번호입니다.
  ///   - sectionTop: 해당 섹션의 시작 기준 Y 값입니다.
  /// - Returns: 헤더를 포함한 실제 아이템 시작 Y 값입니다.
  private func ensureSectionHeaderIfNeeded(at section: Int, sectionTop: CGFloat) -> CGFloat {
    guard sectionHeaderHeight > 0 else {
      supplementaryAttributesDictionary.removeValue(forKey: IndexPath(item: 0, section: section))
      return sectionTop
    }
    
    let headerIndexPath = IndexPath(item: 0, section: section)
    let headerAttributes = supplementaryAttributesDictionary[headerIndexPath]
    ?? UICollectionViewLayoutAttributes(
      forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
      with: headerIndexPath
    )
    headerAttributes.frame = CGRect(
      x: padding,
      y: sectionTop,
      width: max(0, collectionViewWidth - 2 * padding),
      height: sectionHeaderHeight
    )
    headerAttributes.zIndex = 2
    supplementaryAttributesDictionary[headerIndexPath] = headerAttributes
    return headerAttributes.frame.maxY + interItemSpacing
  }
  
  // MARK: Section positioning
  
  /// 이전 섹션들의 최대 Y를 기반으로 현재 섹션 시작 Y를 계산합니다.
  ///
  /// - Parameter section: 시작 위치를 계산할 섹션 번호입니다.
  /// - Returns: 지정한 섹션의 시작 Y 값입니다.
  private func sectionStartY(for section: Int) -> CGFloat {
    guard section > 0 else { return padding }
    
    var previousSectionsMaxY: CGFloat = 0
    for (indexPath, attributes) in layoutAttributesDictionary where indexPath.section < section {
      previousSectionsMaxY = max(previousSectionsMaxY, attributes.frame.maxY)
    }
    for (indexPath, attributes) in supplementaryAttributesDictionary where indexPath.section < section {
      previousSectionsMaxY = max(previousSectionsMaxY, attributes.frame.maxY)
    }
    return previousSectionsMaxY + padding
  }
}

// MARK: - Layout subtype

extension WaterfallCollectionViewLayout {
  /// 섹션별 배치 진행 상태를 표현합니다.
  struct SectionLayoutState {
    let sectionTop: CGFloat
    var columnHeights: [CGFloat]
  }
  
  /// 특정 컬럼에 배치될 아이템의 위치 및 크기 정보를 나타냅니다.
  ///
  /// 이 구조체는 컬럼 번호(`column`), 시작 좌표(`origin`), 크기(`size`)를 포함하며,
  /// CGRect와 유사한 속성과 교차 여부 판단 기능도 제공합니다.
  struct ColumnLayoutFrame {
    var column: Int
    var origin: CGPoint
    var size: CGSize
    
    init(column: Int, frame: CGRect) {
      self.column = column
      self.origin = frame.origin
      self.size = frame.size
    }
  }
}

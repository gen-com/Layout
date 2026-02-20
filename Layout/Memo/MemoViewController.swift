//
//  MemoViewController.swift
//  Layout
//
//  Created by Byeongjo Koo.
//

import UIKit

final class MemoViewController: UIViewController {
  
  // MARK: View model
  
  private let viewModel = MemoViewModel()
  private let dummyDataGenerator = MemoDummyDataGenerator()
  
  // MARK: Subviews
  
  private lazy var memoCollectionView: UICollectionView = {
    let layout = WaterfallCollectionViewLayout(numberOfColumns: Numerics.waterfallLayoutNumberOfColumns)
    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    collectionView.delegate = self
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    return collectionView
  }()
  
  private lazy var pinFilterButton: UIButton = {
    let button = UIButton(frame: CGRect(origin: .zero, size: Metrics.pinFilterButtonSize))
    button.setImage(UIImage(named: "unpinned-nav")?.withTintColor(.black), for: .normal)
    button.setImage(UIImage(named: "pinned-nav")?.withTintColor(.black), for: .selected)
    button.addAction(
      UIAction { [weak self] _ in self?.togglePinFilterButtonDidTap() },
      for: .primaryActionTriggered
    )
    return button
  }()
  
  private lazy var createMemoButton: UIButton = {
    let symbolConfiguration = UIImage.SymbolConfiguration(weight: .bold)
    let plusImage = UIImage(systemName: "plus", withConfiguration: symbolConfiguration)
    var configuration = UIButton.Configuration.glass()
    configuration.cornerStyle = .capsule
    configuration.image = plusImage
    
    let button = UIButton(configuration: configuration)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.addAction(
      UIAction { [weak self] _ in self?.createMemoButtonDidTap() },
      for: .primaryActionTriggered
    )
    return button
  }()
  
  // MARK: DataSource
  
  fileprivate enum MemoSection: String, Hashable {
    case pinned
    case normal
    
    /// 섹션 헤더에 표시할 사용자 노출 제목입니다.
    var title: String {
      switch self {
      case .pinned:
        return Texts.pinnedSectionTitle
      case .normal:
        return Texts.normalSectionTitle
      }
    }
  }
  
  private typealias MemoDataSource = UICollectionViewDiffableDataSource<MemoSection, String>
  private typealias MemoSnapshot = NSDiffableDataSourceSnapshot<MemoSection, String>
  
  private typealias CellRegistration = UICollectionView.CellRegistration<MemoCollectionViewCell, String>
  private typealias HeaderRegistration = UICollectionView.SupplementaryRegistration<MemoSectionHeaderView>
  
  /// ViewModel 결과를 snapshot으로 변환해 data source에 전달합니다.
  private lazy var memoProvider: MemoDataProvider = {
    let provider = MemoDataProvider(viewModel: viewModel)
    provider.onSnapshot = { [weak self] snapshot in
      self?.apply(snapshot: snapshot)
    }
    return provider
  }()
  
  private var cellRegistration: CellRegistration?
  private var headerRegistration: HeaderRegistration?
  
  /// 셀/헤더 재사용 등록을 기반으로 diffable data source를 구성합니다.
  private lazy var memoDataSource: MemoDataSource = {
    let dataSource = MemoDataSource(collectionView: memoCollectionView) {
      [weak self] collectionView, indexPath, itemID in
      guard let self, let cellRegistration = self.cellRegistration else { return UICollectionViewCell() }
      
      return collectionView.dequeueConfiguredReusableCell(
        using: cellRegistration,
        for: indexPath,
        item: itemID
      )
    }
    dataSource.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
      guard let self,
            let headerRegistration = self.headerRegistration,
            kind == UICollectionView.elementKindSectionHeader
      else { return nil }
      let headerView = collectionView.dequeueConfiguredReusableSupplementary(
        using: headerRegistration,
        for: indexPath
      )
      let sections = self.memoDataSource.snapshot().sectionIdentifiers
      if indexPath.section < sections.count {
        headerView.configure(title: sections[indexPath.section].title)
      }
      return headerView
    }
    return dataSource
  }()
  
  private func apply(snapshot: MemoSnapshot, animatingDifferences: Bool = true) {
    memoDataSource.apply(snapshot, animatingDifferences: animatingDifferences) { [memoCollectionView] in
      memoCollectionView.collectionViewLayout.invalidateLayout()
    }
    setNeedsUpdateContentUnavailableConfiguration()
  }
  
  // MARK: Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    view.backgroundColor = .systemBackground
    
    setUpSubviews()
    setUpSubviewsLayouts()
    
    setUpCellRegistration()
    setUpHeaderRegistration()
    
    fetchMemos()
  }
  
  // MARK: Cell registration set up
  
  private func setUpCellRegistration() {
    cellRegistration = CellRegistration { [weak self] cell, _, memoID in
      self?.configure(cell: cell, memoID: memoID)
    }
  }
  
  private func setUpHeaderRegistration() {
    headerRegistration = HeaderRegistration(
      elementKind: UICollectionView.elementKindSectionHeader
    ) { _, _, _ in }
  }
  
  // MARK: Subviews set up
  
  private func setUpSubviews() {
    view.addSubview(memoCollectionView)
    view.addSubview(createMemoButton)
  }
  
  private func setUpSubviewsLayouts() {
    setUpMemoCollectionViewLayouts()
    setUpCreateMemoButtonLayouts()
  }
  
  private func setUpMemoCollectionViewLayouts() {
    NSLayoutConstraint.activate(
      [
        memoCollectionView.topAnchor.constraint(
          equalTo: view.safeAreaLayoutGuide.topAnchor
        ),
        memoCollectionView.leadingAnchor.constraint(
          equalTo: view.safeAreaLayoutGuide.leadingAnchor
        ),
        memoCollectionView.trailingAnchor.constraint(
          equalTo: view.safeAreaLayoutGuide.trailingAnchor
        ),
        memoCollectionView.bottomAnchor.constraint(
          equalTo: view.safeAreaLayoutGuide.bottomAnchor
        ),
      ]
    )
  }
  
  private func setUpCreateMemoButtonLayouts() {
    NSLayoutConstraint.activate([
      createMemoButton.trailingAnchor
        .constraint(
          equalTo: view.trailingAnchor,
          constant: Metrics.createMemoButtonTrailingInset
        ),
      createMemoButton.bottomAnchor
        .constraint(
          equalTo: view.safeAreaLayoutGuide.bottomAnchor,
          constant: Metrics.createMemoButtonBottomInset
        ),
      createMemoButton.widthAnchor
        .constraint(
          equalToConstant: Metrics.createMemoButtonSize.width
        ),
      createMemoButton.heightAnchor
        .constraint(
          equalToConstant: Metrics.createMemoButtonSize.height
        ),
    ])
  }
  
  // MARK: Update memo collection
  
  private func fetchMemos() {
    memoProvider.performInitialFetch(showPinnedOnly: pinFilterButton.isSelected)
  }
  
  /// 저장소 최신값으로 snapshot을 재구성합니다.
  private func reloadMemos() {
    memoProvider.reload()
  }
  
  /// 데이터 유무에 따라 empty state UI를 갱신합니다.
  override func updateContentUnavailableConfiguration(
    using state: UIContentUnavailableConfigurationState
  ) {
    super.updateContentUnavailableConfiguration(using: state)
    
    if memoDataSource.snapshot().itemIdentifiers.isEmpty {
      let fontSize = FontSize.emptyStateViewLabel
      var config = UIContentUnavailableConfiguration.empty()
      config.text = Texts.emptyMemoState
      config.textProperties.color = .secondaryLabel
      config.textProperties.font = .systemFont(ofSize: fontSize, weight: .medium)
      config.background = .clear()
      contentUnavailableConfiguration = config
    } else {
      contentUnavailableConfiguration = nil
    }
  }
  
  // MARK: Memo control
  
  private func createMemo(content: String, date: Date) {
    viewModel.createMemo(with: content, on: date, pinned: pinFilterButton.isSelected)
    reloadMemos()
  }
  
  private func updateMemo(item: Memo, content: String, date: Date) {
    let updatedMemo = item.updating(date: date, content: content)
    viewModel.updateMemo(item, to: updatedMemo)
    reloadMemos()
  }
  
  private func togglePinMemo(with memoID: String) {
    guard let memoItem = memoItem(for: memoID) else { return }
    let toggledMemo = memoItem.pinToggled
    viewModel.updateMemo(memoItem, to: toggledMemo)
    reloadMemos()
  }
  
  private func configure(cell: MemoCollectionViewCell, memoID: String) {
    guard let memoItem = memoItem(for: memoID) else { return }
    cell.configure(memo: memoItem)
    cell.setOnPinAction { [weak self] _ in
      self?.togglePinMemo(with: memoID)
    }
  }
  
  private func memoItem(for memoID: String) -> Memo? {
    memoProvider.memoItem(for: memoID)
  }
  
  private func memoItem(at indexPath: IndexPath) -> Memo? {
    guard let memoID = memoDataSource.itemIdentifier(for: indexPath) else { return nil }
    return memoItem(for: memoID)
  }
  
  // MARK: Action - toggle pin filter
  
  private func togglePinFilterButtonDidTap() {
    pinFilterButton.isSelected.toggle()
    
    memoProvider.updateFilter(showPinnedOnly: pinFilterButton.isSelected)
  }
  
  // MARK: Action - creating memo
  
  private func createMemoButtonDidTap() {
    let sampleMemo = dummyDataGenerator.generateMemoSample()
    createMemo(content: sampleMemo.content, date: sampleMemo.date)
  }
  
  // MARK: Action - deleting memo
  
  private func presentDeleteAlert(for memoItem: Memo) {
    let alert = UIAlertController(
      title: nil,
      message: Texts.memoDeletionWarning,
      preferredStyle: .alert
    )
    alert.addAction(UIAlertAction(title: Texts.delete, style: .destructive) { [weak self] _ in
      guard let self else { return }
      
      self.viewModel.deleteMemo(memoItem)
      self.reloadMemos()
    })
    alert.addAction(UIAlertAction(title: Texts.cancel, style: .cancel))
    
    present(alert, animated: true)
  }
}

// MARK: - UICollectionViewDelegate conformance

extension MemoViewController: UICollectionViewDelegate {
  func collectionView(
    _ collectionView: UICollectionView,
    contextMenuConfigurationForItemsAt indexPaths: [IndexPath],
    point: CGPoint
  ) -> UIContextMenuConfiguration? {
    guard let targetIndexPath = indexPaths.first,
          let targetMemoItem = memoItem(at: targetIndexPath)
    else { return nil }
    
    let contextMenuConfiguration = UIContextMenuConfiguration(
      identifier: targetIndexPath as NSIndexPath,
      previewProvider: nil
    ) { [weak self] _ in
      let deleteAction = UIAction(
        title: Texts.delete,
        image: UIImage(systemName: "trash"),
        attributes: .destructive
      ) { _ in
        self?.presentDeleteAlert(for: targetMemoItem)
      }
      return UIMenu(title: "", children: [deleteAction])
    }
    return contextMenuConfiguration
  }
}

extension MemoViewController {
  @MainActor
  fileprivate final class MemoDataProvider {
    typealias Snapshot = NSDiffableDataSourceSnapshot<MemoSection, String>
    
    var onSnapshot: ((Snapshot) -> Void)?
    
    private let viewModel: MemoViewModel
    private var isPinnedFilterEnabled = false
    private var memoCache: [String: Memo] = [:]
    
    init(
      viewModel: MemoViewModel
    ) {
      self.viewModel = viewModel
    }
    
    func performInitialFetch(showPinnedOnly: Bool) {
      isPinnedFilterEnabled = showPinnedOnly
      sendSnapshot()
    }
    
    func updateFilter(showPinnedOnly: Bool) {
      guard isPinnedFilterEnabled != showPinnedOnly else { return }
      isPinnedFilterEnabled = showPinnedOnly
      sendSnapshot()
    }
    
    func reload() {
      sendSnapshot(forceReconfigure: true)
    }
    
    func memoItem(for id: String) -> Memo? {
      memoCache[id]
    }
    
    private func sendSnapshot(forceReconfigure: Bool = false) {
      let combinedItems = viewModel.fetchMemos(showPinnedOnly: isPinnedFilterEnabled)
      memoCache = Dictionary(uniqueKeysWithValues: combinedItems.map { ($0.id, $0) })
      let pinnedItemIDs = combinedItems.filter(\.isPinned).map(\.id)
      let normalItemIDs = combinedItems.filter { $0.isPinned == false }.map(\.id)
      
      var snapshot = Snapshot()
      if pinnedItemIDs.isEmpty == false {
        snapshot.appendSections([.pinned])
        snapshot.appendItems(pinnedItemIDs, toSection: .pinned)
      }
      if normalItemIDs.isEmpty == false {
        snapshot.appendSections([.normal])
        snapshot.appendItems(normalItemIDs, toSection: .normal)
      }
      if forceReconfigure {
        snapshot.reconfigureItems(snapshot.itemIdentifiers)
      }
      onSnapshot?(snapshot)
    }
  }
}

// MARK: - Constants

fileprivate extension MemoViewController {
  @MainActor
  enum FontSize {
    static let emptyStateViewLabel: CGFloat = 16
  }
  
  enum Metrics {
    static let pinFilterButtonSize = CGSize(width: 40, height: 40)
    
    static let createMemoButtonTrailingInset: CGFloat = -16
    static let createMemoButtonBottomInset: CGFloat = -16
    static let createMemoButtonSize = CGSize(width: 54, height: 54)
    
  }
  
  enum Numerics {
    static let waterfallLayoutNumberOfColumns = 2
  }
  
  enum Texts {
    static let viewTitle = "note"
    static let pinnedSectionTitle = "Pinned"
    static let normalSectionTitle = "All Notes"
    
    static let emptyMemoState = "No Memo"
    
    static let memoDeletionWarning = "Delete this memo? This action can't be undone."
    static let delete = "Delete"
    static let cancel = "Cancel"
  }
}

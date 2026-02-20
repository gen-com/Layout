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
  
  // MARK: Subviews
  
  private lazy var memoCollectionView: UICollectionView = {
    let layout = WaterfallMemoCollectionViewLayout(numberOfColumns: Numerics.waterfallLayoutNumberOfColumns)
    
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
  private let headerRegistration = HeaderRegistration(
    elementKind: WaterfallMemoCollectionViewLayout.sectionHeaderElementKind
  ) { _, _, _ in }
  
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
            kind == WaterfallMemoCollectionViewLayout.sectionHeaderElementKind
      else { return nil }
      let headerView = collectionView.dequeueConfiguredReusableSupplementary(
        using: self.headerRegistration,
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
  
  /// 최신 snapshot을 적용하고, 커스텀 레이아웃 캐시를 안전하게 무효화합니다.
  private func apply(snapshot: MemoSnapshot, animatingDifferences: Bool = true) {
    if let waterfallLayout = memoCollectionView.collectionViewLayout as? WaterfallMemoCollectionViewLayout {
      waterfallLayout.resetCache()
    }

    memoDataSource.apply(snapshot, animatingDifferences: animatingDifferences) { [weak self] in
      guard let self else { return }
      self.memoCollectionView.collectionViewLayout.invalidateLayout()
    }
    setNeedsUpdateContentUnavailableConfiguration()
  }
  
  // MARK: Lifecycle
  
  /// 뷰 계층/레이아웃/등록을 초기화하고 첫 데이터를 로드합니다.
  override func viewDidLoad() {
    super.viewDidLoad()
    
    view.backgroundColor = .systemBackground
    
    setUpSubviews()
    setUpSubviewsLayouts()
    setUpCellRegistration()
    
    fetchMemos()
  }
  
  // MARK: Cell registration set up
  
  /// 셀 구성 클로저를 등록해 memoID -> cell rendering 경로를 연결합니다.
  private func setUpCellRegistration() {
    cellRegistration = CellRegistration { [weak self] cell, _, memoID in
      self?.configure(cell: cell, memoID: memoID)
    }
  }
  
  // MARK: Subviews set up
  
  /// 화면에 필요한 subview를 추가합니다.
  private func setUpSubviews() {
    view.addSubview(memoCollectionView)
    view.addSubview(createMemoButton)
  }
  
  // MARK: Subviews Layouts
  
  /// 서브뷰 오토레이아웃 제약을 구성합니다.
  private func setUpSubviewsLayouts() {
    setUpMemoCollectionViewLayouts()
    setUpCreateMemoButtonLayouts()
  }
  
  /// 컬렉션 뷰를 safe area 전체에 고정합니다.
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
  
  /// 생성 버튼을 우하단 플로팅 위치에 배치합니다.
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
  
  /// 현재 필터 상태로 초기 메모 목록을 요청합니다.
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
  
  /// 새 메모를 생성하고 목록을 갱신합니다.
  private func createMemo(content: String, date: Date) {
    viewModel.createMemo(with: content, on: date, pinned: pinFilterButton.isSelected)
    reloadMemos()
  }
  
  /// 기존 메모 내용을 업데이트하고 목록을 갱신합니다.
  private func updateMemo(item: Memo, content: String, date: Date) {
    let updatedMemo = item.updating(date: date, content: content)
    viewModel.updateMemo(item, to: updatedMemo)
    reloadMemos()
  }
  
  /// 메모 pin 상태를 토글하고 목록을 갱신합니다.
  private func togglePinMemo(with memoID: String) {
    guard let memoItem = memoItem(for: memoID) else { return }
    let toggledMemo = memoItem.pinToggled
    viewModel.updateMemo(memoItem, to: toggledMemo)
    reloadMemos()
  }
  
  /// memoID로 모델을 조회해 셀 콘텐츠와 pin 액션을 연결합니다.
  private func configure(cell: MemoCollectionViewCell, memoID: String) {
    guard let memoItem = memoItem(for: memoID) else { return }
    cell.configure(memo: memoItem)
    cell.setOnPinAction { [weak self] _ in
      self?.togglePinMemo(with: memoID)
    }
  }
  
  /// ID 기반 캐시 조회를 래핑합니다.
  private func memoItem(for memoID: String) -> Memo? {
    memoProvider.memoItem(for: memoID)
  }
  
  /// indexPath -> itemID -> 모델 조회 순서로 현재 메모를 반환합니다.
  private func memoItem(at indexPath: IndexPath) -> Memo? {
    guard let memoID = memoDataSource.itemIdentifier(for: indexPath) else { return nil }
    return memoItem(for: memoID)
  }
  
  // MARK: Action - toggle pin filter
  
  /// pin-only 필터를 토글하고 provider 필터를 갱신합니다.
  private func togglePinFilterButtonDidTap() {
    pinFilterButton.isSelected.toggle()
    
    memoProvider.updateFilter(showPinnedOnly: pinFilterButton.isSelected)
  }
  
  // MARK: Action - creating memo
  
  /// 샘플 텍스트 기반 임시 메모를 생성하는 테스트 액션입니다.
  private func createMemoButtonDidTap() {
    let content = makeRandomMemoContent()

    let randomSecondsInWeek = TimeInterval(Int.random(in: 0...(7 * 24 * 60 * 60)))
    let randomDate = Date().addingTimeInterval(-randomSecondsInWeek)
    createMemo(content: content, date: randomDate)
  }

  /// 랜덤 제목/본문 조합으로 가변 길이 샘플 메모 본문을 생성합니다.
  private func makeRandomMemoContent() -> String {
    let title = Texts.randomMemoTitles.randomElement() ?? "Untitled"
    let short = Texts.randomMemoBodiesShort.randomElement() ?? ""
    let medium = Texts.randomMemoBodiesMedium.randomElement() ?? ""
    let long = Texts.randomMemoBodiesLong.randomElement() ?? ""

    let body: String
    switch Int.random(in: 0...4) {
    case 0:
      body = short
    case 1, 2:
      body = medium
    default:
      body = [medium, long].joined(separator: "\n\n")
    }

    return [title, body]
      .filter { $0.isEmpty == false }
      .joined(separator: "\n")
  }
  
  // MARK: Action - deleting memo
  
  /// 삭제 확인 얼럿을 표시하고 확정 시 메모를 삭제합니다.
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
  /// 선택된 아이템에 대한 컨텍스트 메뉴(삭제)를 제공합니다.
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

private final class MemoSectionHeaderView: UICollectionReusableView {
  private let titleLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = .systemFont(ofSize: 17, weight: .semibold)
    label.textColor = .label
    return label
  }()
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setUpSubviews()
    setUpLayouts()
  }
  
  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  /// 헤더 제목 텍스트를 갱신합니다.
  func configure(title: String) {
    titleLabel.text = title
  }
  
  /// 헤더 하위 뷰를 추가합니다.
  private func setUpSubviews() {
    addSubview(titleLabel)
  }
  
  /// 제목 라벨을 헤더 경계에 맞춰 배치합니다.
  private func setUpLayouts() {
    NSLayoutConstraint.activate([
      titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
      titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
      titleLabel.topAnchor.constraint(equalTo: topAnchor),
      titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
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
    
    /// 초기 필터를 반영해 첫 snapshot을 발행합니다.
    func performInitialFetch(showPinnedOnly: Bool) {
      isPinnedFilterEnabled = showPinnedOnly
      sendSnapshot()
    }
    
    /// pin 필터 변경 시 snapshot을 다시 발행합니다.
    func updateFilter(showPinnedOnly: Bool) {
      guard isPinnedFilterEnabled != showPinnedOnly else { return }
      isPinnedFilterEnabled = showPinnedOnly
      sendSnapshot()
    }
    
    /// 현재 아이템을 유지한 채 셀 재구성을 유도하는 snapshot을 발행합니다.
    func reload() {
      sendSnapshot(forceReconfigure: true)
    }
    
    /// 렌더링/액션 처리용 메모 캐시 조회를 제공합니다.
    func memoItem(for id: String) -> Memo? {
      memoCache[id]
    }
    
    /// ViewModel 결과를 pinned/normal 섹션 snapshot으로 변환해 전달합니다.
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

    static let randomMemoTitles: [String] = [
      "Meeting Notes",
      "Quick Idea",
      "Today Reminder",
      "Shopping List",
      "Workout Plan",
      "Travel Plan"
    ]

    static let randomMemoBodiesShort: [String] = [
      "Call Alex at 3 PM.",
      "Buy milk and eggs.",
      "Draft intro paragraph.",
      "Stretch for 10 minutes."
    ]

    static let randomMemoBodiesMedium: [String] = [
      "Check progress and share updates before noon.\nFocus on blockers first and propose one concrete next step.",
      "Organize tasks by priority and deadline.\nStart with the smallest task to build momentum.",
      "Book tickets and confirm accommodation details.\nKeep all reservation numbers in one note.",
      "Review this week goals and adjust tomorrow plan.\nLeave a short buffer for unexpected work."
    ]

    static let randomMemoBodiesLong: [String] = [
      "Project A: finalize scope and confirm ownership for each deliverable.\nProject B: capture open questions and schedule a review session.\nPersonal: clean workspace, back up laptop, and prepare materials for tomorrow.\n\nIf time allows, write a short retrospective about what worked well this week and what should change next week.",
      "Morning routine:\n1) 20-minute run\n2) shower and breakfast\n3) planning session for top three outcomes.\n\nWork block:\n- complete API integration\n- verify error handling paths\n- update documentation with examples.\n\nEvening:\n- quick grocery run\n- prepare clothes for tomorrow\n- read for 30 minutes before sleep."
    ]
    
    static let memoDeletionWarning = "Delete this memo? This action can't be undone."
    static let delete = "Delete"
    static let cancel = "Cancel"
  }
}

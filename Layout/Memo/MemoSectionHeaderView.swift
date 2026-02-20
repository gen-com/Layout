//
//  MemoSectionHeaderView.swift
//  Layout
//
//  Created by Byeongjo Koo.
//

import UIKit

final class MemoSectionHeaderView: UICollectionReusableView {
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
  
  private func setUpSubviews() {
    addSubview(titleLabel)
  }
  
  private func setUpLayouts() {
    NSLayoutConstraint.activate([
      titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
      titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
      titleLabel.topAnchor.constraint(equalTo: topAnchor),
      titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
  }
  
  func configure(title: String) {
    titleLabel.text = title
  }
}

//
//  MemoCollectionViewCell.swift
//  Layout
//
//  Created by Byeongjo Koo.
//

import UIKit

final class MemoCollectionViewCell: UICollectionViewCell {
  
  // MARK: Subviews
  
  private let titleLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.numberOfLines = 1
    label.font = .systemFont(ofSize: 16, weight: .semibold)
    label.textColor = .label
    return label
  }()
  
  private let bodyLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.numberOfLines = 0
    label.font = .systemFont(ofSize: 14, weight: .medium)
    label.textColor = .secondaryLabel
    return label
  }()
  
  private var onPinAction: ((UIButton) -> Void)?
  
  private lazy var pinButton: UIButton = {
    let button = UIButton(type: .system)
    button.tintColor = .label
    button.translatesAutoresizingMaskIntoConstraints = false
    button.addAction(UIAction { [weak self] action in
      guard let self,
            let sender = action.sender as? UIButton
      else { return }
      
      self.onPinAction?(sender)
    }, for: .primaryActionTriggered)
    return button
  }()
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    contentView.backgroundColor = .secondarySystemFill
    contentView.layer.cornerRadius = 8
    contentView.layer.masksToBounds = true
    
    contentView.addSubview(titleLabel)
    contentView.addSubview(bodyLabel)
    contentView.addSubview(pinButton)
    
    NSLayoutConstraint.activate([
      titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
      titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
      titleLabel.trailingAnchor.constraint(equalTo: pinButton.leadingAnchor, constant: -8),
      
      pinButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
      pinButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
      pinButton.widthAnchor.constraint(equalToConstant: 24),
      pinButton.heightAnchor.constraint(equalToConstant: 24),
      
      bodyLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
      bodyLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
      bodyLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
      bodyLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
    ])
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func preferredLayoutAttributesFitting(
    _ layoutAttributes: UICollectionViewLayoutAttributes
  ) -> UICollectionViewLayoutAttributes {
    let attributes = super.preferredLayoutAttributesFitting(layoutAttributes)
    
    let targetSize = CGSize(
      width: attributes.size.width,
      height: UIView.layoutFittingCompressedSize.height
    )
    let fittingSize = contentView.systemLayoutSizeFitting(
      targetSize,
      withHorizontalFittingPriority: .required,
      verticalFittingPriority: .fittingSizeLevel
    )
    attributes.size.height = ceil(fittingSize.height)
    return attributes
  }
  
  // MARK: Configure
  
  func configure(memo: Memo) {
    titleLabel.text = memo.title
    bodyLabel.text = memo.bodyContent
    let symbolName = memo.isPinned ? "pin.circle.fill" : "pin.circle"
    pinButton.setImage(UIImage(systemName: symbolName), for: .normal)
  }
  
  // MARK: Actions
  
  func setOnPinAction(_ action: @escaping (UIButton) -> Void) {
    onPinAction = action
  }
}

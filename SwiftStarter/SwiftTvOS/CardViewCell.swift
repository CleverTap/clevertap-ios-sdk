//
//  CardViewCell.swift
//  SwiftTvOS
//
//  Created by Reshab Singh  on 10/03/26.
//  Copyright © 2026 CleverTap. All rights reserved.
//

import UIKit

final class CardCell: UICollectionViewCell {

    static let reuseID = "CardCell"

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.textAlignment = .center
        l.textColor = .white
        l.font = .systemFont(ofSize: 28, weight: .semibold)
        l.numberOfLines = 2
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.7
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCell()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupCell() {
        contentView.layer.cornerRadius = 16
        contentView.clipsToBounds = true

        contentView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    func configure(title: String, color: UIColor) {
        titleLabel.text = title
        contentView.backgroundColor = color
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({
            if self.isFocused {
                self.transform = CGAffineTransform(scaleX: 1.08, y: 1.08)
                self.contentView.layer.shadowColor = UIColor.white.cgColor
                self.contentView.layer.shadowOpacity = 0.4
                self.contentView.layer.shadowRadius = 12
                self.contentView.layer.shadowOffset = .zero
                self.contentView.clipsToBounds = false
                self.layer.zPosition = 1
            } else {
                self.transform = .identity
                self.contentView.layer.shadowOpacity = 0
                self.contentView.clipsToBounds = true
                self.layer.zPosition = 0
            }
        }, completion: nil)
    }
}

// MARK: - SectionHeader

final class SectionHeader: UICollectionReusableView {

    static let reuseID = "SectionHeader"

    private let label: UILabel = {
        let l = UILabel()
        l.textColor = .white
        l.font = .systemFont(ofSize: 34, weight: .bold)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String) {
        label.text = title
    }
}

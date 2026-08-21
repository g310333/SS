//
//  ProfileViewController.swift
//  SecuritiesSimulation
//

import UIKit

/// "個人" tab: currently a placeholder — no profile endpoint is wired up
/// yet.
final class ProfileViewController: UIViewController {

    private let titleLabel = UILabel()
    private let placeholderIcon = UIImageView(image: UIImage(systemName: "person.circle"))
    private let placeholderLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = MaterialPalette.background
        navigationController?.setNavigationBarHidden(true, animated: false)

        setUpLayout()
    }

    private func setUpLayout() {
        titleLabel.text = "個人"
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = MaterialPalette.textPrimary

        let headerContainer = UIView()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerContainer.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: headerContainer.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -16),
            titleLabel.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor),
            headerContainer.heightAnchor.constraint(equalToConstant: 44),
        ])

        placeholderIcon.tintColor = MaterialPalette.textSecondary
        placeholderIcon.contentMode = .scaleAspectFit

        placeholderLabel.text = "尚未串接個人資料"
        placeholderLabel.font = .systemFont(ofSize: 13)
        placeholderLabel.textColor = MaterialPalette.textSecondary

        let placeholderStack = UIStackView(arrangedSubviews: [placeholderIcon, placeholderLabel])
        placeholderStack.axis = .vertical
        placeholderStack.alignment = .center
        placeholderStack.spacing = 8
        placeholderStack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(headerContainer)
        view.addSubview(placeholderStack)
        headerContainer.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            headerContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            placeholderIcon.widthAnchor.constraint(equalToConstant: 40),
            placeholderIcon.heightAnchor.constraint(equalToConstant: 40),
            placeholderStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            placeholderStack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }
}

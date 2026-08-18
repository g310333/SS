//
//  MaterialTextField.swift
//  SecuritiesSimulation
//

import UIKit

/// A reusable Material Design styled input: a title label, an underlined
/// text field that highlights on focus, and an inline error message.
final class MaterialTextField: UIView {

    let textField = UITextField()

    var text: String {
        get { textField.text ?? "" }
        set { textField.text = newValue }
    }

    var title: String {
        get { titleLabel.text ?? "" }
        set { titleLabel.text = newValue }
    }

    var errorMessage: String? {
        didSet { updateErrorState() }
    }

    private let titleLabel = UILabel()
    private let underline = UIView()
    private let errorLabel = UILabel()
    private var underlineHeightConstraint: NSLayoutConstraint!

    init(title: String, placeholder: String, isSecure: Bool = false) {
        super.init(frame: .zero)
        titleLabel.text = title
        textField.placeholder = placeholder
        textField.isSecureTextEntry = isSecure
        setUpViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpViews() {
        titleLabel.font = .systemFont(ofSize: 13, weight: .medium)
        titleLabel.textColor = MaterialPalette.textSecondary

        textField.font = .systemFont(ofSize: 17)
        textField.textColor = MaterialPalette.textPrimary
        textField.borderStyle = .none
        textField.autocorrectionType = .no
        textField.addTarget(self, action: #selector(editingDidBegin), for: .editingDidBegin)
        textField.addTarget(self, action: #selector(editingDidEnd), for: .editingDidEnd)

        underline.backgroundColor = MaterialPalette.divider

        errorLabel.font = .systemFont(ofSize: 12)
        errorLabel.textColor = MaterialPalette.error
        errorLabel.numberOfLines = 0
        errorLabel.alpha = 0

        for subview in [titleLabel, textField, underline, errorLabel] {
            subview.translatesAutoresizingMaskIntoConstraints = false
            addSubview(subview)
        }

        underlineHeightConstraint = underline.heightAnchor.constraint(equalToConstant: 1)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            textField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            textField.leadingAnchor.constraint(equalTo: leadingAnchor),
            textField.trailingAnchor.constraint(equalTo: trailingAnchor),
            textField.heightAnchor.constraint(equalToConstant: 28),

            underline.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 4),
            underline.leadingAnchor.constraint(equalTo: leadingAnchor),
            underline.trailingAnchor.constraint(equalTo: trailingAnchor),
            underlineHeightConstraint,

            errorLabel.topAnchor.constraint(equalTo: underline.bottomAnchor, constant: 4),
            errorLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            errorLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            errorLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    @objc private func editingDidBegin() {
        UIView.animate(withDuration: 0.2) {
            self.underline.backgroundColor = MaterialPalette.primaryVariant
            self.underlineHeightConstraint.constant = 2
            self.titleLabel.textColor = MaterialPalette.primaryVariant
            self.layoutIfNeeded()
        }
    }

    @objc private func editingDidEnd() {
        UIView.animate(withDuration: 0.2) {
            self.underline.backgroundColor = self.errorMessage == nil ? MaterialPalette.divider : MaterialPalette.error
            self.underlineHeightConstraint.constant = 1
            self.titleLabel.textColor = MaterialPalette.textSecondary
            self.layoutIfNeeded()
        }
    }

    private func updateErrorState() {
        errorLabel.text = errorMessage
        let hasError = errorMessage != nil
        underline.backgroundColor = hasError ? MaterialPalette.error : MaterialPalette.divider
        UIView.animate(withDuration: 0.15) {
            self.errorLabel.alpha = hasError ? 1 : 0
            self.layoutIfNeeded()
        }
    }
}

//
//  RegisterViewController.swift
//  SecuritiesSimulation
//

import UIKit
import Combine

final class RegisterViewController: UIViewController {

    private let viewModel: RegisterViewModel
    private var cancellables = Set<AnyCancellable>()

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let nicknameField = MaterialTextField(title: "暱稱", placeholder: "請輸入暱稱")
    private let mailField = MaterialTextField(title: "帳號", placeholder: "you@example.com")
    private let passwordField = MaterialTextField(title: "密碼", placeholder: "請輸入密碼", isSecure: true)
    private let passwordVisibilityButton = UIButton(type: .system)
    private let confirmPasswordField = MaterialTextField(title: "確認密碼", placeholder: "請再次輸入密碼", isSecure: true)
    private let confirmPasswordVisibilityButton = UIButton(type: .system)
    private let generalErrorLabel = UILabel()
    private let registerButton = UIButton(type: .system)
    private let registerButtonSpinner = UIActivityIndicatorView(style: .medium)
    private let logInPromptLabel = UILabel()
    private let logInButton = UIButton(type: .system)

    /// Invoked when the user taps "登入". Pure navigation — no business
    /// logic involved — so `AppCoordinator` handles it directly rather
    /// than routing it through `RegisterViewModel`.
    var onLoginTapped: (() -> Void)?

    init(viewModel: RegisterViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = MaterialPalette.background
        title = "註冊"

        setUpLayout()
        setUpActions()
        bindViewModel()
        setUpKeyboardHandling()
    }

    // MARK: - Layout

    private func setUpLayout() {
        scrollView.keyboardDismissMode = .interactive
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)

        titleLabel.text = "建立帳號"
        titleLabel.font = .systemFont(ofSize: 30, weight: .bold)
        titleLabel.textColor = MaterialPalette.textPrimary

        subtitleLabel.text = "註冊新帳號以開始使用"
        subtitleLabel.font = .systemFont(ofSize: 16)
        subtitleLabel.textColor = MaterialPalette.textSecondary

        configureVisibilityButton(passwordVisibilityButton, action: #selector(togglePasswordVisibility))
        passwordField.textField.rightView = passwordVisibilityButton
        passwordField.textField.rightViewMode = .always

        configureVisibilityButton(confirmPasswordVisibilityButton, action: #selector(toggleConfirmPasswordVisibility))
        confirmPasswordField.textField.rightView = confirmPasswordVisibilityButton
        confirmPasswordField.textField.rightViewMode = .always

        generalErrorLabel.font = .systemFont(ofSize: 13)
        generalErrorLabel.textColor = MaterialPalette.error
        generalErrorLabel.numberOfLines = 0
        generalErrorLabel.textAlignment = .center
        generalErrorLabel.alpha = 0

        configureRegisterButton()

        logInPromptLabel.text = "已經有帳號？"
        logInPromptLabel.font = .systemFont(ofSize: 14)
        logInPromptLabel.textColor = MaterialPalette.textSecondary

        logInButton.setTitle("登入", for: .normal)
        logInButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        logInButton.setTitleColor(MaterialPalette.primaryVariant, for: .normal)

        let logInStack = UIStackView(arrangedSubviews: [logInPromptLabel, logInButton])
        logInStack.axis = .horizontal
        logInStack.spacing = 4
        logInStack.alignment = .center

        let formStack = UIStackView(arrangedSubviews: [
            titleLabel,
            subtitleLabel,
            spacer(height: 24),
            nicknameField,
            mailField,
            passwordField,
            confirmPasswordField,
            generalErrorLabel,
            spacer(height: 8),
            registerButton,
        ])
        formStack.axis = .vertical
        formStack.spacing = 16
        formStack.setCustomSpacing(4, after: subtitleLabel)
        formStack.setCustomSpacing(24, after: confirmPasswordField)

        formStack.translatesAutoresizingMaskIntoConstraints = false
        logInStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(formStack)
        contentView.addSubview(logInStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            formStack.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 32),
            formStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).withPriority(.defaultLow),
            formStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            formStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),

            registerButton.heightAnchor.constraint(equalToConstant: 48),

            logInStack.topAnchor.constraint(equalTo: formStack.bottomAnchor, constant: 32),
            logInStack.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            logInStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),
        ])
    }

    private func configureVisibilityButton(_ button: UIButton, action: Selector) {
        button.tintColor = MaterialPalette.textSecondary
        button.setImage(UIImage(systemName: "eye"), for: .normal)
        button.setImage(UIImage(systemName: "eye.slash"), for: .selected)
        button.frame = CGRect(x: 0, y: 0, width: 32, height: 24)
        button.addTarget(self, action: action, for: .touchUpInside)
    }

    private func configureRegisterButton() {
        registerButton.setTitle("註冊", for: .normal)
        registerButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        registerButton.setTitleColor(MaterialPalette.onPrimary, for: .normal)
        registerButton.setTitleColor(MaterialPalette.onPrimary.withAlphaComponent(0.6), for: .disabled)
        registerButton.backgroundColor = MaterialPalette.primary
        registerButton.layer.cornerRadius = 8
        registerButton.layer.shadowColor = UIColor.black.cgColor
        registerButton.layer.shadowOpacity = 0.2
        registerButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        registerButton.layer.shadowRadius = 4

        registerButtonSpinner.color = MaterialPalette.onPrimary
        registerButtonSpinner.hidesWhenStopped = true
        registerButtonSpinner.translatesAutoresizingMaskIntoConstraints = false
        registerButton.addSubview(registerButtonSpinner)
        NSLayoutConstraint.activate([
            registerButtonSpinner.centerYAnchor.constraint(equalTo: registerButton.centerYAnchor),
            registerButtonSpinner.trailingAnchor.constraint(equalTo: registerButton.trailingAnchor, constant: -16),
        ])
    }

    private func spacer(height: CGFloat) -> UIView {
        let view = UIView()
        view.heightAnchor.constraint(equalToConstant: height).isActive = true
        return view
    }

    // MARK: - Actions

    private func setUpActions() {
        nicknameField.textField.addTarget(self, action: #selector(nicknameChanged), for: .editingChanged)
        mailField.textField.addTarget(self, action: #selector(mailChanged), for: .editingChanged)
        passwordField.textField.addTarget(self, action: #selector(passwordChanged), for: .editingChanged)
        confirmPasswordField.textField.addTarget(self, action: #selector(confirmPasswordChanged), for: .editingChanged)
        registerButton.addTarget(self, action: #selector(registerTapped), for: .touchUpInside)
        logInButton.addTarget(self, action: #selector(logInTapped), for: .touchUpInside)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    @objc private func nicknameChanged() {
        viewModel.nicknameDidChange(nicknameField.text)
    }

    @objc private func mailChanged() {
        viewModel.mailDidChange(mailField.text)
    }

    @objc private func passwordChanged() {
        viewModel.passwordDidChange(passwordField.text)
    }

    @objc private func confirmPasswordChanged() {
        viewModel.confirmPasswordDidChange(confirmPasswordField.text)
    }

    @objc private func togglePasswordVisibility() {
        passwordVisibilityButton.isSelected.toggle()
        passwordField.textField.isSecureTextEntry = !passwordVisibilityButton.isSelected
    }

    @objc private func toggleConfirmPasswordVisibility() {
        confirmPasswordVisibilityButton.isSelected.toggle()
        confirmPasswordField.textField.isSecureTextEntry = !confirmPasswordVisibilityButton.isSelected
    }

    @objc private func registerTapped() {
        view.endEditing(true)
        viewModel.registerButtonTapped()
    }

    @objc private func logInTapped() {
        view.endEditing(true)
        onLoginTapped?()
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    // MARK: - Binding

    private func bindViewModel() {
        viewModel.$isRegisterEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isEnabled in
                self?.updateRegisterButtonEnabled(isEnabled)
            }
            .store(in: &cancellables)

        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.updateRegisterButtonLoading(isLoading)
            }
            .store(in: &cancellables)

        viewModel.$nicknameErrorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.nicknameField.errorMessage = message
            }
            .store(in: &cancellables)

        viewModel.$mailErrorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.mailField.errorMessage = message
            }
            .store(in: &cancellables)

        viewModel.$passwordErrorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.passwordField.errorMessage = message
            }
            .store(in: &cancellables)

        viewModel.$confirmPasswordErrorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.confirmPasswordField.errorMessage = message
            }
            .store(in: &cancellables)

        viewModel.$generalErrorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.generalErrorLabel.text = message
                UIView.animate(withDuration: 0.15) {
                    self?.generalErrorLabel.alpha = message == nil ? 0 : 1
                }
            }
            .store(in: &cancellables)
    }

    private func updateRegisterButtonEnabled(_ isEnabled: Bool) {
        registerButton.isEnabled = isEnabled && !viewModel.isLoading
        registerButton.alpha = registerButton.isEnabled ? 1 : 0.5
    }

    private func updateRegisterButtonLoading(_ isLoading: Bool) {
        registerButton.isEnabled = viewModel.isRegisterEnabled && !isLoading
        registerButton.alpha = registerButton.isEnabled ? 1 : 0.5
        registerButton.setTitle(isLoading ? "註冊中" : "註冊", for: .normal)
        if isLoading {
            registerButtonSpinner.startAnimating()
        } else {
            registerButtonSpinner.stopAnimating()
        }
    }

    // MARK: - Keyboard handling

    private func setUpKeyboardHandling() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillChangeFrame(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification, object: nil
        )
    }

    @objc private func keyboardWillChangeFrame(_ notification: Notification) {
        guard let frameValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let keyboardFrame = view.convert(frameValue.cgRectValue, from: nil)
        let bottomInset = max(0, view.bounds.maxY - keyboardFrame.minY - view.safeAreaInsets.bottom)
        scrollView.contentInset.bottom = bottomInset
        scrollView.verticalScrollIndicatorInsets.bottom = bottomInset
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        scrollView.contentInset.bottom = 0
        scrollView.verticalScrollIndicatorInsets.bottom = 0
    }
}

private extension NSLayoutConstraint {
    func withPriority(_ priority: UILayoutPriority) -> NSLayoutConstraint {
        self.priority = priority
        return self
    }
}

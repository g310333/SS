//
//  LoginViewController.swift
//  SecuritiesSimulation
//

import UIKit
import Combine

final class LoginViewController: UIViewController {

    private let viewModel: LoginViewModel
    private var cancellables = Set<AnyCancellable>()

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let usernameField = MaterialTextField(title: "帳號", placeholder: "you@example.com")
    private let passwordField = MaterialTextField(title: "密碼", placeholder: "請輸入密碼", isSecure: true)
    private let passwordVisibilityButton = UIButton(type: .system)
    private let generalErrorLabel = UILabel()
    private let loginButton = UIButton(type: .system)
    private let loginButtonSpinner = UIActivityIndicatorView(style: .medium)
    private let forgotPasswordButton = UIButton(type: .system)
    private let signUpPromptLabel = UILabel()
    private let signUpButton = UIButton(type: .system)

    init(viewModel: LoginViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = MaterialPalette.background
        navigationController?.setNavigationBarHidden(true, animated: false)

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

        titleLabel.text = "證券模擬"
        titleLabel.font = .systemFont(ofSize: 30, weight: .bold)
        titleLabel.textColor = MaterialPalette.textPrimary

        subtitleLabel.text = "登入以繼續"
        subtitleLabel.font = .systemFont(ofSize: 16)
        subtitleLabel.textColor = MaterialPalette.textSecondary

        configurePasswordVisibilityButton()
        passwordField.textField.rightView = passwordVisibilityButton
        passwordField.textField.rightViewMode = .always

        generalErrorLabel.font = .systemFont(ofSize: 13)
        generalErrorLabel.textColor = MaterialPalette.error
        generalErrorLabel.numberOfLines = 0
        generalErrorLabel.textAlignment = .center
        generalErrorLabel.alpha = 0

        configureLoginButton()

        forgotPasswordButton.setTitle("忘記密碼？", for: .normal)
        forgotPasswordButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        forgotPasswordButton.setTitleColor(MaterialPalette.primaryVariant, for: .normal)
        forgotPasswordButton.contentHorizontalAlignment = .trailing

        signUpPromptLabel.text = "還沒有帳號？"
        signUpPromptLabel.font = .systemFont(ofSize: 14)
        signUpPromptLabel.textColor = MaterialPalette.textSecondary

        signUpButton.setTitle("註冊", for: .normal)
        signUpButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        signUpButton.setTitleColor(MaterialPalette.primaryVariant, for: .normal)

        let signUpStack = UIStackView(arrangedSubviews: [signUpPromptLabel, signUpButton])
        signUpStack.axis = .horizontal
        signUpStack.spacing = 4
        signUpStack.alignment = .center

        let formStack = UIStackView(arrangedSubviews: [
            titleLabel,
            subtitleLabel,
            spacer(height: 24),
            usernameField,
            passwordField,
            forgotPasswordButton,
            generalErrorLabel,
            spacer(height: 8),
            loginButton,
        ])
        formStack.axis = .vertical
        formStack.spacing = 16
        formStack.setCustomSpacing(4, after: subtitleLabel)
        formStack.setCustomSpacing(24, after: passwordField)
        formStack.setCustomSpacing(8, after: forgotPasswordButton)

        formStack.translatesAutoresizingMaskIntoConstraints = false
        signUpStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(formStack)
        contentView.addSubview(signUpStack)

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

            loginButton.heightAnchor.constraint(equalToConstant: 48),

            signUpStack.topAnchor.constraint(equalTo: formStack.bottomAnchor, constant: 32),
            signUpStack.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            signUpStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),
        ])
    }

    private func configurePasswordVisibilityButton() {
        passwordVisibilityButton.tintColor = MaterialPalette.textSecondary
        passwordVisibilityButton.setImage(UIImage(systemName: "eye"), for: .normal)
        passwordVisibilityButton.setImage(UIImage(systemName: "eye.slash"), for: .selected)
        passwordVisibilityButton.frame = CGRect(x: 0, y: 0, width: 32, height: 24)
        passwordVisibilityButton.addTarget(self, action: #selector(togglePasswordVisibility), for: .touchUpInside)
    }

    private func configureLoginButton() {
        loginButton.setTitle("登入", for: .normal)
        loginButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        loginButton.setTitleColor(MaterialPalette.onPrimary, for: .normal)
        loginButton.setTitleColor(MaterialPalette.onPrimary.withAlphaComponent(0.6), for: .disabled)
        loginButton.backgroundColor = MaterialPalette.primary
        loginButton.layer.cornerRadius = 8
        loginButton.layer.shadowColor = UIColor.black.cgColor
        loginButton.layer.shadowOpacity = 0.2
        loginButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        loginButton.layer.shadowRadius = 4

        loginButtonSpinner.color = MaterialPalette.onPrimary
        loginButtonSpinner.hidesWhenStopped = true
        loginButtonSpinner.translatesAutoresizingMaskIntoConstraints = false
        loginButton.addSubview(loginButtonSpinner)
        NSLayoutConstraint.activate([
            loginButtonSpinner.centerYAnchor.constraint(equalTo: loginButton.centerYAnchor),
            loginButtonSpinner.trailingAnchor.constraint(equalTo: loginButton.trailingAnchor, constant: -16),
        ])
    }

    private func spacer(height: CGFloat) -> UIView {
        let view = UIView()
        view.heightAnchor.constraint(equalToConstant: height).isActive = true
        return view
    }

    // MARK: - Actions

    private func setUpActions() {
        usernameField.textField.addTarget(self, action: #selector(usernameChanged), for: .editingChanged)
        passwordField.textField.addTarget(self, action: #selector(passwordChanged), for: .editingChanged)
        loginButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    @objc private func usernameChanged() {
        viewModel.usernameDidChange(usernameField.text)
    }

    @objc private func passwordChanged() {
        viewModel.passwordDidChange(passwordField.text)
    }

    @objc private func togglePasswordVisibility() {
        passwordVisibilityButton.isSelected.toggle()
        passwordField.textField.isSecureTextEntry = !passwordVisibilityButton.isSelected
    }

    @objc private func loginTapped() {
        view.endEditing(true)
        viewModel.loginButtonTapped()
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    // MARK: - Binding

    private func bindViewModel() {
        viewModel.$isLoginEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isEnabled in
                self?.updateLoginButtonEnabled(isEnabled)
            }
            .store(in: &cancellables)

        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.updateLoginButtonLoading(isLoading)
            }
            .store(in: &cancellables)

        viewModel.$usernameErrorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.usernameField.errorMessage = message
            }
            .store(in: &cancellables)

        viewModel.$passwordErrorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.passwordField.errorMessage = message
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

    private func updateLoginButtonEnabled(_ isEnabled: Bool) {
        loginButton.isEnabled = isEnabled && !viewModel.isLoading
        loginButton.alpha = loginButton.isEnabled ? 1 : 0.5
    }

    private func updateLoginButtonLoading(_ isLoading: Bool) {
        loginButton.isEnabled = viewModel.isLoginEnabled && !isLoading
        loginButton.alpha = loginButton.isEnabled ? 1 : 0.5
        loginButton.setTitle(isLoading ? "登入中" : "登入", for: .normal)
        if isLoading {
            loginButtonSpinner.startAnimating()
        } else {
            loginButtonSpinner.stopAnimating()
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

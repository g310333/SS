//
//  OrderViewController.swift
//  SecuritiesSimulation
//

import UIKit
import Combine

/// "模擬下單" order screen: a header with back navigation and the stock's
/// code/name, a 零股／整張 lot-type switch, price/quantity input fields, an
/// estimated-amount readout, and a submit button.
///
/// Pushed from the stock detail screen's bottom bar. No order endpoint is
/// wired up yet — submitting only validates the inputs (via
/// `OrderViewModel`) and confirms locally.
final class OrderViewController: UIViewController {

    private let viewModel: OrderViewModel
    private var cancellables = Set<AnyCancellable>()

    private let backButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let stockLabel = UILabel()

    private var lotTypeButtons: [UIButton] = []

    private let priceField = MaterialTextField(title: "價格", placeholder: "請輸入價格")
    private let quantityField = MaterialTextField(title: "", placeholder: "")

    private let estimatedAmountValueLabel = UILabel()

    private let submitButton = UIButton(configuration: .filled())

    init(viewModel: OrderViewModel) {
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
        render(viewModel.state)

        viewModel.onOrderSubmitted = { [weak self] result in
            self?.presentSubmittedAlert(for: result)
        }
        viewModel.onOrderFailed = { [weak self] in
            self?.presentOrderFailedAlert()
        }
    }

    // MARK: - Layout

    private func setUpLayout() {
        let headerContainer = makeHeader()
        let scrollView = UIScrollView()
        let bottomBar = makeBottomBar()

        let rootStack = UIStackView(arrangedSubviews: [headerContainer, scrollView, bottomBar])
        rootStack.axis = .vertical
        rootStack.spacing = 0
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(rootStack)

        NSLayoutConstraint.activate([
            rootStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            rootStack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            rootStack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            rootStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            headerContainer.heightAnchor.constraint(equalToConstant: 44),
            bottomBar.heightAnchor.constraint(equalToConstant: 80),
        ])

        setUpScrollContent(in: scrollView)
    }

    private func makeHeader() -> UIView {
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = MaterialPalette.primary

        titleLabel.text = "模擬下單"
        titleLabel.font = .systemFont(ofSize: 17, weight: .bold)
        titleLabel.textColor = MaterialPalette.textPrimary

        let spacer = UIView()

        let headerRow = UIStackView(arrangedSubviews: [backButton, titleLabel, spacer])
        headerRow.axis = .horizontal
        headerRow.alignment = .center
        headerRow.spacing = 4

        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.widthAnchor.constraint(equalToConstant: 32).isActive = true
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let container = UIView()
        headerRow.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(headerRow)
        NSLayoutConstraint.activate([
            headerRow.topAnchor.constraint(equalTo: container.topAnchor),
            headerRow.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            headerRow.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            headerRow.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        return container
    }

    private func setUpScrollContent(in scrollView: UIScrollView) {
        stockLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        stockLabel.textColor = MaterialPalette.textPrimary

        let lotTypeRow = makeLotTypeRow()
        let inputCard = makeInputCard()
        let estimatedAmountRow = makeEstimatedAmountRow()

        let contentStack = UIStackView(arrangedSubviews: [
            stockLabel,
            lotTypeRow,
            inputCard,
            estimatedAmountRow,
        ])
        contentStack.axis = .vertical
        contentStack.spacing = 20
        contentStack.setCustomSpacing(24, after: lotTypeRow)
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        scrollView.addSubview(contentStack)
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -16),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32),
        ])
    }

    private func makeLotTypeRow() -> UIView {
        let row = UIStackView(arrangedSubviews: OrderLotType.allCases.map { lotType in
            let button = makeLotTypeButton(title: lotType.title)
            button.tag = lotType.rawValue
            lotTypeButtons.append(button)
            return button
        })
        row.axis = .horizontal
        row.spacing = 8
        row.distribution = .fillEqually
        return row
    }

    private func makeLotTypeButton(title: String) -> UIButton {
        var config = UIButton.Configuration.plain()
        config.title = title
        config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 14, bottom: 10, trailing: 14)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 14, weight: .semibold)
            return outgoing
        }
        let button = UIButton(configuration: config)
        button.layer.cornerRadius = 18
        button.layer.borderWidth = 1
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(lotTypeButtonTapped(_:)), for: .touchUpInside)
        return button
    }

    private func makeInputCard() -> UIView {
        let card = UIView()
        card.backgroundColor = MaterialPalette.surface
        card.layer.cornerRadius = 12
        card.clipsToBounds = true

        priceField.textField.keyboardType = .decimalPad
        quantityField.textField.keyboardType = .numberPad

        let fieldsStack = UIStackView(arrangedSubviews: [priceField, quantityField])
        fieldsStack.axis = .vertical
        fieldsStack.spacing = 20
        fieldsStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(fieldsStack)

        NSLayoutConstraint.activate([
            fieldsStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            fieldsStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            fieldsStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            fieldsStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
        ])
        return card
    }

    private func makeEstimatedAmountRow() -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = "預估金額"
        titleLabel.font = .systemFont(ofSize: 13)
        titleLabel.textColor = MaterialPalette.textSecondary

        estimatedAmountValueLabel.font = .systemFont(ofSize: 20, weight: .bold)
        estimatedAmountValueLabel.textColor = MaterialPalette.textPrimary

        let row = UIStackView(arrangedSubviews: [titleLabel, UIView(), estimatedAmountValueLabel])
        row.axis = .horizontal
        row.alignment = .center
        return row
    }

    private func makeBottomBar() -> UIView {
        let container = UIView()

        let divider = UIView()
        divider.backgroundColor = MaterialPalette.divider
        divider.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(divider)

        var submitConfig = UIButton.Configuration.filled()
        submitConfig.title = "送出委託"
        submitConfig.baseBackgroundColor = MaterialPalette.primary
        submitConfig.baseForegroundColor = MaterialPalette.onPrimary
        submitConfig.cornerStyle = .medium
        submitButton.configuration = submitConfig
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(submitButton)

        NSLayoutConstraint.activate([
            divider.topAnchor.constraint(equalTo: container.topAnchor),
            divider.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            divider.heightAnchor.constraint(equalToConstant: 1),

            submitButton.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: 12),
            submitButton.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            submitButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            submitButton.heightAnchor.constraint(equalToConstant: 48),
        ])

        return container
    }

    // MARK: - Actions

    private func setUpActions() {
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        submitButton.addTarget(self, action: #selector(submitButtonTapped), for: .touchUpInside)
        priceField.textField.addTarget(self, action: #selector(priceChanged), for: .editingChanged)
        quantityField.textField.addTarget(self, action: #selector(quantityChanged), for: .editingChanged)
    }

    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func lotTypeButtonTapped(_ sender: UIButton) {
        guard let lotType = OrderLotType(rawValue: sender.tag) else { return }
        viewModel.selectLotType(lotType)
    }

    @objc private func priceChanged() {
        viewModel.updatePrice(priceField.text)
    }

    @objc private func quantityChanged() {
        viewModel.updateQuantity(quantityField.text)
    }

    @objc private func submitButtonTapped() {
        guard viewModel.state.isSubmitEnabled else { return }
        view.endEditing(true)
        viewModel.submitOrder()
    }

    private func presentSubmittedAlert(for result: BuyTradeResult) {
        let state = viewModel.state
        let message = """
        \(state.stockName)（\(result.stockCode)）
        成交價 \(Self.formattedAmount(result.price)) · 股數 \(result.quantity)
        總金額 \(Self.formattedAmount(result.totalAmount))
        剩餘現金 \(Self.formattedAmount(result.cashBalance))
        持有股數 \(result.holdingQuantity)
        """
        let alert = UIAlertController(title: "模擬委託已送出", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "確定", style: .default) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }

    private func presentOrderFailedAlert() {
        let alert = UIAlertController(title: "委託送出失敗", message: "請稍後再試", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "確定", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Binding

    private func bindViewModel() {
        viewModel.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.render(state)
            }
            .store(in: &cancellables)
    }

    // MARK: - Rendering

    private func render(_ state: OrderViewState) {
        stockLabel.text = "\(state.stockName)（\(state.stockCode)）"

        for button in lotTypeButtons {
            let isSelected = button.tag == state.lotType.rawValue
            button.configuration?.baseForegroundColor = isSelected ? MaterialPalette.onPrimary : MaterialPalette.textSecondary
            button.backgroundColor = isSelected ? MaterialPalette.primary : .clear
            button.layer.borderColor = (isSelected ? MaterialPalette.primary : MaterialPalette.divider).cgColor
        }

        quantityField.title = state.lotType.quantityLabel
        quantityField.textField.placeholder = state.lotType.quantityPlaceholder

        if priceField.text != state.price { priceField.text = state.price }
        if quantityField.text != state.quantity { quantityField.text = state.quantity }

        estimatedAmountValueLabel.text = state.estimatedAmount.map(Self.formattedAmount) ?? "-"

        submitButton.configuration?.title = state.isSubmitting ? "送出中…" : "送出委託"
        submitButton.isEnabled = state.isSubmitEnabled
        submitButton.alpha = state.isSubmitEnabled ? 1 : 0.5
    }

    private static func formattedAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        let formatted = formatter.string(from: NSNumber(value: amount)) ?? String(format: "%.0f", amount)
        return "NT$ \(formatted)"
    }
}

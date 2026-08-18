//
//  StockDetailViewController.swift
//  SecuritiesSimulation
//

import UIKit
import Combine

/// Individual stock detail screen: a header with back navigation and the
/// stock's code/name, a price/change hero section, an OHLC + volume metrics
/// card, a chart placeholder with period tabs, and a bottom action bar.
///
/// Rendered entirely from the `Stock` snapshot the user tapped on the home
/// list (see `StockDetailViewModel`) — no network call of its own yet. The
/// period tabs and favorite toggle are local UI state only, with no service
/// wired up behind them.
final class StockDetailViewController: UIViewController {

    private let viewModel: StockDetailViewModel
    private let stockGroupService: StockGroupServicing

    private let backButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let industryLabel = UILabel()
    private let favoriteButton = UIButton(type: .system)

    private let priceLabel = UILabel()
    private let changeLabel = UILabel()
    private let updatedAtLabel = UILabel()

    private var periodButtons: [UIButton] = []
    private let periodTitles = ["分時", "日K", "週K", "月K"]
    private var selectedPeriodIndex = 1
    private let chartPlaceholderView = UIView()

    private var cancellables = Set<AnyCancellable>()

    init(viewModel: StockDetailViewModel, stockGroupService: StockGroupServicing) {
        self.viewModel = viewModel
        self.stockGroupService = stockGroupService
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
        viewModel.loadFavoriteStatus()
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
            bottomBar.heightAnchor.constraint(equalToConstant: 64),
        ])

        setUpScrollContent(in: scrollView)
    }

    private func makeHeader() -> UIView {
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = MaterialPalette.primary

        titleLabel.font = .systemFont(ofSize: 17, weight: .bold)
        titleLabel.textColor = MaterialPalette.textPrimary

        industryLabel.font = .systemFont(ofSize: 11)
        industryLabel.textColor = MaterialPalette.textSecondary

        let titleStack = UIStackView(arrangedSubviews: [titleLabel, industryLabel])
        titleStack.axis = .vertical
        titleStack.spacing = 1
        titleStack.alignment = .center

        favoriteButton.setImage(UIImage(systemName: "star"), for: .normal)
        favoriteButton.tintColor = MaterialPalette.primary

        let headerRow = UIStackView(arrangedSubviews: [backButton, titleStack, favoriteButton])
        headerRow.axis = .horizontal
        headerRow.alignment = .center
        headerRow.distribution = .equalSpacing

        for button in [backButton, favoriteButton] {
            button.translatesAutoresizingMaskIntoConstraints = false
            button.widthAnchor.constraint(equalToConstant: 32).isActive = true
        }

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
        let contentStack = UIStackView(arrangedSubviews: [
            makePriceSection(),
            makeMetricsCard(),
            makeChartSection(),
        ])
        contentStack.axis = .vertical
        contentStack.spacing = 16
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

    private func makePriceSection() -> UIView {
        priceLabel.font = .systemFont(ofSize: 36, weight: .bold)

        changeLabel.font = .systemFont(ofSize: 15, weight: .semibold)

        updatedAtLabel.font = .systemFont(ofSize: 12)
        updatedAtLabel.textColor = MaterialPalette.textSecondary

        let priceRow = UIStackView(arrangedSubviews: [priceLabel, changeLabel])
        priceRow.axis = .horizontal
        priceRow.alignment = .lastBaseline
        priceRow.spacing = 10

        let section = UIStackView(arrangedSubviews: [priceRow, updatedAtLabel])
        section.axis = .vertical
        section.spacing = 4
        return section
    }

    private func makeMetricsCard() -> UIView {
        let card = UIView()
        card.backgroundColor = MaterialPalette.surface
        card.layer.cornerRadius = 12
        card.clipsToBounds = true

        let rows = UIStackView(arrangedSubviews: [
            makeMetricRow(
                left: ("開盤", viewModel.state.openingPrice),
                right: ("最高", viewModel.state.highestPrice)
            ),
            makeMetricRow(
                left: ("最低", viewModel.state.lowestPrice),
                right: ("成交量", viewModel.state.tradeVolume)
            ),
            makeMetricRow(
                left: ("成交值", viewModel.state.tradeValue),
                right: ("成交筆數", viewModel.state.transactionCount)
            ),
        ])
        rows.axis = .vertical
        rows.spacing = 16
        rows.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(rows)

        NSLayoutConstraint.activate([
            rows.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            rows.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            rows.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            rows.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
        ])
        return card
    }

    private func makeMetricRow(left: (title: String, value: String), right: (title: String, value: String)) -> UIView {
        let row = UIStackView(arrangedSubviews: [
            makeMetricPair(title: left.title, value: left.value),
            makeMetricPair(title: right.title, value: right.value),
        ])
        row.axis = .horizontal
        row.distribution = .fillEqually
        return row
    }

    private func makeMetricPair(title: String, value: String) -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 12)
        titleLabel.textColor = MaterialPalette.textSecondary

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        valueLabel.textColor = MaterialPalette.textPrimary

        let pair = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        pair.axis = .vertical
        pair.spacing = 2
        return pair
    }

    private func makeChartSection() -> UIView {
        let periodRow = UIStackView(arrangedSubviews: periodTitles.enumerated().map { index, title in
            let button = makePeriodButton(title: title)
            button.tag = index
            periodButtons.append(button)
            return button
        })
        periodRow.axis = .horizontal
        periodRow.spacing = 8

        chartPlaceholderView.backgroundColor = MaterialPalette.surface
        chartPlaceholderView.layer.cornerRadius = 12
        chartPlaceholderView.clipsToBounds = true
        chartPlaceholderView.translatesAutoresizingMaskIntoConstraints = false
        chartPlaceholderView.heightAnchor.constraint(equalToConstant: 220).isActive = true

        let placeholderIcon = UIImageView(image: UIImage(systemName: "chart.xyaxis.line"))
        placeholderIcon.tintColor = MaterialPalette.textSecondary
        placeholderIcon.contentMode = .scaleAspectFit

        let placeholderLabel = UILabel()
        placeholderLabel.text = "圖表尚未串接"
        placeholderLabel.font = .systemFont(ofSize: 13)
        placeholderLabel.textColor = MaterialPalette.textSecondary

        let placeholderStack = UIStackView(arrangedSubviews: [placeholderIcon, placeholderLabel])
        placeholderStack.axis = .vertical
        placeholderStack.alignment = .center
        placeholderStack.spacing = 8
        placeholderStack.translatesAutoresizingMaskIntoConstraints = false
        chartPlaceholderView.addSubview(placeholderStack)

        NSLayoutConstraint.activate([
            placeholderIcon.widthAnchor.constraint(equalToConstant: 32),
            placeholderIcon.heightAnchor.constraint(equalToConstant: 32),
            placeholderStack.centerXAnchor.constraint(equalTo: chartPlaceholderView.centerXAnchor),
            placeholderStack.centerYAnchor.constraint(equalTo: chartPlaceholderView.centerYAnchor),
        ])

        let section = UIStackView(arrangedSubviews: [periodRow, chartPlaceholderView])
        section.axis = .vertical
        section.spacing = 12
        updatePeriodSelection()
        return section
    }

    private func makePeriodButton(title: String) -> UIButton {
        var config = UIButton.Configuration.plain()
        config.title = title
        config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 14, bottom: 6, trailing: 14)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 13, weight: .medium)
            return outgoing
        }
        let button = UIButton(configuration: config)
        button.layer.cornerRadius = 16
        button.layer.borderWidth = 1
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(periodButtonTapped(_:)), for: .touchUpInside)
        return button
    }

    private func makeBottomBar() -> UIView {
        let container = UIView()

        let divider = UIView()
        divider.backgroundColor = MaterialPalette.divider
        divider.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(divider)

        var buyConfig = UIButton.Configuration.filled()
        buyConfig.title = "模擬下單"
        buyConfig.baseBackgroundColor = MaterialPalette.primary
        buyConfig.baseForegroundColor = MaterialPalette.onPrimary
        buyConfig.cornerStyle = .medium
        let buyButton = UIButton(configuration: buyConfig)

        let buttonsRow = UIStackView(arrangedSubviews: [buyButton])
        buttonsRow.axis = .horizontal
        buttonsRow.distribution = .fillEqually
        buttonsRow.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(buttonsRow)

        NSLayoutConstraint.activate([
            divider.topAnchor.constraint(equalTo: container.topAnchor),
            divider.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            divider.heightAnchor.constraint(equalToConstant: 1),

            buttonsRow.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: 12),
            buttonsRow.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            buttonsRow.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            buttonsRow.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12),
        ])

        return container
    }

    // MARK: - Actions

    private func setUpActions() {
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        favoriteButton.addTarget(self, action: #selector(favoriteButtonTapped), for: .touchUpInside)
    }

    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func favoriteButtonTapped() {
        let groupSelectionViewModel = GroupSelectionViewModel(
            stockGroupService: stockGroupService,
            stockCode: viewModel.state.code,
            selectedGroupIDs: Set(viewModel.favoriteGroups.map(\.id))
        )
        let groupSelectionViewController = GroupSelectionViewController(viewModel: groupSelectionViewModel)
        groupSelectionViewController.onConfirm = { [weak self] selectedGroups in
            self?.viewModel.updateFavoriteGroups(selectedGroups)
        }
        if let sheet = groupSelectionViewController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        present(groupSelectionViewController, animated: true)
    }

    @objc private func periodButtonTapped(_ sender: UIButton) {
        selectedPeriodIndex = sender.tag
        updatePeriodSelection()
    }

    private func updatePeriodSelection() {
        for button in periodButtons {
            let isSelected = button.tag == selectedPeriodIndex
            button.configuration?.baseForegroundColor = isSelected ? MaterialPalette.onPrimary : MaterialPalette.textSecondary
            button.backgroundColor = isSelected ? MaterialPalette.primary : .clear
            button.layer.borderColor = (isSelected ? MaterialPalette.primary : MaterialPalette.divider).cgColor
        }
    }

    // MARK: - Binding

    private func bindViewModel() {
        viewModel.$favoriteGroups
            .receive(on: DispatchQueue.main)
            .sink { [weak self] favoriteGroups in
                self?.renderFavorite(favoriteGroups)
            }
            .store(in: &cancellables)
    }

    private func renderFavorite(_ favoriteGroups: Set<WatchlistGroup>) {
        let isFavorite = !favoriteGroups.isEmpty
        favoriteButton.setImage(UIImage(systemName: isFavorite ? "star.fill" : "star"), for: .normal)
    }

    // MARK: - Rendering

    private func render(_ state: StockDetailViewState) {
        titleLabel.text = "\(state.name) \(state.code)"
        industryLabel.text = state.industryName
        industryLabel.isHidden = state.industryName == nil

        priceLabel.text = state.closingPrice
        changeLabel.text = state.changeText
        updatedAtLabel.text = "更新時間 \(state.updatedAt)"

        let color = color(for: state.changeDirection)
        priceLabel.textColor = color
        changeLabel.textColor = color
    }

    private func color(for direction: StockChangeDirection) -> UIColor {
        switch direction {
        case .up: return .systemRed
        case .down: return .systemGreen
        case .flat: return MaterialPalette.textPrimary
        }
    }
}

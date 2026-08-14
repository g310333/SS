//
//  HomeViewController.swift
//  SecuritiesSimulation
//

import UIKit
import Combine

/// Home / market overview screen: a title bar with search, a segmented
/// switch between "全部股票" and "自選", a category bar underneath that
/// changes per segment, a content area, and a bottom action bar.
final class HomeViewController: UIViewController {

    private let viewModel: HomeViewModel
    private var cancellables = Set<AnyCancellable>()

    private let titleLabel = UILabel()
    private let searchButton = UIButton(type: .system)
    private let searchBar = UISearchBar()
    private let segmentedTabBar = SegmentedTabBar(titles: StockListSegment.allCases.map(\.title))
    private let categoryChipBar = CategoryChipBar()
    private let contentPlaceholderLabel = UILabel()

    init(viewModel: HomeViewModel? = nil) {
        self.viewModel = viewModel ?? HomeViewModel()
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
    }

    // MARK: - Layout

    private func setUpLayout() {
        titleLabel.text = "全股市行情"
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = MaterialPalette.textPrimary

        searchButton.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        searchButton.tintColor = MaterialPalette.primary

        let headerRow = UIStackView(arrangedSubviews: [titleLabel, UIView(), searchButton])
        headerRow.axis = .horizontal
        headerRow.alignment = .center

        searchBar.placeholder = "搜尋股票代號或名稱"
        searchBar.searchBarStyle = .minimal
        searchBar.isHidden = true

        let headerContainer = UIView()
        headerRow.translatesAutoresizingMaskIntoConstraints = false
        headerContainer.addSubview(headerRow)
        NSLayoutConstraint.activate([
            headerRow.topAnchor.constraint(equalTo: headerContainer.topAnchor),
            headerRow.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: 16),
            headerRow.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -16),
            headerRow.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor),
            headerContainer.heightAnchor.constraint(equalToConstant: 44),
        ])

        contentPlaceholderLabel.font = .systemFont(ofSize: 14)
        contentPlaceholderLabel.textColor = MaterialPalette.textSecondary
        contentPlaceholderLabel.textAlignment = .center

        let bottomBar = makeBottomBar()

        let rootStack = UIStackView(arrangedSubviews: [
            headerContainer,
            searchBar,
            segmentedTabBar,
            categoryChipBar,
            contentPlaceholderLabel,
            bottomBar,
        ])
        rootStack.axis = .vertical
        rootStack.spacing = 0
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(rootStack)

        NSLayoutConstraint.activate([
            rootStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            rootStack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            rootStack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            rootStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            segmentedTabBar.heightAnchor.constraint(equalToConstant: 44),
            categoryChipBar.heightAnchor.constraint(equalToConstant: 44),
            bottomBar.heightAnchor.constraint(equalToConstant: 64),
        ])
    }

    private func makeBottomBar() -> UIView {
        let container = UIView()

        let divider = UIView()
        divider.backgroundColor = MaterialPalette.divider
        divider.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(divider)

        let buttonsRow = UIStackView(arrangedSubviews: [
            makeBottomBarButton(title: "篩選", systemImageName: "line.3.horizontal.decrease.circle"),
            makeBottomBarButton(title: "排序", systemImageName: "arrow.up.arrow.down"),
        ])
        buttonsRow.axis = .horizontal
        buttonsRow.distribution = .fillEqually
        buttonsRow.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(buttonsRow)

        NSLayoutConstraint.activate([
            divider.topAnchor.constraint(equalTo: container.topAnchor),
            divider.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            divider.heightAnchor.constraint(equalToConstant: 1),

            buttonsRow.topAnchor.constraint(equalTo: divider.bottomAnchor),
            buttonsRow.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            buttonsRow.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            buttonsRow.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        return container
    }

    private func makeBottomBarButton(title: String, systemImageName: String) -> UIButton {
        var config = UIButton.Configuration.plain()
        config.title = title
        config.image = UIImage(systemName: systemImageName)
        config.imagePlacement = .top
        config.imagePadding = 4
        config.baseForegroundColor = MaterialPalette.textSecondary
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 11, weight: .medium)
            return outgoing
        }
        return UIButton(configuration: config)
    }

    // MARK: - Actions

    private func setUpActions() {
        searchButton.addTarget(self, action: #selector(searchButtonTapped), for: .touchUpInside)

        segmentedTabBar.onSelect = { [weak self] index in
            guard let segment = StockListSegment(rawValue: index) else { return }
            self?.viewModel.selectSegment(segment)
        }

        categoryChipBar.onSelect = { [weak self] index in
            self?.viewModel.selectCategory(at: index)
        }
    }

    @objc private func searchButtonTapped() {
        view.endEditing(true)
        viewModel.toggleSearch()
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

    /// Renders one `HomeViewState` snapshot. The category bar always
    /// receives `categories` and `selectedCategoryIndex` from the same
    /// snapshot, so it never highlights an index that belonged to the
    /// previous segment's category list.
    private func render(_ state: HomeViewState) {
        categoryChipBar.configure(titles: state.categories, selectedIndex: state.selectedCategoryIndex)
        contentPlaceholderLabel.text = "\(state.segment.title) · \(state.selectedCategory ?? "")"

        let shouldHideSearchBar = !state.isSearchActive
        guard searchBar.isHidden != shouldHideSearchBar else { return }
        UIView.animate(withDuration: 0.2) {
            self.searchBar.isHidden = shouldHideSearchBar
            self.view.layoutIfNeeded()
        }
    }
}

// MARK: - SegmentedTabBar

/// A two-option Material-style tab switch with a sliding underline
/// indicator beneath the selected title.
private final class SegmentedTabBar: UIView {

    var onSelect: ((Int) -> Void)?

    private let titles: [String]
    private var buttons: [UIButton] = []
    private let indicator = UIView()
    private var indicatorLeadingConstraint: NSLayoutConstraint?
    private var indicatorWidthConstraint: NSLayoutConstraint?
    private(set) var selectedIndex: Int = 0

    init(titles: [String]) {
        self.titles = titles
        super.init(frame: .zero)
        setUpViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpViews() {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false

        for (index, title) in titles.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(title, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
            button.tag = index
            button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
            buttons.append(button)
            stack.addArrangedSubview(button)
        }

        let divider = UIView()
        divider.backgroundColor = MaterialPalette.divider
        divider.translatesAutoresizingMaskIntoConstraints = false

        indicator.backgroundColor = MaterialPalette.primary
        indicator.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stack)
        addSubview(divider)
        addSubview(indicator)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),

            divider.leadingAnchor.constraint(equalTo: leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: trailingAnchor),
            divider.bottomAnchor.constraint(equalTo: bottomAnchor),
            divider.heightAnchor.constraint(equalToConstant: 1),

            indicator.bottomAnchor.constraint(equalTo: bottomAnchor),
            indicator.heightAnchor.constraint(equalToConstant: 2),
        ])

        updateAppearance(animated: false)
    }

    @objc private func buttonTapped(_ sender: UIButton) {
        select(index: sender.tag, animated: true)
        onSelect?(sender.tag)
    }

    func select(index: Int, animated: Bool) {
        guard titles.indices.contains(index), index != selectedIndex else { return }
        selectedIndex = index
        updateAppearance(animated: animated)
    }

    private func updateAppearance(animated: Bool) {
        for (index, button) in buttons.enumerated() {
            let isSelected = index == selectedIndex
            button.setTitleColor(isSelected ? MaterialPalette.primary : MaterialPalette.textSecondary, for: .normal)
        }

        let selectedButton = buttons[selectedIndex]
        indicatorLeadingConstraint?.isActive = false
        indicatorWidthConstraint?.isActive = false
        indicatorLeadingConstraint = indicator.leadingAnchor.constraint(equalTo: selectedButton.leadingAnchor)
        indicatorWidthConstraint = indicator.widthAnchor.constraint(equalTo: selectedButton.widthAnchor)
        indicatorLeadingConstraint?.isActive = true
        indicatorWidthConstraint?.isActive = true

        if animated {
            UIView.animate(withDuration: 0.2) {
                self.layoutIfNeeded()
            }
        }
    }
}

// MARK: - CategoryChipBar

/// A horizontally scrolling row of category chips. Rebuilt via
/// `configure(titles:selectedIndex:)` whenever the category list changes
/// (e.g. switching between 全部股票 and 自選).
private final class CategoryChipBar: UIView {

    var onSelect: ((Int) -> Void)?

    private let scrollView = UIScrollView()
    private let stack = UIStackView()
    private var buttons: [ChipButton] = []
    private var selectedIndex: Int = 0

    init() {
        super.init(frame: .zero)
        setUpViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpViews() {
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)

        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            stack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stack.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
        ])
    }

    func configure(titles: [String], selectedIndex: Int) {
        buttons.forEach { $0.removeFromSuperview() }
        buttons = titles.enumerated().map { index, title in
            let button = ChipButton(title: title)
            button.tag = index
            button.addTarget(self, action: #selector(chipTapped(_:)), for: .touchUpInside)
            return button
        }
        buttons.forEach { stack.addArrangedSubview($0) }
        self.selectedIndex = selectedIndex
        updateSelection()
    }

    @objc private func chipTapped(_ sender: UIButton) {
        selectedIndex = sender.tag
        updateSelection()
        onSelect?(sender.tag)
    }

    private func updateSelection() {
        for (index, button) in buttons.enumerated() {
            button.setSelected(index == selectedIndex)
        }
    }
}

/// A rounded, pill-shaped filter chip used inside `CategoryChipBar`.
private final class ChipButton: UIButton {

    init(title: String) {
        super.init(frame: .zero)
        var config = UIButton.Configuration.plain()
        config.title = title
        config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 14, bottom: 6, trailing: 14)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 13, weight: .medium)
            return outgoing
        }
        configuration = config
        layer.cornerRadius = 16
        layer.borderWidth = 1
        clipsToBounds = true
        setSelected(false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setSelected(_ selected: Bool) {
        configuration?.baseForegroundColor = selected ? MaterialPalette.onPrimary : MaterialPalette.textSecondary
        backgroundColor = selected ? MaterialPalette.primary : .clear
        layer.borderColor = (selected ? MaterialPalette.primary : MaterialPalette.divider).cgColor
    }
}

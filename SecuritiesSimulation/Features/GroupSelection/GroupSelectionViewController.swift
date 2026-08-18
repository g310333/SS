//
//  GroupSelectionViewController.swift
//  SecuritiesSimulation
//

import UIKit
import Combine

/// "加入自選群組" sheet: lets the user pick which watchlist groups a stock
/// belongs to, or create a new one. Presented modally (as a sheet) from the
/// stock detail screen's star button.
///
/// Backed entirely by in-memory mock state via `GroupSelectionViewModel` —
/// no watchlist service is wired up yet.
final class GroupSelectionViewController: UIViewController {

    private let viewModel: GroupSelectionViewModel
    private var cancellables = Set<AnyCancellable>()

    /// Reports the confirmed group selection back to the presenter once the
    /// user taps 完成.
    var onConfirm: ((Set<WatchlistGroup>) -> Void)?

    private let titleLabel = UILabel()
    private let closeButton = UIButton(type: .system)
    private let listContainerView = UIView()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    private let errorLabel = UILabel()
    private let addGroupButton = UIButton(type: .system)
    private let confirmButton = UIButton(configuration: .filled())

    /// Backing store for `tableView`, kept separate from `viewModel.state` so
    /// the data source methods only ever reflect the last rendered snapshot.
    private var groups: [WatchlistGroup] = []
    private var selectedGroupIDs: Set<Int> = []

    init(viewModel: GroupSelectionViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = MaterialPalette.background

        setUpLayout()
        setUpActions()
        bindViewModel()

        viewModel.onAddGroupFailed = { [weak self] in
            self?.presentAddGroupFailedAlert()
        }
    }

    // MARK: - Layout

    private func setUpLayout() {
        titleLabel.text = "加入自選群組"
        titleLabel.font = .systemFont(ofSize: 17, weight: .bold)
        titleLabel.textColor = MaterialPalette.textPrimary

        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = MaterialPalette.textSecondary

        let headerRow = UIStackView(arrangedSubviews: [titleLabel, UIView(), closeButton])
        headerRow.axis = .horizontal
        headerRow.alignment = .center

        tableView.register(GroupCell.self, forCellReuseIdentifier: GroupCell.reuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 52
        tableView.separatorInset = .zero

        errorLabel.font = .systemFont(ofSize: 14)
        errorLabel.textColor = MaterialPalette.textSecondary
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 0

        setUpListContainer()

        var addGroupConfig = UIButton.Configuration.plain()
        addGroupConfig.title = "新增群組"
        addGroupConfig.image = UIImage(systemName: "plus.circle")
        addGroupConfig.imagePadding = 6
        addGroupConfig.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 4, bottom: 12, trailing: 4)
        addGroupConfig.baseForegroundColor = MaterialPalette.primary
        addGroupButton.configuration = addGroupConfig

        var confirmConfig = UIButton.Configuration.filled()
        confirmConfig.title = "完成"
        confirmConfig.baseBackgroundColor = MaterialPalette.primary
        confirmConfig.baseForegroundColor = MaterialPalette.onPrimary
        confirmConfig.cornerStyle = .medium
        confirmButton.configuration = confirmConfig

        let rootStack = UIStackView(arrangedSubviews: [headerRow, listContainerView, addGroupButton, confirmButton])
        rootStack.axis = .vertical
        rootStack.spacing = 8
        rootStack.setCustomSpacing(16, after: headerRow)
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(rootStack)

        NSLayoutConstraint.activate([
            rootStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            rootStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            rootStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            rootStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),

            confirmButton.heightAnchor.constraint(equalToConstant: 48),
        ])
    }

    /// `tableView`, `loadingIndicator`, and `errorLabel` occupy the same
    /// region and are toggled by `render(_:)` rather than swapped in and out
    /// of the stack, so the rows above and below never reflow as the load
    /// state changes.
    ///
    /// Only `tableView` is pinned edge-to-edge (required) to
    /// `listContainerView` — it's the one view with no opinion of its own
    /// height, so it's safe to let it define the container's size. Pinning
    /// `loadingIndicator`/`errorLabel` the same way would force
    /// `listContainerView` to equal *their* small intrinsic height too
    /// (`isHidden` doesn't exempt a plain constrained subview from layout,
    /// only a `UIStackView` arranged subview), collapsing the whole
    /// container — and the table with it — down to a couple dozen points
    /// regardless of loading state. Centering them instead keeps them out of
    /// that sizing negotiation entirely.
    private func setUpListContainer() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        listContainerView.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: listContainerView.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: listContainerView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: listContainerView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: listContainerView.bottomAnchor),
        ])

        for subview in [loadingIndicator, errorLabel] {
            subview.translatesAutoresizingMaskIntoConstraints = false
            listContainerView.addSubview(subview)
            NSLayoutConstraint.activate([
                subview.centerXAnchor.constraint(equalTo: listContainerView.centerXAnchor),
                subview.centerYAnchor.constraint(equalTo: listContainerView.centerYAnchor),
                subview.leadingAnchor.constraint(greaterThanOrEqualTo: listContainerView.leadingAnchor, constant: 24),
                subview.trailingAnchor.constraint(lessThanOrEqualTo: listContainerView.trailingAnchor, constant: -24),
            ])
        }
    }

    // MARK: - Actions

    private func setUpActions() {
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        addGroupButton.addTarget(self, action: #selector(addGroupButtonTapped), for: .touchUpInside)
        confirmButton.addTarget(self, action: #selector(confirmButtonTapped), for: .touchUpInside)
    }

    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }

    @objc private func addGroupButtonTapped() {
        let alert = UIAlertController(title: "新增群組", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "群組名稱"
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "新增", style: .default) { [weak self, weak alert] _ in
            guard let name = alert?.textFields?.first?.text else { return }
            self?.viewModel.addGroup(name: name)
        })
        present(alert, animated: true)
    }

    private func presentAddGroupFailedAlert() {
        let alert = UIAlertController(title: "新增群組失敗", message: "請稍後再試", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "確定", style: .default))
        present(alert, animated: true)
    }

    @objc private func confirmButtonTapped() {
        let selectedGroups = groups.filter { selectedGroupIDs.contains($0.id) }
        onConfirm?(Set(selectedGroups))
        dismiss(animated: true)
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

    private func render(_ state: GroupSelectionViewState) {
        groups = state.groups
        selectedGroupIDs = state.selectedGroupIDs
        confirmButton.isEnabled = state.isConfirmEnabled
        confirmButton.alpha = state.isConfirmEnabled ? 1 : 0.5

        if state.isLoading {
            loadingIndicator.startAnimating()
            tableView.isHidden = true
            errorLabel.isHidden = true
        } else if let message = state.errorMessage {
            loadingIndicator.stopAnimating()
            tableView.isHidden = true
            errorLabel.isHidden = false
            errorLabel.text = message
        } else {
            loadingIndicator.stopAnimating()
            errorLabel.isHidden = true
            tableView.isHidden = false
            tableView.reloadData()
        }
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension GroupSelectionViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        groups.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: GroupCell.reuseIdentifier, for: indexPath) as! GroupCell
        let group = groups[indexPath.row]
        cell.configure(name: group.name, isSelected: selectedGroupIDs.contains(group.id))
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.toggleGroup(id: groups[indexPath.row].id)
    }
}

// MARK: - GroupCell

/// A single watchlist-group row: name on the left, a filled/empty circle
/// checkmark on the right showing selection state.
private final class GroupCell: UITableViewCell {

    static let reuseIdentifier = "GroupCell"

    private let nameLabel = UILabel()
    private let checkmarkImageView = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUpViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpViews() {
        selectionStyle = .none

        nameLabel.font = .systemFont(ofSize: 15)
        nameLabel.textColor = MaterialPalette.textPrimary

        checkmarkImageView.contentMode = .scaleAspectFit
        checkmarkImageView.setContentHuggingPriority(.required, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [nameLabel, UIView(), checkmarkImageView])
        row.axis = .horizontal
        row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(row)

        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            row.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkmarkImageView.widthAnchor.constraint(equalToConstant: 22),
            checkmarkImageView.heightAnchor.constraint(equalToConstant: 22),
        ])
    }

    func configure(name: String, isSelected: Bool) {
        nameLabel.text = name
        checkmarkImageView.image = UIImage(systemName: isSelected ? "checkmark.circle.fill" : "circle")
        checkmarkImageView.tintColor = isSelected ? MaterialPalette.primary : MaterialPalette.divider
    }
}

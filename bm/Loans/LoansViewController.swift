//
//  ViewController.swift
//  bm
//
//  Created by Vincent Tourraine on 30/07/2019.
//  Copyright © 2019 Studio AMANgA. All rights reserved.
//

import UIKit

import WebKit
import SafariServices

class LoansViewController: UITableViewController {

    enum State {
        case loans([Item])
        case notLoggedIn
    }
    var state: State = .notLoggedIn
    var loader: GhostLoader?
    var isFirstLaunch = true
    var lastRefreshDate: Date?

    let LoginSegueIdentifier = "Login"
    let CardSegueIdentifier = "Card"
    let AboutSegueIdentifier = "About"
    let LibrariesSegueIdentifier = "Libraries"
    let SearchSegueIdentifier = "Search"

    let LoansNotLoggedInViewXIB = "LoansNotLoggedInView"

    // MARK: - View life cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        let infoButton = UIButton(type: .infoLight)
        infoButton.tintColor = .white
        infoButton.addTarget(self, action: #selector(openAboutScreen(sender:)), for: .touchUpInside)
        let MinimumTargetSize: CGFloat = 44
        infoButton.frame = CGRect(x: 0, y: 0, width: MinimumTargetSize, height: MinimumTargetSize)
        let infoBarButtonItem = UIBarButtonItem(customView: infoButton)
        navigationItem.rightBarButtonItem = infoBarButtonItem

        refreshControl?.tintColor = .white

        tableView.tableFooterView = UIView(frame: CGRect.zero)

        if Credentials.load(from: .standard) == nil {
            reloadData(state: .notLoggedIn)
        }
        else if let itemCache = ItemCache.load(from: .standard) {
            reloadData(state: .loans(itemCache.items))
        }

        navigationController?.configureCustomAppearance()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if isFirstLaunch {
            // loadDemoData()
            if Credentials.load(from: .standard) != nil {
                refresh(sender: nil)
            }

            isFirstLaunch = false
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let aboutViewController = segue.destination as? AboutViewController {
            let userIsLoggedIn = (Credentials.load(from: .standard) != nil)
            aboutViewController.userIsLoggedIn = userIsLoggedIn
        }
    }

    func configureNotLoggedInPlaceholder() {
        if let placeholderView = Bundle.main.loadNibNamed(LoansNotLoggedInViewXIB, owner: self, options: nil)?.first as? UIView {
            for subview in placeholderView.subviews {
                if let button = subview as? UIButton {
                    button.configureRoundCorners()
                    button.titleLabel?.adjustsFontSizeToFitWidth = true
                    button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
                }
            }
            tableView.backgroundView = placeholderView
        }
    }

    func configureEmptyListPlaceholder() {
        let label = UILabel(frame: .zero)
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.textColor = .gray
        label.textAlignment = .center
        label.text = NSLocalizedString("No Current Loans", comment: "")
        label.adjustsFontSizeToFitWidth = true
        tableView.backgroundView = label
    }

    func reloadData(state: State) {
        self.state = state
        tableView.reloadData()

        switch state {
        case .loans(let items):
            if items.isEmpty {
                configureEmptyListPlaceholder()
            }
            else {
                tableView.backgroundView = nil
            }

        case .notLoggedIn:
            configureNotLoggedInPlaceholder()
        }
    }

    func loadDemoData() {
        let fileName = "DemoAccountLoans"
        let path = Bundle(for: type(of: self)).path(forResource: fileName, ofType: "html")
        let html = try? String(contentsOfFile: path!)
        let loans = PageParser.parseLoans(html: html!)
        reloadData(state: .loans(loans!.items))
    }

    func item(at indexPath: IndexPath) -> Item? {
        switch state {
        case .loans(let items):
            return items[indexPath.row]

        default:
            return nil
        }
    }

    func configureToolbar(message: String?, animated: Bool) {
        guard let message = message else {
            navigationController?.setToolbarHidden(true, animated: animated)
            return
        }

        let spaceItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let label = UILabel(frame: .zero)
        label.text = message
        label.font = UIFont.preferredFont(forTextStyle: .footnote)
        let labelItem = UIBarButtonItem(customView: label)
        setToolbarItems([spaceItem, labelItem, spaceItem], animated: false)
        navigationController?.setToolbarHidden(false, animated: animated)
    }

    func refreshIfNecessary() {
        guard let lastRefreshDate = lastRefreshDate else {
            return
        }

        // Refresh every hour
        let minimumRefreshInterval: TimeInterval = (60 * 60)
        if lastRefreshDate.timeIntervalSinceNow < -minimumRefreshInterval {
            refresh(sender: nil)
        }
    }

    // MARK: - Actions

    @objc func openAboutScreen(sender: Any) {
        self.performSegue(withIdentifier: self.AboutSegueIdentifier, sender: nil)
    }

    @IBAction func refresh(sender: Any?) {
        guard loader == nil, let credentials = Credentials.load(from: .standard) else {
            return
        }

        configureToolbar(message: NSLocalizedString("Updating Account…", comment: ""), animated: false)

        loader = GhostLoader(credentials: credentials, parentView: view, success: { (items) in
            self.reloadData(state: .loans(items))

            let itemCache = ItemCache(items: items)
            ItemCache.save(items: itemCache, to: .standard)

            self.refreshControl?.endRefreshing()
            self.configureToolbar(message: nil, animated: true)
            self.loader = nil
            self.lastRefreshDate = Date()
        }) { (error) in
            self.presentLoadingError(error)
            self.refreshControl?.endRefreshing()
            self.configureToolbar(message: nil, animated: true)
            self.loader = nil
        }
    }

    func openInGoodreads(item: Item) {
        guard let query = item.title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let url = URL(string: "https://www.goodreads.com/search?q=\(query)") else {
                return
        }

        UIApplication.shared.open(url, options: [.universalLinksOnly: true]) { (result) in
            if result == false {
                self.presentSafariViewController(url)
            }
        }
    }

    @IBAction func presentLoginScreen(sender: Any?) {
        performSegue(withIdentifier: LoginSegueIdentifier, sender: sender)
    }

    @objc func presentLibrariesScreen(sender: Any?) {
        performSegue(withIdentifier: LibrariesSegueIdentifier, sender: sender)
    }

    @objc func presentSearchScreen(sender: Any?) {
        performSegue(withIdentifier: SearchSegueIdentifier, sender: sender)
    }

    // MARK: - Table view

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch state {
        case .loans(let items):
            return items.count

        default:
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! ItemTableViewCell
        if let item = self.item(at: indexPath) {
            cell.configure(item: item)
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let item = self.item(at: indexPath) else {
            return nil
        }

        let action = UIContextualAction(style: .normal, title: NSLocalizedString("Search on Goodreads", comment: "")) { (action, view, completion) in
            self.openInGoodreads(item: item)
        }

        if #available(iOS 13.0, *) {
            action.image = UIImage(systemName: "safari")
        }

        let configuration = UISwipeActionsConfiguration(actions: [action])
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }
}

extension UINavigationController {
    func configureCustomAppearance() {
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
            var largeTitleTextAttributes = appearance.largeTitleTextAttributes
            largeTitleTextAttributes[NSAttributedString.Key.font] = UIFont.boldSystemFont(ofSize: 34)
            largeTitleTextAttributes[NSAttributedString.Key.foregroundColor] = UIColor.white
            appearance.largeTitleTextAttributes = largeTitleTextAttributes
            appearance.backgroundColor = .BMRed
            navigationBar.tintColor = .white
            navigationBar.scrollEdgeAppearance = appearance
            navigationBar.standardAppearance = appearance
        }
    }
}

//
//  ViewController.swift
//  RxTabular
//
//  Created by Nuno Mota on 25/05/2022.
//

import UIKit
import RealmSwift
import RxSwift
import RxCocoa

class MainViewController: UIViewController {
    
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var searchBar: UISearchBar! {
        didSet {
            searchBar.isUserInteractionEnabled = true
            searchBar.backgroundImage = UIImage()
            searchBar.backgroundColor = .clear
            searchBar.barTintColor = .clear
            searchBar.delegate = self
            searchBar.placeholder = "Type here to search..."
        }
    }
    @IBOutlet private weak var tableView: UITableView! {
        didSet {
            tableView.separatorStyle = .none
            tableView.register(UINib(nibName: "PostalTableViewCell", bundle: nil), forCellReuseIdentifier: PostalTableViewCell.identifier)
        }
    }
    
    @IBOutlet private weak var tableViewBottomAnchor: NSLayoutConstraint!
    
    
    
    private var disposeBag = DisposeBag()
    private var viewmodel:MainViewModel!
    
    
    //MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isHidden = true
        setupView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        NotificationCenter.default.removeObserver(self)
    }
    
    //MARK: - Setup Functions
    private func setupView() {
        /// Bind Search bar to update contents as user types
        let searchDriver = searchBar.rx
            .text
            .orEmpty
            .asDriver()
        
        viewmodel = MainViewModel(repositoryService: Resolver.shared.resolve(), searchDriver: searchDriver)
        /// To be able to set tableView row height
        tableView.rx
            .setDelegate(self)
            .disposed(by: disposeBag)
        
        /// Search next page of content when tableview is scrolled to the bottom
        tableView.rx
            .contentOffset
            .asDriver()
            .skip(1)
            .throttle(.seconds(1))
            .drive(onNext: { [weak self] offset in
                guard let self = self else { return }

                let offsetY = offset.y
                let contentHeight = self.tableView.contentSize.height
                let tableViewFrameHeight = self.tableView.frame.height
                
                guard offsetY > contentHeight - tableViewFrameHeight else { return }
                self.viewmodel.getContent(reset: false, searchText: self.searchBar.text)
            })
            .disposed(by: disposeBag)
        
        /// Bind postal codes to the tableView
        viewmodel
            .postalCodes
            .asObservable()
            .bind(to: tableView.rx.items(cellIdentifier: PostalTableViewCell.identifier, cellType: PostalTableViewCell.self)) { [weak self] index, postalModel, cell in
            
                guard let self = self else { return }
                let cellViewModel = self.viewmodel.getViewmodelFor(index: index)
                cell.configure(with: cellViewModel)
            }
            .disposed(by: disposeBag)
        
        
        viewmodel
            .isLoading
            .asObservable()
            .bind { [weak self] animate in
            DispatchQueue.main.async {
                self?.activityIndicator.isHidden = !animate
            }
        }
        .disposed(by: disposeBag)
        
        viewmodel.getContent(reset: true)
        
    }
    
    /// Bring TableView up with keyboard
    /// to prevent content being covered by the keyboard
    @objc
    private func keyboardWillShow(notification: Notification) {
        if let keyboardHeight = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height {
            
            tableViewBottomAnchor.constant = keyboardHeight
            view.layoutIfNeeded()
        }
    }

    /// Reset TableView to original position
    @objc
    private func keyboardWillHide(notification: Notification) {
        tableViewBottomAnchor.constant = 0
        view.layoutIfNeeded()
    }

}

//MARK: - UITableViewDelegate
extension MainViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 56
    }
}

//MARK: - SEARCH DELEGATE
/// allows MainViewController to respond to changes to the search bar
extension MainViewController: UISearchBarDelegate {}


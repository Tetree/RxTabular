//
//  MainViewModel.swift
//  RxTabular
//
//  Created by Nuno Mota on 25/05/2022.
//

import Foundation
import RxSwift
import RxRelay
import RxCocoa
import RealmSwift

final class MainViewModel {
    
    private let pageSize = 30
    private var disposeBag = DisposeBag()
    private(set) var postalCodes = BehaviorRelay<[PostalModel]>(value: [])
    
    private let searchDriver:Driver<String>
    
    /// boolean flag to prevent multiple requests in a row when scrolling to next page
    private(set) var isLoading = BehaviorRelay<Bool>(value: false)
    
    init(searchDriver: Driver<String>) {
        self.searchDriver = searchDriver
        
        self.searchDriver
            .throttle(.seconds(1))
            .distinctUntilChanged()
            .drive { [weak self] query in
                self?.getContent(reset: true, searchText: query)
            }
            .disposed(by: disposeBag)
    }
    
    //MARK: - Content Functions
    func getContent(reset: Bool, searchText: String? = nil) {
        isLoading.accept(true)
        if let query = searchText, !query.isEmpty {
            getContentWithFilters(reset: reset, searchText: query)
        }else {
            getContentForNoFilters(reset: reset)
        }
        
    }
    
    /// Get content from local database (Realm) without any search queries
    private func getContentForNoFilters(reset: Bool) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            do {
                let realm = try Realm()
                let filteredResults = realm.objects(PostalDTO.self)
                    
                self.updateContentForNewResults(reset: reset, results: filteredResults)
            } catch {
                debugPrint("getContentForNoFilters failed with error: \(error.localizedDescription)")
                self.isLoading.accept(false)
            }
            
        }
    }
    
    /// Get content from local database (Realm) with search queries
    private func getContentWithFilters(reset: Bool, searchText: String) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            do {
                
                /// break search query into components
                let searchTerms = searchText.split(separator: " ")
                let realm = try Realm()
                
                /// create the query parameters
                /// we check if the "postal" property of the PostalDTO object contains each of the search terms
                /// typed by the user with diacritic insensitivity so Realm treats special characters as the base character (e.g. é -> e).
                var predicates = [NSPredicate]()
                for term in searchTerms {
                    let predicate = NSPredicate.init(format: "postal CONTAINS[cd] %@", term as NSString)
                    
                    predicates.append(predicate)
                }
                
                /// set the query parameters
                let query = NSCompoundPredicate(type: NSCompoundPredicate.LogicalType.and, subpredicates: predicates)
                
                let filteredResults = realm.objects(PostalDTO.self)
                    .filter(query)
                
                self.updateContentForNewResults(reset: reset, results: filteredResults)
                
            } catch {
                debugPrint("getContentWithFilters failed with error: \(error.localizedDescription)")
                self.isLoading.accept(false)
            }
        }
    }
    
    private func updateContentForNewResults(reset: Bool, results: Results<PostalDTO>) {
        /// Realm can't be accessed from different threads and since any data fetch requests are done in the background
        /// we convert the data to a new Array of PostalModel t be used in the Main Thread from the results returned
        var mappedArray = [PostalModel]()
        
        /// start index of the results content to be mapped and displayed
        let startIndex = reset ? 0 : postalCodes.value.count
        
        /// map/display at most only 30 elements per page
        ///  Realm results are lazy loaded so we always fetch the complete set of results
        ///  but access at most 30 at a time to display on our table view in a
        ///  continuous pagination
        for i in startIndex..<min(pageSize + startIndex, results.count) {
            
            if i >= results.count { break }
            let postalDTO = results[i]
            
            let postalModel = PostalModel(postalNumber: postalDTO.postalNumber, postalExtension: postalDTO.postalExtension, postalDesignation: postalDTO.postalDesignation, postal: postalDTO.postal)
            
            mappedArray.append(postalModel)
        }

        if reset {
            postalCodes.accept(mappedArray)
        }else {
            var newValue = postalCodes.value
            newValue.append(contentsOf: mappedArray)
            postalCodes.accept(newValue)
        }
        isLoading.accept(false)
    }
    
    func getViewmodelFor(index: Int) -> PostalCellViewModel {
        let model = postalCodes.value[index]
        return PostalCellViewModel(model: model)
    }
    
}

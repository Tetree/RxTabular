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
    
    private let repositoryService:RepositoryServiceable
    private let pageSize = 30
    private var disposeBag = DisposeBag()
    private(set) var postalCodes = BehaviorRelay<[PostalModel]>(value: [])
    
    private let searchDriver:Driver<String>
    
    /// boolean flag to prevent multiple requests in a row when scrolling to next page
    private(set) var isLoading = BehaviorRelay<Bool>(value: false)
    
    init(repositoryService:RepositoryServiceable, searchDriver: Driver<String>) {
        self.repositoryService = repositoryService
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
        repositoryService.getContent(reset: reset, searchText: searchText) { [weak self] result in
            switch result {
            case .success(let results):
                self?.updateContentForNewResults(reset: reset, results: results)
            case .failure(let error):
                print("Failed with error: \(error.localizedDescription)")
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

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
    private let postalCodes = BehaviorRelay<[PostalModel]>(value: [])
    
    var postalObserver:Observable<[PostalModel]> {
        postalCodes.asObservable()
    }
    
    private let searchDriver:Driver<String>
    private let scrollOffsetDriver:Driver<CGPoint>
    
    /// boolean flag to prevent multiple requests in a row when scrolling to next page
    private let isLoading = BehaviorRelay<Bool>(value: false)
    
    var isLoadingObservable:Observable<Bool> {
        isLoading.asObservable()
    }
    
    var tableviewDidScrollToBottom: ((CGPoint) -> (Bool, String?))?
    
    init(repositoryService:RepositoryServiceable, searchDriver: Driver<String>,
         scrollOffsetDriver: Driver<CGPoint>) {
        
        self.repositoryService = repositoryService
        self.searchDriver = searchDriver
        self.scrollOffsetDriver = scrollOffsetDriver
        
        self.searchDriver
            .throttle(.seconds(1))
            .distinctUntilChanged()
            .drive { [weak self] query in
                self?.getContent(reset: true, searchText: query)
            }
            .disposed(by: disposeBag)
        
        self.scrollOffsetDriver
            .skip(1)
            .throttle(.seconds(1))
            .drive(onNext: { [weak self] offset in
                guard let self = self else { return }

                let canFetchNextContentResult = self.tableviewDidScrollToBottom?(offset)
 
                guard canFetchNextContentResult?.0 == true else { return }
                self.getContent(reset: false, searchText: canFetchNextContentResult?.1)
            })
            .disposed(by: disposeBag)
    }
    
    func start() {
        getContent(reset: true)
    }
    
    //MARK: - Content Functions
    private func getContent(reset: Bool, searchText: String? = nil) {
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

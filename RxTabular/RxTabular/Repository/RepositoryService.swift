//
//  RepositoryService.swift
//  RxTabular
//
//  Created by Nuno Mota on 26/05/2022.
//

import Foundation
import RealmSwift

final class RepositoryService: RepositoryServiceable {
    
    func getContent(reset: Bool, searchText: String? = nil, completionHandler: @escaping RepositoryCallback) {
        if let query = searchText, !query.isEmpty {
            getContentWithFilters(reset: reset, searchText: query, completionHandler: completionHandler)
        }else {
            getContentForNoFilters(reset: reset, completionHandler: completionHandler)
        }
    }
    
    /// Get content from local database (Realm) without any search queries
    private func getContentForNoFilters(reset: Bool, completionHandler: @escaping RepositoryCallback) {
        DispatchQueue.global(qos: .background).async {
            do {
                let realm = try Realm()
                let filteredResults = realm.objects(PostalDTO.self)
                
                completionHandler(.success(filteredResults))
            } catch {
                debugPrint("getContentForNoFilters failed with error: \(error.localizedDescription)")
                completionHandler(.failure(error))
            }
        }
    }
    
    /// Get content from local database (Realm) with search queries
    private func getContentWithFilters(reset: Bool, searchText: String, completionHandler: @escaping RepositoryCallback) {
        DispatchQueue.global(qos: .background).async { 
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
                
                completionHandler(.success(filteredResults))
            } catch {
                debugPrint("getContentWithFilters failed with error: \(error.localizedDescription)")
                completionHandler(.failure(error))
            }
        }
    }
}

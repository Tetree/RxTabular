//
//  RepositoryServiceable.swift
//  RxTabular
//
//  Created by Nuno Mota on 26/05/2022.
//

import Foundation
import RealmSwift

protocol RepositoryServiceable {
    typealias RepositoryCallback = (Result<Results<PostalDTO>, Error>) -> Void
    func getContent(reset: Bool, searchText: String?, completionHandler:@escaping RepositoryCallback)
}

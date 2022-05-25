//
//  PostalCellViewModel.swift
//  RxTabular
//
//  Created by Nuno Mota on 25/05/2022.
//

import Foundation

final class PostalCellViewModel {
    
    let model:PostalModel
    
    init(model: PostalModel) {
        self.model = model
    }
    
    var getPostalCode:String { "\(model.postalNumber)-\(model.postalExtension)" }
    var getPostalDesignation:String { "\(model.postalDesignation)" }
}

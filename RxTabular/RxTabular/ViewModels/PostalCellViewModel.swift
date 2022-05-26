//
//  PostalCellViewModel.swift
//  RxTabular
//
//  Created by Nuno Mota on 25/05/2022.
//

import Foundation

struct PostalCellViewModel {
    
    let model:PostalModel
    
    var getPostalCode:String { "\(model.postalNumber)-\(model.postalExtension)" }
    var getPostalDesignation:String { "\(model.postalDesignation)" }
}

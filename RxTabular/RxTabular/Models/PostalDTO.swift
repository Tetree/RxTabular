//
//  PostalDTO.swift
//  RxTabular
//
//  Created by Nuno Mota on 25/05/2022.
//

import Foundation
import RealmSwift

final class PostalDTO : Object {
    @Persisted private(set) var postalNumber:String
    @Persisted private(set) var postalExtension:String
    @Persisted private(set) var postalDesignation:String
    @Persisted private(set) var postal:String
    
    /// hash value to be able to differentiate when we create a Set<PostalDTO>
    override var hash: Int {
        return postal.hashValue
    }
    
    convenience init(postalNumber: String, postalExtension: String, postalDesignation: String) {
        self.init()
        self.postalNumber = postalNumber
        self.postalExtension = postalExtension
        self.postalDesignation = postalDesignation
        self.postal = "\(postalNumber)-\(postalExtension) \(postalDesignation)"
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        if let newPostal = object as? PostalDTO {
            return self.postal == newPostal.postal
        }
        return false
    }
    
}

//
//  Injected.swift
//  RxTabular
//
//  Created by Nuno Mota on 26/05/2022.
//

import Foundation

@propertyWrapper
struct Injected<T: Any> {
    
    let wrappedValue: T
    
    init() {
        wrappedValue = Resolver.shared.resolve()
    }
}

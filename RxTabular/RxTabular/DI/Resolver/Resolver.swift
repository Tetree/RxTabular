//
//  Resolver.swift
//  RxTabular
//
//  Created by Nuno Mota on 26/05/2022.
//

import Foundation

final class Resolver {
    
    static let shared = Resolver()
    private var registeredObjects = [String: () -> AnyObject]()
    private var registeredInstances = [String: AnyObject]()
    
    private init() {}
    
    func register<T>(_ identifier: T.Type, _ injectable:@escaping () -> AnyObject) {
        let identifier = String(describing: T.self)
        registeredObjects[identifier] = injectable
    }
    
    func resolve<T>() -> T {
        
        let identifier = String(describing: T.self)
        guard registeredObjects[identifier] != nil else {
            fatalError("Failed to register object of type \(T.self)")
        }
        
        if let instance = registeredInstances[identifier] {
            return instance as! T
        }else {
            let instance = registeredObjects[identifier]!()
            
            registeredInstances[identifier] = instance
            
            return instance as! T
        }
    }
    
}

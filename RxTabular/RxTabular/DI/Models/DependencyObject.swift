//
//  DependencyObject.swift
//  RxTabular
//
//  Created by Nuno Mota on 26/05/2022.
//

import Foundation

struct DependencyObject {
    let identifier:String
    let creator: () -> Injectable
}

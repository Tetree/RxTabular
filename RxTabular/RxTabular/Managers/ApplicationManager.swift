//
//  ApplicationManager.swift
//  RxTabular
//
//  Created by Nuno Mota on 25/05/2022.
//

import Foundation

/// Manager class to determine if the csv file needs to be downloaded
final class ApplicationManager {

    /// Set a boolean flag to let us know wether we have saved the csv data locally successfully before or
    /// if it's required to do so on app start
    static func setCSVSavedSuccessfully(value: Bool) {
        let userDefaults = Foundation.UserDefaults.standard
        userDefaults.set(value, forKey: Constants.HAS_CSV_SAVED_LOCALLY)
    }
    
    static func hasSetCSVSavedSuccessfully() -> Bool {
        let userDefaults = Foundation.UserDefaults.standard
        return userDefaults.bool(forKey: Constants.HAS_CSV_SAVED_LOCALLY)
    }
    
}


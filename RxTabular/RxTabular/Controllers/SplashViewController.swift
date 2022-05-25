//
//  SplashViewController.swift
//  RxTabular
//
//  Created by Nuno Mota on 25/05/2022.
//

import UIKit
import TabularData
import RealmSwift
import Lottie

class SplashViewController: UIViewController {

    private let goToMainVCSegue = "goToMainVC"
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var animationView: AnimationView! {
        didSet {
            animationView.loopMode = .loop
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

       setupView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animationView.play()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        animationView.pause()
    }
    
    private func setupView() {
        /// check if we have already saved the contents of the csv file locally or not
        if ApplicationManager.hasSetCSVSavedSuccessfully() {
            performSegue(withIdentifier: goToMainVCSegue, sender: nil)
        }else {
            activityIndicator.isHidden = false
            downloadRemoteData { [weak self] data in
                self?.loadDataIntoRealm(data: data)
            }
        }
    }
    
    private func loadDataIntoRealm(data: [PostalDTO]) {
        guard !data.isEmpty else {
            DispatchQueue.main.async { [weak self] in
                self?.activityIndicator.isHidden = true
                self?.showAppLaunchError()
            }
            return
        }
        DispatchQueue.global(qos: .background).async { [weak self] in
            do {
                /// save the data locally into Realm with a batch write
               try autoreleasepool {
                    let realm = try Realm()
                    
                   try realm.write({
                       realm.add(data)
                   })

                    ApplicationManager.setCSVSavedSuccessfully(value: true)
                   
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        self.activityIndicator.isHidden = false
                        self.performSegue(withIdentifier: self.goToMainVCSegue, sender: nil)
                    }
                }
            }catch {
                debugPrint("Failed to save data in Realm with error: \(error.localizedDescription)")
                self?.showAppLaunchError()
            }
        }
    }
    
    private func downloadRemoteData(completionHandler:@escaping ([PostalDTO]) -> Void) {
        guard let url = URL(string: Constants.CSV_URL) else {
            completionHandler([])
            return
        }
        activityIndicator.isHidden = false
        DispatchQueue.global(qos: .background).async {
            do {
                /// names of the columns we need from the csv file
                /// so we can discard the rest and keep only these 3
                let numCodPostalColumn = "num_cod_postal"
                let extCodPostalColumn = "ext_cod_postal"
                let desigPostalColumn = "desig_postal"
                
                let dataFrame = try DataFrame(contentsOfCSVFile: url,
                                              columns: [numCodPostalColumn,
                                                        extCodPostalColumn,
                                                        desigPostalColumn],
                                              types: [numCodPostalColumn: .string,
                                                      extCodPostalColumn: .string,
                                                       desigPostalColumn: .string])
                
                var postalArray = [PostalDTO]()
                
                /// create PostalDTO model objects to be saved in our local database
                for row in dataFrame.rows {
                    
                    if let num = row[0] as? String, let exten = row[1] as? String,
                       let desig = row[2] as? String {
                        let dto = PostalDTO(postalNumber: num, postalExtension: exten, postalDesignation:desig)
                        postalArray.append(dto)
                    }
                    
                }
                
                /// remove the duplicate entries.
                /// Since we are only displaying the postal code and designation there can be more than one entry with the same "postal" property.
                /// We do this by creating a Set with our array and then we sort our array in an ascending order
                let sortedPostalArray = Array(Set(postalArray)).sorted { object1, object2 in
                    object1.postal < object2.postal
                }
                
                completionHandler(sortedPostalArray)
            }catch {
                debugPrint("Failed to get remote data with error: \(error.localizedDescription)")
                
                completionHandler([])
            }
        }
    }

    
    private func showAppLaunchError() {
        DispatchQueue.main.async { [weak self] in
            let alert = UIAlertController(title: "App launch failed", message: "App failed to get remote data.\n Please try again later", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertAction.Style.default, handler: nil))
            self?.present(alert, animated: true, completion: nil)
        }
    }
}

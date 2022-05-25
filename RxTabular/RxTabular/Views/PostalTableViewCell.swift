//
//  PostalTableViewCell.swift
//  RxTabular
//
//  Created by Nuno Mota on 25/05/2022.
//

import UIKit

class PostalTableViewCell: UITableViewCell {
    
    static let identifier = "postalTableViewCellIdentifier"
    
    @IBOutlet private weak var postalCodeLabel: UILabel!
    @IBOutlet private weak var postalDesignationLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        
    }
    
    override func prepareForReuse() {
        postalCodeLabel.text = ""
        postalDesignationLabel.text = ""
    }
    
    func configure(with viewmodel: PostalCellViewModel) {
        postalCodeLabel.text = viewmodel.getPostalCode
        postalDesignationLabel.text = viewmodel.getPostalDesignation
    }

}

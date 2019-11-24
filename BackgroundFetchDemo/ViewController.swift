//
//  ViewController.swift
//  BackgroundFetchDemo
//
//  Created by Subhra Roy on 24/11/19.
//  Copyright © 2019 Subhra Roy. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.updateUI(statusStr: "No data loaded")
    }
    
    func updateUI(statusStr : String?){
        self.titleLabel.text = statusStr ?? "Update With nil text"
        self.dateLabel.text = "\(Date())"
    }


}


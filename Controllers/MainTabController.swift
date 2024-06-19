//
//  MainTabController.swift
//  Mazi
//
//  Created by Jumageldi on 18.06.2024.
//

import Foundation
import UIKit
class MainTabController: UITabBarController{
    @IBInspectable var initialIndex: Int = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        selectedIndex = initialIndex
      configTabs()
    }
    
    private func configTabs(){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let homeVC = storyboard.instantiateViewController(withIdentifier: "HomeViewController")
        let addVC = storyboard.instantiateViewController(withIdentifier: "AddViewController")
        let archiveVC = storyboard.instantiateViewController(withIdentifier: "ArchiveViewController")
        let tabBarList = [homeVC,addVC, archiveVC]
        viewControllers = tabBarList
    }
}

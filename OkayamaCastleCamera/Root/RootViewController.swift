//
//  RootViewController.swift
//  OkayamaCastleCamera
//
//  Created by Yutaro Muta on 2018/09/25.
//  Copyright © 2018 Yutaro Muta. All rights reserved.
//

import UIKit

final class RootViewController: UITableViewController {

    let modes = Mode.allCases

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return modes.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = modes[indexPath.row].title
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let viewController = modes[indexPath.row].viewController
        navigationController?.pushViewController(viewController, animated: true)
    }
}

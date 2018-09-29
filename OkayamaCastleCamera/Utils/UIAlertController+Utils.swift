//
//  UIAlertController+Utils.swift
//  OkayamaCastleCamera
//

import UIKit

extension UIAlertController {

    static func showAlert(title: String?, message: String?, on viewController: UIViewController) {
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(okAction)
        viewController.present(alert, animated: true, completion: nil)
    }

}

//
//  Mode.swift
//  OkayamaCastleCamera
//
//  Created by Yutaro Muta on 2018/09/25.
//  Copyright © 2018 Yutaro Muta. All rights reserved.
//

import UIKit

enum Mode: CaseIterable {
    case realtimeMask
    case portraitMatte

    var title: String {
        switch self {
        case .realtimeMask:
            return "RealtimeMask"
        case .portraitMatte:
            return "PortraitMatte"
        }
    }

    var viewController: UIViewController {
        switch self {
        case .realtimeMask:
            return UIStoryboard(name: "RealtimeMask", bundle:  nil).instantiateViewController(withIdentifier: "RealtimeMaskViewController")
        case .portraitMatte:
            return UIStoryboard(name: "PortraitMatte", bundle:  nil).instantiateViewController(withIdentifier: "PortraitMatteViewController")
        }
    }
}

//
//  AssetCell.swift
//  OkayamaCastleCamera
//
//  Created by Yutaro Muta on 2018/09/26.
//  Copyright © 2018 Yutaro Muta. All rights reserved.
//

import UIKit

final class AssetCell: UICollectionViewCell {

    @IBOutlet weak var assetImageView: UIImageView!

    override func prepareForReuse() {
        super.prepareForReuse()
        assetImageView.image = nil
    }

    func configure(_ image: UIImage?) {
        assetImageView.image = image
    }

}

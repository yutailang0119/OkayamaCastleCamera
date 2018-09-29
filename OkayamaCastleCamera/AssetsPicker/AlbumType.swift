//
//  AlbumType.swift
//  OkayamaCastleCamera
//
//  Created by Yutaro Muta on 2018/09/26.
//  Copyright © 2018 Yutaro Muta. All rights reserved.
//

import Photos

enum AlbumType {
    case all
    case depth

    var assets: [PHAsset] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        let assetsFetchResult: PHFetchResult<PHAsset>
        switch self {
        case .all:
            assetsFetchResult = PHAsset.fetchAssets(with: .image, options: options)
        case .depth:
            let albums = PHAssetCollection.fetchAssetCollections(with: PHAssetCollectionType.smartAlbum, subtype: PHAssetCollectionSubtype.smartAlbumDepthEffect, options: nil)
            guard let assetCollection = (0 ..< albums.count).map({ albums[$0] }).filter({ $0.assetCollectionSubtype == .smartAlbumDepthEffect }).first else {
                return []
            }
            assetsFetchResult = PHAsset.fetchAssets(in: assetCollection, options: options)
        }
        return assetsFetchResult.objects(at: IndexSet(integersIn: (0..<assetsFetchResult.count)))
    }
}

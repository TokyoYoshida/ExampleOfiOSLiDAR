//
//  MenuDataSource.swift
//  ExampleOfiOSLiDAR
//
//  Created by TokyoYoshida on 2021/01/31.
//

import Foundation

struct MenuItem {
    let title: String
    let description: String
    let prefix: String
}

class MenuViewModel {
    private let dataSource = [
        MenuItem (
            title: "Depth Map",
            description: "Display the depth map on the screen.",
            prefix: "DepthMap"
        )
    ]
    
    var count: Int {
        dataSource.count
    }
}

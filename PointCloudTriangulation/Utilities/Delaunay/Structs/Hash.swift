//
//  Hash.swift
//  PointCloudTriangulation
//
//  Created by Eugene Bokhan on 12/8/17.
//  Copyright © 2017 Eugene Bokhan. All rights reserved.
//

import Foundation

func hash_combine(seed: inout UInt, value: UInt) {
    let tmp = value &+ 0x9e3779b9 &+ (seed << 6) &+ (seed >> 2)
    seed ^= tmp
}

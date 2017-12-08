//
//  CircumCircle.swift
//  PointCloudTriangulation
//
//  Created by Eugene Bokhan on 12/8/17.
//  Copyright © 2017 Eugene Bokhan. All rights reserved.
//

import Foundation

/// Represents a bounding circle for a set of 3 vertices
struct CircumCircle {
    let vertex1: Vertex
    let vertex2: Vertex
    let vertex3: Vertex
    let x: Double
    let y: Double
    let rsqr: Double
}

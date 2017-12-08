//
//  TriangleView.swift
//  PointCloudTriangulation
//
//  Created by Eugene Bokhan on 12/8/17.
//  Copyright © 2017 Eugene Bokhan. All rights reserved.
//

import UIKit

public class TriangleView: UIView {
    
    public func recalculate(vertexes: [Vertex]) {
        DispatchQueue.main.async { [weak self] in
            self?.calculateMask(vertices: vertexes)
        }
    }
    
    public func clear() {
        DispatchQueue.main.async { [weak self] in
            if let sublayers = self?.layer.sublayers {
                for sublayer in sublayers {
                    sublayer.removeFromSuperlayer()
                }
            }
        }
    }
    
    private func calculateMask(vertices: [Vertex]) {
        if let sublayers = layer.sublayers {
            for sublayer in sublayers {
                sublayer.removeFromSuperlayer()
            }
        }
        
        let triangles = Delaunay().triangulate(vertices)
        
        for triangle in triangles {
            let triangleLayer = CAShapeLayer()
            triangleLayer.path = triangle.toPath()
            triangleLayer.strokeColor = UIColor.green.cgColor
            triangleLayer.fillColor = UIColor.clear.cgColor
            triangleLayer.backgroundColor = UIColor.white.cgColor
            layer.addSublayer(triangleLayer)
        }
    }
    
}

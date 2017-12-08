//
//  QuadNode.swift
//  PointCloudTriangulation
//
//  Created by Eugene Bokhan on 12/8/17.
//  Copyright © 2017 Eugene Bokhan. All rights reserved.
//

import UIKit
import SceneKit

class QuadNode: SCNNode {
    
    var v0 = SCNVector3()
    var v1 = SCNVector3()
    var v2 = SCNVector3()
    var v3 = SCNVector3()
    
    init(v0: SCNVector3, v1: SCNVector3, v2: SCNVector3, v3: SCNVector3)
    {
        self.v0 = v0
        self.v1 = v1
        self.v2 = v2
        self.v3 = v3
        
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

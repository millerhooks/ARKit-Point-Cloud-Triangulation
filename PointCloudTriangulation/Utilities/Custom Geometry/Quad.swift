//
//  Quad.swift
//  PointCloudTriangulation
//
//  Created by Eugene Bokhan on 12/8/17.
//  Copyright © 2017 Eugene Bokhan. All rights reserved.
//

// A four vertice quad - must either be planar, or if non-planar, note that the
// shared edge will be v0->v2
//
//  v1 --------v0
//  |        _/ |
//  |      _/   |
//  |    _/     |
//  |  _/       |
//  | /         |
//  v2 ------- v3

import SceneKit

import UIKit

class Quad: NSObject {
    
    let v0: SCNVector3
    let v1: SCNVector3
    let v2: SCNVector3
    let v3: SCNVector3
    
    var upQuad: Quad?
    var downQuad: Quad?
    var rightQuad: Quad?
    var leftQuad: Quad?
    
    var plane: SCNNode?
    
    init(v0: SCNVector3, v1: SCNVector3, v2: SCNVector3, v3: SCNVector3)
    {
        self.v0 = v0
        self.v1 = v1
        self.v2 = v2
        self.v3 = v3
    }
    
    func addUpQuad() {
        
        let v0 =  self.rightQuad?.upQuad?.v1 ?? (self.v0 * 2 - self.v3).normalized() * 0.001
        let v1 = self.leftQuad?.upQuad?.v0 ?? (self.v1 * 2 - self.v2).normalized() * 0.001
        let v2 = self.v1
        let v3 = self.v0
        
        let quad = Quad(v0: v0, v1: v1, v2: v2, v3: v3)
        
        self.upQuad = quad
        quad.downQuad = self
        
    }
    
    func addDownQuad() {
        
        let v0 = self.v3
        let v1 = self.v2
        let v2 = self.leftQuad?.downQuad?.v3 ?? (self.v2 * 2 - self.v1).normalized() * 0.001
        let v3 = self.rightQuad?.downQuad?.v2 ?? (self.v3 * 2 - self.v0).normalized() * 0.001
        
        let quad = Quad(v0: v0, v1: v1, v2: v2, v3: v3)
        
        self.downQuad = quad
        quad.upQuad = self
        
    }
    
    func addLeftQuad() {
        
        let v0 = self.v1
        let v1 = self.upQuad?.leftQuad?.v2 ?? (self.v1 * 2 - self.v0).normalized() * 0.001
        let v2 = self.downQuad?.leftQuad?.v1 ?? (self.v2 * 2 - self.v3).normalized() * 0.001
        let v3 = self.v2
        
        let quad = Quad(v0: v0, v1: v1, v2: v2, v3: v3)
        
        self.leftQuad = quad
        quad.rightQuad = self
        
    }
    
    func addRightQuad() {
        
        let v0 = self.rightQuad?.upQuad?.v3 ?? (self.v0 * 2 - self.v1).normalized() * 0.001
        let v1 = self.v0
        let v2 = self.v3
        let v3 = self.rightQuad?.downQuad?.v0 ?? (self.v3 * 2 - self.v2).normalized() * 0.001
        
        let quad = Quad(v0: v0, v1: v1, v2: v2, v3: v3)
        
        self.rightQuad = quad
        quad.leftQuad = self
        
    }
    
    func grow() {
        if upQuad == nil {
            addUpQuad()
            print("Add Up Quad")
        }
        if leftQuad == nil {
            addLeftQuad()
            print("Add Left Quad")
        }
        if downQuad == nil {
            addDownQuad()
            print("Add Down Quad")
        }
        if rightQuad == nil {
            addRightQuad()
            print("Add Right Quad")
        }
    }
    
    class func vector3ToFloat3(vector3: SCNVector3) -> Float3
    {
        return Float3(x: vector3.x, y: vector3.y, z: vector3.z)
    }
}



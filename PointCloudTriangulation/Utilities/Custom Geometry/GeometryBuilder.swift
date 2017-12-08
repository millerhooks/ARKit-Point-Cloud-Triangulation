//
//  GeometryBuilder.swift
//  PointCloudTriangulation
//
//  Created by Eugene Bokhan on 12/8/17.
//  Copyright © 2017 Eugene Bokhan. All rights reserved.
//

import UIKit
import SceneKit

class GeometryBuilder: NSObject {
    
    var quads: [Quad]
    var textureSize: CGPoint
    
    enum UVModeType { case StretchToFitXY, StretchToFitX, StretchToFitY, SizeToWorldUnitsXY, SizeToWorldUnitsX}
    var uvMode = UVModeType.StretchToFitXY
    
    init(uvMode: UVModeType = .StretchToFitXY)
    {
        self.uvMode = uvMode
        
        quads = []
        textureSize = CGPoint(x: 1.0,y: 1.0) // Number of world units represents the textures are mapped to geometry as one full image per unit square
    }
    
    // Add a quad to the geometry - list verticies in counter-clockwise order when looking from the
    // "outside" of the square
    func addQuad(quad: Quad)
    {
        quads.append(quad)
    }
    
    func getGeometry() -> SCNGeometry
    {
        // This one structure holds the position, normal and UV Texture Mapping for a single vertice
        //  - This is called "Interleaving Vertex Data" as explained on the SCNGeometrySource Reference Doc
        struct Vertex
        {
            var position: Float3
            var normal: Float3
            var tcoord: Float2
        }
        
        func debugVertex(label: String, v: Vertex)
        {
//            print("\(label).position: \(v.position.x),\(v.position.y),\(v.position.z)")
//            print("\(label).normal: \(v.normal.x),\(v.normal.y),\(v.normal.z)")
//            print("\(label).tcoord: \(v.tcoord.s),\(v.tcoord.t)")
        }
        
        var verts: [Vertex] = []
        var faceIndices: [CInt] = []
        
        // Walk through the quads, adding 4 vertices, 2 faces and 4 normals per quad
        //  v1 --------------v0
        //  |             __/ |
        //  | face     __/    |
        //  | 1     __/       |
        //  |    __/     face |
        //  | __/           2 |
        //  v2 ------------- v3
        for quad in quads
        {
            // first, calculate normals for each vertice (compute seperately for face1 and face2 - common edge gets avg)
            let nvf1 = SCNUtils.getNormal(v0: quad.v0, v1: quad.v1, v2: quad.v2)
            let nvf2 = SCNUtils.getNormal(v0: quad.v0, v1: quad.v2, v2: quad.v3)
            
            // next, the texture coordinates
            var uv0: Float2
            var uv1: Float2
            var uv2: Float2
            var uv3: Float2
            
            switch uvMode
            {
            // The longest sides dictate the texture tiling, then it is stretched (if nec) across
            case .SizeToWorldUnitsX:
                let longestUEdgeLength = max( (quad.v1-quad.v0).length(), (quad.v2-quad.v3).length() )
                let longestVEdgeLength = max( (quad.v1-quad.v2).length(), (quad.v0-quad.v3).length() )
                uv0 = Float2(s: longestUEdgeLength,t: longestVEdgeLength)
                uv1 = Float2(s: 0,t: longestVEdgeLength)
                uv2 = Float2(s: 0,t: 0)
                uv3 = Float2(s: longestUEdgeLength, t:0)
            case .SizeToWorldUnitsXY:
                // For this uvMode, we allign the texture to the "upper left corner" (v1) and tile
                // it to the "right" and "down" (and "up") based on the coordinate units and the
                // texture/units ratio
                
                let v2v0 = quad.v0 - quad.v2 // v2 to v0 edge
                let v2v1 = quad.v1 - quad.v2 // v2 to v1 edge
                let v2v3 = quad.v3 - quad.v2 // v2 to v3 edge
                
                let v2v0Mag = v2v0.length() // length of v2 to v0 edge
                let v2v1Mag = v2v1.length() // length of v2 to v1 edge
                let v2v3Mag = v2v3.length() // length of v2 to v3 edge
                
                let v0angle = v2v3.angle(v: v2v0) // angle of v2v0 edge against v2v3 edge
                let v1angle = v2v3.angle(v: v2v1) // angle of v2v1 edge against v2v3 edge
                
                // now its just some simple trig - yay!
                uv0 = Float2(s: cos(v0angle) * v2v0Mag, t: sin(v0angle)*v2v0Mag)
                uv1 = Float2(s: cos(v1angle) * v2v1Mag, t: sin(v1angle)*v2v1Mag)
                uv2 = Float2(s: 0,t: 0)
                uv3 = Float2(s: v2v3Mag, t: 0)
                
            case .StretchToFitXY:
                uv0 = Float2(s: 1,t: 1)
                uv1 = Float2(s: 0,t: 1)
                uv2 = Float2(s: 0,t: 0)
                uv3 = Float2(s: 1,t: 0)
            default:
                print("Unknown uv mode \(uvMode)") // no uv mapping for you!
                uv0 = Float2(s: 1,t: 1)
                uv1 = Float2(s: 0,t: 1)
                uv2 = Float2(s: 0,t: 0)
                uv3 = Float2(s: 1,t: 0)
            }
            
            let v0norm = nvf1 + nvf2
            let v2norm = nvf1 + nvf2
            
            let v0 = Vertex(position: Quad.vector3ToFloat3(vector3: quad.v0), normal: Quad.vector3ToFloat3(vector3: v0norm.normalized()), tcoord: uv0)
            let v1 = Vertex(position: Quad.vector3ToFloat3(vector3: quad.v1), normal: Quad.vector3ToFloat3(vector3: nvf1.normalized()), tcoord: uv1)
            let v2 = Vertex(position: Quad.vector3ToFloat3(vector3: quad.v2), normal: Quad.vector3ToFloat3(vector3: v2norm.normalized()), tcoord: uv2)
            let v3 = Vertex(position: Quad.vector3ToFloat3(vector3: quad.v3), normal: Quad.vector3ToFloat3(vector3: nvf2.normalized()), tcoord: uv3)
            
            debugVertex(label: "v0", v: v0)
            debugVertex(label: "v1", v: v1)
            debugVertex(label: "v2", v: v2)
            debugVertex(label: "v3", v: v3)
            
            verts.append(v0)
            verts.append(v1)
            verts.append(v2)
            verts.append(v3)
            
            // add face 1
            faceIndices.append(CInt(verts.count-4)) // v0
            faceIndices.append(CInt(verts.count-3)) // v1
            faceIndices.append(CInt(verts.count-2)) // v2
            
            // add face 2
            faceIndices.append(CInt(verts.count-4)) // v0
            faceIndices.append(CInt(verts.count-2)) // v2
            faceIndices.append(CInt(verts.count-1)) // v3
        }
        
        // Define our sources
        
        let data = NSData(bytes: verts, length: verts.count * MemoryLayout<Vertex>.size)
        let vertexSource = SCNGeometrySource(
            data: data as Data,
            semantic: SCNGeometrySource.Semantic.vertex,
            vectorCount: verts.count,
            usesFloatComponents: true,
            componentsPerVector: 3,
            bytesPerComponent: MemoryLayout<GLfloat>.size,
            dataOffset: 0, // position is first member in Vertex
            dataStride:  MemoryLayout<Vertex>.size)
        
        let normalSource = SCNGeometrySource(
            data: data as Data,
            semantic: SCNGeometrySource.Semantic.normal,
            vectorCount: verts.count,
            usesFloatComponents: true,
            componentsPerVector: 3,
            bytesPerComponent: MemoryLayout<GLfloat>.size,
            dataOffset: MemoryLayout<Float3>.size, // one Float3 before normal in Vertex
            dataStride: MemoryLayout<Vertex>.size)
        
        let tcoordSource = SCNGeometrySource(
            data: data as Data,
            semantic: SCNGeometrySource.Semantic.texcoord,
            vectorCount: verts.count,
            usesFloatComponents: true,
            componentsPerVector: 2,
            bytesPerComponent: MemoryLayout<GLfloat>.size,
            dataOffset: 2 * MemoryLayout<Float3>.size, // 2 Float3s before tcoord in Vertex
            dataStride: MemoryLayout<Vertex>.size)
        
        // Define elements Data
        let indexData = NSData(bytes: faceIndices, length: MemoryLayout<CInt>.size * faceIndices.count)
        let element = SCNGeometryElement(data: indexData as Data, primitiveType: .triangles, primitiveCount: faceIndices.count / 3, bytesPerIndex: MemoryLayout<CInt>.size)
        
        let geometry = SCNGeometry(sources: [vertexSource, normalSource, tcoordSource], elements: [element])
        geometry.firstMaterial?.diffuse.contents = UIColor.black.withAlphaComponent(0.8)
        
//        geometry.firstMaterial?.diffuse.contents = UIColor(red: CGFloat(drand48()), green: CGFloat(drand48()), blue: CGFloat(drand48()), alpha: 0.95)
        return geometry
    }
}


//
//  SceneObjects.swift
//  ARAssignmentApp
//
//  Created by Anand Koti on 07/12/21.
//

import Foundation
import UIKit
import ARKit
import SceneKit


class SceneObjects{
    
    
    let sceneObjectOffset = SCNVector3(0, 0, 0)
    var objectArray = [SCNNode]()
    
    func drawSphericalObject() -> SCNNode{
        let scene = SCNScene()
        let sphere = SCNNode(geometry: SCNSphere(radius: 0.05))
        let rectangle = SCNNode(geometry: SCNBox(width: 0.1, height: 0.1, length: 0.2, chamferRadius: 0))
        objectArray.append(sphere)
        objectArray.append(rectangle)
       
        return sphere
    }
    
}



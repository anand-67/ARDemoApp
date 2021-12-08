//
//  ViewController.swift
//  ARAssignmentApp
//
//  Created by Anand Koti on 07/12/21.
//

import UIKit
import SceneKit
import ARKit


enum AppState: Int16 {
  case lookingForSurface  // Just starting out; no surfaces detected yet
  case pointToSurface     // Surfaces detected, but device is not pointing to any of them
  case readyToFurnish     // Surfaces detected *and* device is pointing to at least one
}

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var lblStatus: UILabel!
    
    var rectangularCube : SCNNode?
    var sphereObject : SCNNode?
    var gridNode : SCNNode?
    var sceneObjects : SceneObjects!
    var statusMessage = ""
    var trackingStatus = ""
    var appState: AppState = .lookingForSurface

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
        
        self.initARSession()
        self.initSceneView()
        self.initGestureRecognizers()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    
    override func didReceiveMemoryWarning() {
      super.didReceiveMemoryWarning()
    }
    
    
    func initSceneView() {
      sceneView.delegate = self
      sceneView.automaticallyUpdatesLighting = true
      sceneView.showsStatistics = true
      sceneView.preferredFramesPerSecond = 60
      sceneView.antialiasingMode = .multisampling2X
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints , ARSCNDebugOptions.showWorldOrigin]
    }
    
    
  
    func createARConfiguration() -> ARConfiguration {
      let config = ARWorldTrackingConfiguration()
      config.worldAlignment = .gravity
      config.planeDetection = [.horizontal]
      config.isLightEstimationEnabled = true
      return config
    }
    
    
  
    func initARSession() {
      guard ARWorldTrackingConfiguration.isSupported else {
        print("********** AR session not supported **********")
        return
      }

      let config = createARConfiguration()
      sceneView.session.run(config)
    }
    
    
    func resetARsession() {
        let config = createARConfiguration()
        sceneView.session.run(config,
                              options: [.resetTracking,
                                        .removeExistingAnchors])
        appState = .lookingForSurface
    }
    
    
    func updateStatusText() {
      switch appState {
      case .lookingForSurface:
        statusMessage = "Scan the room"
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
      case .pointToSurface:
        statusMessage = "Point your device towards surfaces."
        sceneView.debugOptions = []
      case .readyToFurnish:
        statusMessage = "Tap on the floor grid to place object."
        sceneView.debugOptions = []
      }

      lblStatus.text = trackingStatus != "" ? "\(trackingStatus)" : "\(statusMessage)"
    }
    
    
    func updateAppState() {
      guard appState == .pointToSurface ||
        appState == .readyToFurnish
        else {
          return
      }

      if isAnyPlaneInView() {
        appState = .readyToFurnish
      } else {
        appState = .pointToSurface
      }
    }
    
    

    func isAnyPlaneInView() -> Bool {
      let screenDivisions = 5 - 1
      let viewWidth = view.bounds.size.width
      let viewHeight = view.bounds.size.height

      for y in 0...screenDivisions {
        let yCoord = CGFloat(y) / CGFloat(screenDivisions) * viewHeight
        for x in 0...screenDivisions {
          let xCoord = CGFloat(x) / CGFloat(screenDivisions) * viewWidth
          let point = CGPoint(x: xCoord, y: yCoord)

          // Perform hit test for planes.
            if #available(iOS 13.0, *) {
              let hitTest = sceneView.raycastQuery(from: point, allowing: .estimatedPlane, alignment: .horizontal)
                if hitTest != nil{
                    return true
                }
            } else {
                let hitTest = sceneView.hitTest(point, types: .estimatedHorizontalPlane)
                if !hitTest.isEmpty{
                  return true
                }
            }
        

        }
      }
      return false
    }
    

    
    func addObjectsToScene(hitTestResults : ARHitTestResult){
        self.drawObjectsInPlane()
        
    }
    
    
    
    func drawObjectsInPlane(){
        let sphere = SCNNode(geometry: SCNSphere(radius: 0.07))
        sphere.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "earth")
        sphere.geometry?.firstMaterial?.specular.contents = UIColor.yellow
        self.gridNode?.addChildNode(sphere)
        self.sphereObject = sphere
        
        let rectanglularCube = SCNNode(geometry: SCNBox(width: 0.07, height: 0.07, length: 0.07, chamferRadius: 0))
        rectanglularCube.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        rectanglularCube.geometry?.firstMaterial?.specular.contents = UIColor.white
        rectanglularCube.position = SCNVector3(0.15, 0, 0)
        self.gridNode?.addChildNode(rectanglularCube)
        self.rectangularCube = rectanglularCube
    }
    
    
    
    func initGestureRecognizers() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleScreenTap))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
    }

    @objc func handleScreenTap(sender: UITapGestureRecognizer) {
        let tapHandler = sender.view as! ARSCNView
        let tappedLocation = sender.location(in: tapHandler)
        let planeIntersection = tapHandler.hitTest(tappedLocation, types: [.estimatedHorizontalPlane])
        if !planeIntersection.isEmpty{
            addObjectsToScene(hitTestResults: planeIntersection.first!)
        }
    }
    
    
    func drawPlaneNode(on node: SCNNode, for planeAnchor: ARPlaneAnchor) {
        let plane = SCNNode(geometry: SCNPlane(width: CGFloat(planeAnchor.extent.x) , height:  CGFloat(planeAnchor.extent.z)))
        plane.position = SCNVector3(planeAnchor.center.x, planeAnchor.center.y, planeAnchor.center.z)
        plane.geometry?.firstMaterial?.isDoubleSided = true
        plane.eulerAngles = SCNVector3(-Double.pi / 2, 0, 0)
        if planeAnchor.alignment == .horizontal{
            plane.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "grid")
            plane.name = "horizontal"
        }else{
            plane.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "grid")
            plane.name = "vertical"
        }
        node.addChildNode(plane)
        self.gridNode = plane
        appState = .readyToFurnish
    }
    
    
    @IBAction func btnBounceAction(_ sender: UIButton) {
//        sphereObject?.physicsBody? = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: self.sphereObject!, options: nil))
//        sphereObject?.physicsBody?.applyForce(SCNVector3(0, 4, 0), asImpulse: true)
//        sphereObject?.physicsBody?.isAffectedByGravity = true
//        sphereObject?.physicsBody?.restitution = 1
        
    }
    
    @IBAction func btnRotateXAction(_ sender: UIButton) {
        let rotateByXAxis = SCNAction.rotate(by: 180.convertDegreesToRadians(), around: SCNVector3(1, 0, 0), duration: 3)
        self.sphereObject?.runAction(rotateByXAxis)
    }
    
    @IBAction func btnRotateYAction(_ sender: UIButton) {
            let rotateByYAxis = SCNAction.rotate(by: 180.convertDegreesToRadians(), around: SCNVector3(0, 1, 0), duration: 3)
        self.sphereObject?.runAction(rotateByYAxis)
    }
    
    @IBAction func btnRotateZAction(_ sender: UIButton) {
        let rotateByZAxis = SCNAction.rotate(by: 180.convertDegreesToRadians(), around: SCNVector3(0, 0, 1), duration: 3)
        self.sphereObject?.runAction(rotateByZAxis)
    }
    
    
    // MARK: - ARSCNViewDelegate
    func session(_ session: ARSession, didFailWithError error: Error) {
        trackingStatus = "Session Failed \(error)"
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        trackingStatus = "Session interrupted"
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        trackingStatus = "Session interrupted and ended"
        self.resetARsession()
        
    }
    
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        switch camera.trackingState {
        case .notAvailable:
          trackingStatus = "For some reason, augmented reality tracking isn’t available."
        case .normal:
          trackingStatus = ""
        case .limited(let reason):
          switch reason {
          case .excessiveMotion:
            trackingStatus = "You’re moving the device quickly. Slow down."
          case .insufficientFeatures:
            trackingStatus = "I can’t get a sense of the room. Is something blocking the rear camera?"
          case .initializing:
            trackingStatus = "Initializing — please wait a moment..."
          case .relocalizing:
            trackingStatus = "Relocalizing — please wait a moment..."
           default:
              print("Error")
          }
        }
    }
    

    
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            self.updateAppState()
            self.updateStatusText()
        }
    }
    
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }

        node.enumerateChildNodes { (childNode , _) in
          childNode.removeFromParentNode()
        }
        
        drawPlaneNode(on: node, for: planeAnchor)
    }
}


func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
  return SCNVector3(left.x + right.x,
                    left.y + right.y,
                    left.z + right.z)
}


extension Int {
    func convertDegreesToRadians() -> CGFloat{
        return CGFloat(self) * CGFloat.pi / 180.0
    }
}

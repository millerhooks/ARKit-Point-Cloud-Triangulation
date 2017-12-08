//
//  ViewController.swift
//  PointCloudTriangulation
//
//  Created by Eugene Bokhan on 12/8/17.
//  Copyright © 2017 Eugene Bokhan. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController {
    
    // MARK: - UI Elements
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var messagePanel: UIVisualEffectView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var restartExperienceButton: BouncyButton!
    @IBOutlet weak var createCloudButton: BouncyButton!
    
    
    // MARK: - Intarface Actions
    
    @IBAction func restartExperience(_ sender: Any) {
        guard restartExperienceButtonIsEnabled else { return }
        
        DispatchQueue.main.async {
            
            self.restartExperienceButtonIsEnabled = false
            
            self.textManager.cancelAllScheduledMessages()
            self.textManager.dismissPresentedAlert()
            self.textManager.showMessage("Starting a new session")
            
            self.startSession()
        }
    }
    
    @IBAction func createCloudAction(_ sender: Any) {
        
        createCloudButton.isSelected = !createCloudButton.isSelected

        if !createCloudButton.isSelected {
            DispatchQueue.main.async {
                // Clear triagle path view
                self.triangleView.clear()
            }
        }
    }
    
    // MARK: - Properties
    
    var textManager: TextManager!
    var restartExperienceButtonIsEnabled = true {
        didSet {
            if restartExperienceButtonIsEnabled == true {
                restartExperienceButton.setImage(#imageLiteral(resourceName: "restart"), for: [])
                restartExperienceButton.show()
                createCloudButton.show()
                showHitTestVisualization = false
            } else {
                restartExperienceButton.setImage(#imageLiteral(resourceName: "restartPressed"), for: [])
                restartExperienceButton.hide()
                createCloudButton.isSelected = false
                createCloudButton.hide()
            }
        }
    }
    let geoBuilder = GeometryBuilder(uvMode: GeometryBuilder.UVModeType.StretchToFitXY)
    private lazy var triangleView: TriangleView = {
        TriangleView(frame: view.bounds)
    }()
    
    // MARK: - ARKit Properties
    
    let session = ARSession()
    var sessionConfig: ARConfiguration = ARWorldTrackingConfiguration()
    
    var screenCenter: CGPoint?
    // Config properties
    let standardConfiguration: ARWorldTrackingConfiguration = {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        return configuration
    }()
    var dragOnInfinitePlanesEnabled = false
    
    // MARK: - Hit Test Visualization
    
    var showHitTestVisualization = true
    
    // MARK: - Queues
    
    static let serialQueue = DispatchQueue(label: "com.eugenebokhan.example.serialSceneKitQueue")
    // Create instance variable for more readable access inside class
    let serialQueue: DispatchQueue = ViewController.serialQueue
    
    // MARK: - ScanViewController Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupARKitScene()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        session.pause()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Prevent the screen from being dimmed after a while.
        UIApplication.shared.isIdleTimerDisabled = true
        
        // Start the ARSession.
        startSession()
    }
    
    // MARK: - Setup UI
    
    func setupUI() {
        
        textManager = TextManager(viewController: self)
        
        // Set appearance of message output panel
        messagePanel.layer.cornerRadius = 5.0
        messagePanel.clipsToBounds = true
        messagePanel.isHidden = true
        messageLabel.text = ""
        
        // Setup buttons
        setupButtons()
        
        sceneView.addSubview(triangleView)
    }
    
    // MARK: - Setup ARKit Scene
    
    func setupARKitScene() {
        sceneView.delegate = self
        //        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, SCNDebugOptions.showBoundingBoxes]
        sceneView.autoenablesDefaultLighting = true
        sceneView.session = session
        sceneView.antialiasingMode = .multisampling4X
        sceneView.automaticallyUpdatesLighting = false
        
        sceneView.preferredFramesPerSecond = 60
        sceneView.contentScaleFactor = 1
        
        if let camera = sceneView.pointOfView?.camera {
            camera.wantsHDR = true
            camera.wantsExposureAdaptation = true
        }
    }
    
    // MARK: - Setup Buttons
    
    func setupButtons() {
        restartExperienceButton.presentationType = .right
        createCloudButton.presentationType = .right
    }
    
    // MARK: - Create geometry
    
    func createGeometries() {
        
        let vertexArray = createVertexArray()
        
//        DispatchQueue.main.async {
//            self.addTriangleChildNodes(vertexArray)
//        }

        triangleView.recalculate(vertexes: vertexArray)
    }
    
    // MARK: - Help methods
    
    func createVertexArray() -> [Vertex] {
        
        var vertexArray: [Vertex] = [] {
            didSet {
                if vertexArray.count > 68 {
                    vertexArray.remove(at: 0)
                }
            }
        }
        
        if let features = self.session.currentFrame?.rawFeaturePoints {
            let points = features.__points
            for i in 0...features.__count {
                
                let feature = points.advanced(by: Int(i))
                let featurePos = SCNVector3(feature.pointee)
                let projectedPoint = self.sceneView.projectPoint(featurePos)
                let screenPoint = CGPoint(x: projectedPoint.x, y: projectedPoint.y)
                
                if fitsScreenPartRect(point: screenPoint, screenPart: 1.0) {
                    vertexArray.append( Vertex(point: screenPoint, scnVector: featurePos, id: i) )
                }
            }
        }
        
        return vertexArray
    }
    
    func addTriangleChildNodes(_ vertexArray: [Vertex]) {
        
        let triangles = Delaunay().triangulate(vertexArray)
        
        for triange in triangles {
            
            if !checkForGeoIntersection(triange: triange) && checkCatenary(triange: triange, minLength: 0.1) {
                if let quadNode = createQuadNode(triange: triange) {
                    self.sceneView.scene.rootNode.addChildNode(quadNode)
                }
            }
        }
    }
    
    func checkCatenary(triange: Triangle, minLength: CGFloat) -> Bool {
        
        var maxCatenary: Float = 0
        
        if let v0 = triange.vertex1.scnVector, let v1 = triange.vertex2.scnVector, let v2 = triange.vertex3.scnVector {
            let firstCatenary = (v0 - v1).length()
            let secondCatenary = (v0 - v2).length()
            let thirdCatenary = (v1 - v2).length()
            maxCatenary = max(max(firstCatenary, secondCatenary), thirdCatenary)
        }
        
        return maxCatenary < 0.1
    }
    
    func checkForGeoIntersection(triange: Triangle) -> Bool {
        
        var intersects: Bool
        
        if checkPointForIntersection((triange.vertex1.point + triange.vertex2.point + triange.vertex3.point) / 3) {
            intersects = true
        } else {
            intersects = false
        }
        
        return intersects
    }
    
    func checkPointForIntersection(_ screenPoint: CGPoint) -> Bool {
        
        var intersectsGeometry = false
        if let result = self.sceneView.hitTest(screenPoint, options: nil).first {
            if let nodeName = result.node.name {
                if nodeName == "Triangle" {
                    intersectsGeometry = true
                    result.node.removeFromParentNode()
                }
            }
        }
        
        return intersectsGeometry
    }
    
    func fitsScreenPartRect(point: CGPoint, screenPart: CGFloat) -> Bool {
        
        let bounds = self.sceneView.bounds
        let minX = (bounds.width - (bounds.width * screenPart)) / 2
        let minY = (bounds.height - (bounds.height * screenPart)) / 2
        let maxX = (bounds.width * screenPart) + minX
        let maxY = (bounds.height * screenPart) + minY
        
        return point.x > minX && point.x < maxX && point.y > minY && point.y < maxY
    }
    
    func createQuadNode(triange: Triangle) -> QuadNode? {
        var quadNode: QuadNode?
        if let v0 = triange.vertex1.scnVector, let v1 = triange.vertex2.scnVector, let v2 = triange.vertex3.scnVector {
            let quad = Quad(v0: v0, v1: v1, v2: v2, v3: v1)
            self.geoBuilder.addQuad(quad: quad)
            let geometry = self.geoBuilder.getGeometry()
            quadNode = QuadNode(v0: v0, v1: v1, v2: v2, v3: v1)
            quadNode?.geometry = geometry
            quadNode?.name = "Triangle"
        }
        return quadNode
    }
    
    // MARK: - Error handling
    
    func displayErrorMessage(title: String, message: String, allowRestart: Bool = false) {
        // Blur the background.
        textManager.blurBackground()
        
        if allowRestart {
            // Present an alert informing about the error that has occurred.
            let restartAction = UIAlertAction(title: "Reset", style: .default) { _ in
                self.textManager.unblurBackground()
            }
            textManager.showAlert(title: title, message: message, actions: [restartAction])
        } else {
            textManager.showAlert(title: title, message: message, actions: [])
        }
    }
    
}

// MARK: - ARKit / ARSCNView Methods

extension ViewController {
    
    func startSession() {
        if ARWorldTrackingConfiguration.isSupported {
            // Start the ARSession.
            resetTracking()
        } else {
            // This device does not support 6DOF world tracking.
            let sessionErrorMsg = "This app requires world tracking. World tracking is only available on iOS devices with A9 processor or newer. " +
            "Please quit the application."
            displayErrorMessage(title: "Unsupported platform", message: sessionErrorMsg, allowRestart: false)
        }
    }
    
    func resetTracking() {
        session.run(standardConfiguration, options: [.resetTracking, .removeExistingAnchors])
        showHitTestVisualization = true
        // Disable Restart button for a while in order to give the session enough time to restart.
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0, execute: {
            self.restartExperienceButtonIsEnabled = true
        })
    }
    
    func enableEnvironmentMapWithIntensity(_ intensity: CGFloat) {
        sceneView.scene.lightingEnvironment.intensity = intensity
    }
    
}

// MARK: - ARSCNViewDelegate

extension ViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
        DispatchQueue.main.async() {
            // If light estimation is enabled, update the intensity of the model's lights and the environment map
            if let lightEstimate = self.session.currentFrame?.lightEstimate {
                self.sceneView.scene.enableEnvironmentMapWithIntensity(lightEstimate.ambientIntensity / 40, queue: self.serialQueue)
            } else {
                self.sceneView.scene.enableEnvironmentMapWithIntensity(40, queue: self.serialQueue)
            }
        }
        
        DispatchQueue.main.async {
            if self.createCloudButton.isSelected {
                self.createGeometries()
            }
        }
        
    }
}

// MARK: - ARSessionDelegate

extension ViewController: ARSessionDelegate {
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        
        textManager.showTrackingQualityInfo(for: camera.trackingState, autoHide: true)
        
        switch camera.trackingState {
        case .notAvailable:
            resetTracking()
        case .limited:
            break
        //            textManager.escalateFeedback(for: camera.trackingState, inSeconds: 3.0)
        case .normal:
            textManager.cancelScheduledMessage(forType: .trackingStateEscalation)
        }
        
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Do something with the new transform
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        
        guard let arError = error as? ARError else { return }
        
        let nsError = error as NSError
        var sessionErrorMsg = "\(nsError.localizedDescription) \(nsError.localizedFailureReason ?? "")"
        if let recoveryOptions = nsError.localizedRecoveryOptions {
            for option in recoveryOptions {
                sessionErrorMsg.append("\(option).")
            }
        }
        
        let isRecoverable = (arError.code == .worldTrackingFailed)
        if isRecoverable {
            sessionErrorMsg += "\nYou can try resetting the session or quit the application."
        } else {
            sessionErrorMsg += "\nThis is an unrecoverable error that requires to quit the application."
        }
        
        displayErrorMessage(title: "We're sorry!", message: sessionErrorMsg, allowRestart: isRecoverable)
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        textManager.blurBackground()
        textManager.showAlert(title: "Session Interrupted", message: "The session will be reset after the interruption has ended.")
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        textManager.unblurBackground()
        session.run(standardConfiguration, options: [.resetTracking, .removeExistingAnchors])
        textManager.showMessage("RESETTING SESSION")
    }
}

//
//  ViewController.swift
//  arkitByExample001
//
//  Created by David on 8/16/17.
//  Copyright © 2017 Vision Runner. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    var planes = [Plane]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        //COMMENTED OUT AS IT IS BOILERPLATE CODE
        //        // Create a new scene
        //        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        //
        //        // Set the scene to the view
        //        sceneView.scene = scene
        
        //PART 1:
        //source: https://blog.markdaws.net/arkit-by-example-part1-7830677ef84d

//        1. create the new scene
        let scene = SCNScene.init()
        
        
        
        
      // commented out to remove initial added cube
        
        
        
        
////        2. create geometry
        let boxGeometry = SCNBox.init(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0.0)

//        3. Wrap the geometry in a node
        let boxNode = SCNNode.init(geometry: boxGeometry)

//        4. position the node
        boxNode.position = SCNVector3.init(0, 0, -0.5)

//        5. add node to scene
        scene.rootNode.addChildNode(boxNode)
        
//        6. set the scene to the view
        self.sceneView.scene = scene
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
//        7. add default lighting
//        self.sceneView.autoenablesDefaultLighting = true
        self.sceneView.autoenablesDefaultLighting = false
        
        self.sceneView.automaticallyUpdatesLighting = true

        
        // PART 2: Detecting plane geometry
        
//        8. add debug visualizagtions
        //TODO: Test that these are both working
        self.sceneView.debugOptions = ARSCNDebugOptions.showWorldOrigin
        self.sceneView.debugOptions = ARSCNDebugOptions.showFeaturePoints
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingSessionConfiguration()
        
//        9. add plane detection property to session configuration object
        configuration.planeDetection = ARWorldTrackingSessionConfiguration.PlaneDetection.horizontal
        
        // Run the view's session
        sceneView.session.run(configuration)
        
    }
    
    // 10. Add in delegate method to respond to plane detection
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        let planeNode = Plane(anchor: planeAnchor)
        planes.append(planeNode)

        // Add physics to the plane node
        planeNode.physicsBody = SCNPhysicsBody.init(type: SCNPhysicsBodyType.kinematic, shape: nil)
        
        if let planeNodePhysicsBody = planeNode.physicsBody {
            planeNodePhysicsBody.mass = 2.0
        }



        node.addChildNode(planeNode)
    }
    
//    12. update the Plane SceneKit is already rendering.
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let overlayPlane = planes.first(where: {$0.anchor.identifier == anchor.identifier}),
            let anchor = anchor as? ARPlaneAnchor
            else { return }
        overlayPlane.update(anchor: anchor)
    }

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // update the lighting in the scene
        
        var estimate = ARLightEstimate.init()
        if let currentFrameWithLighting = self.sceneView.session.currentFrame {
            if let currentFrameWithLightingEstimate = currentFrameWithLighting.lightEstimate {
                estimate = currentFrameWithLightingEstimate
            }
        }

        // TODO: Put this on the screen
        print("light estimate: %f", estimate.ambientIntensity);
        
        
        
    }
    
    // Part 3: Hit detection
    // source: Took this code from Jared Davidson's tutorial on ARKit
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let result = sceneView.hitTest(touch.location(in: sceneView), types: [ARHitTestResult.ResultType.featurePoint])
        
        // grab the last hit result , should be most accurate
        guard let hitResult = result.last else { return }
        
        // tranform that transform into a scene vector3
        let hitTransform = SCNMatrix4(hitResult.worldTransform)
        
        // get the xyz out of our matrix float
        let hitVector = SCNVector3Make(hitTransform.m41, hitTransform.m42, hitTransform.m43)
        
        insertGeometry(position: hitVector)
    }
    
    // Took this code from Jared Davidson's code to place geometry in space
    func insertGeometry(position: SCNVector3) {
        
        // create shape
        let cubeShape = SCNBox.init(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0.0)
        
        // create node from shape
        let shapeNode = SCNNode(geometry: cubeShape)

        // create material to assign images to aspects of box skin
        let materials = shapeNode.geometry?.materials as! [SCNMaterial]
        let material = materials[0]
        material.lightingModel = SCNMaterial.LightingModel.physicallyBased
        material.diffuse.contents = UIImage.init(named:"limestone-albdo")
        material.roughness.contents = UIImage.init(named:"limestone-roughness")
        material.metalness.contents = UIImage.init(named:"limestone-metal")
        material.normal.contents = UIImage.init(named:"limestone-normal")
        

        // Add physics to the node
        // The physicsBody tells SceneKit this geometry should be
        // manipulated by the physics engine
        shapeNode.physicsBody = SCNPhysicsBody.init(type: SCNPhysicsBodyType.dynamic, shape: nil)
        
        if let shapeNodePhysicsBody = shapeNode.physicsBody {
            shapeNodePhysicsBody.mass = 1.0
        }

        // position shapeNode with input position
        shapeNode.position = position
        
        // We insert the geometry slightly above the point the user tapped
        // so that it drops onto the plane using the physics engine
        
        let insertionYOffset: Float = 0.5
        shapeNode.position.y = position.y + insertionYOffset
        
        // add ballNode to root node
        sceneView.scene.rootNode.addChildNode(shapeNode)
    }

    // PART 4:
    
    // add a light
    
    func addLighting(position: SCNVector3) {
        
        let spotLight = SCNLight.init()
        spotLight.type = SCNLight.LightType.spot
        spotLight.spotInnerAngle = 45
        spotLight.spotOuterAngle = 45
        
        let spotNode = SCNNode.init()
        spotNode.light = spotLight
        spotNode.position = position
        
        // By default the stop light points directly down the negative
        // z-axis, we want to shine it down so rotate 90deg around the
        // x-axis to point it down
        spotNode.eulerAngles = SCNVector3Make(-Float.pi / 2, 0, 0);
        self.sceneView.scene.rootNode.addChildNode(spotNode)
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}

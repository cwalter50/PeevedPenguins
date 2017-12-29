//
//  GameScene.swift
//  PeevedPenguins
//
//  Created by Christopher Walter on 12/28/17.
//  Copyright © 2017 AssistStat. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
    
    /* Game object connections */
    var catapultArm: SKSpriteNode!
    var levelHolder: SKNode!
    
    /* UI Connections */
    var buttonRestart: MSButtonNode!
    
    /* Tracking helpers */
    var trackerNode: SKNode? {
        didSet {
            if let trackerNode = trackerNode {
                /* Set tracker */
                lastTrackerPosition = trackerNode.position
            }
        }
    }
    var lastTrackerPosition = CGPoint(x: 0, y: 0)
    var lastTimeInterval:TimeInterval = 0
    
    override func didMove(to view: SKView) {
        /* Set reference to catapultArm SKSpriteNode */
        catapultArm = childNode(withName: "catapultArm") as! SKSpriteNode
        levelHolder = childNode(withName: "levelHolder")
        
        /* Set reference to buttonRestart SKSpriteNode */
        buttonRestart = childNode(withName: "//buttonRestart") as! MSButtonNode
        
        /* Setup button selection handler */
        buttonRestart.selectedHandler = { [unowned self] in
            
            if let view = self.view {
                
                // Load the SKScene from 'GameScene.sks'
                if let scene = SKScene(fileNamed: "GameScene") {
                    
                    // Set the scale mode to scale to fit the window
                    scene.scaleMode = .aspectFill
                    
                    // Present the scene
                    view.presentScene(scene)
                }
                
                // Debug helpers
                view.showsFPS = true
                view.showsPhysics = true
                view.showsDrawCount = true
            }
        }
        
        /* Load Level 1 */
        let resourcePath = Bundle.main.path(forResource: "Level1", ofType: "sks")
        let level = SKReferenceNode (url: URL (fileURLWithPath: resourcePath!))
        levelHolder.addChild(level)
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        /* Add a new penguin to the scene */
        let penguin = MSReferenceNode(fileNamed: "Penguin")
        addChild(penguin)
        
        /* Move penguin to the catapult bucket area */
        penguin.avatar.position = catapultArm.position + CGPoint(x: 32, y: 50)
        
        /* Impulse vector */
        let launchDirection = CGVector(dx: 1, dy: 0)
        let force = launchDirection * 300
        
        /* Apply impulse to penguin */
        penguin.avatar.physicsBody?.applyImpulse(force)
        
        /* Set tracker to follow penguin */
        trackerNode = penguin.avatar
    }
    
    override func update(_ currentTime: TimeInterval) {
        
        /* Check there is a node to track and camera is present */
        if let trackerNode = trackerNode, let camera = camera {
            
            /* Calculate horizontal distance to move */
            let moveDistance = trackerNode.position.x - lastTrackerPosition.x
            
            /* Duration is time between updates */
            let moveDuration = currentTime - lastTimeInterval
            
            /* Create a move action for the camera */
            let moveCamera = SKAction.moveBy(x: moveDistance, y: 0, duration: moveDuration)
            camera.run(moveCamera)
            
            /* Store last tracker position */
            lastTrackerPosition = trackerNode.position
        }
        
        /* Store current update step time */
        lastTimeInterval = currentTime
        
    }
}

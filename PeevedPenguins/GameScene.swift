//
//  GameScene.swift
//  PeevedPenguins
//
//  Created by Christopher Walter on 12/28/17.
//  Copyright © 2017 AssistStat. All rights reserved.
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    /* Game object connections */
    var catapultArm: SKSpriteNode!
    var catapult: SKSpriteNode!
    var levelHolder: SKNode!
    var cantileverNode: SKSpriteNode!
    var touchNode: SKSpriteNode!
    
    /* UI Connections */
    var buttonRestart: MSButtonNode!
    
    /* Physics helpers */
    var touchJoint: SKPhysicsJointSpring?
    var penguinJoint: SKPhysicsJointPin?
    
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
        catapult = childNode(withName: "catapult") as! SKSpriteNode
        cantileverNode = childNode(withName: "cantileverNode") as! SKSpriteNode
        touchNode = childNode(withName: "touchNode") as! SKSpriteNode
        levelHolder = childNode(withName: "levelHolder")
        
        /* Set reference to buttonRestart SKSpriteNode */
        buttonRestart = childNode(withName: "//buttonRestart") as! MSButtonNode
        
        /* Setup button selection handler */
        buttonRestart.selectedHandler = { [unowned self] in
            
            if let view = self.view {
                
                // Load the SKScene from 'GameScene.sks'
                if let scene = SKScene(fileNamed: "GameScene") {
                    
                    // Set the scale mode to scale to fit the window
                    scene.scaleMode = .aspectFit
                    
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
        
        /* Initialize catapult arm physics body of type alpha */
        let catapultArmBody = SKPhysicsBody (texture: catapultArm!.texture!, size: catapultArm.size)
        
        /* Mass needs to be heavy enough to hit the penguin with sufficient force */
        catapultArmBody.mass = 0.5
        
        /* No need for gravity otherwise the arm will fall over */
        catapultArmBody.affectedByGravity = false
        
        /* Improves physics collision handling of fast moving objects */
        catapultArmBody.usesPreciseCollisionDetection = true
        
        /* Assign the physics body to the catapult arm */
        catapultArm.physicsBody = catapultArmBody
        
        /* Pin joint catapult and catapult arm */
        let catapultPinJoint = SKPhysicsJointPin.joint(withBodyA: catapult.physicsBody!, bodyB: catapultArm.physicsBody!, anchor: CGPoint(x: -93, y: -45))
        physicsWorld.add(catapultPinJoint)
        
        /* Spring joint catapult arm and cantilever node */
        let catapultSpringJoint = SKPhysicsJointSpring.joint(withBodyA: catapultArm.physicsBody!, bodyB: cantileverNode.physicsBody!, anchorA: catapultArm.position + CGPoint(x:15, y:30), anchorB: cantileverNode.position)
        physicsWorld.add(catapultSpringJoint)
        
        /* Make this joint a bit more springy */
        catapultSpringJoint.frequency = 1.5
        
        /* Set physics contact delegate */
        physicsWorld.contactDelegate = self
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        /* Physics contact delegate implementation */
        
        /* Get references to the bodies involved in the collision */
        let contactA:SKPhysicsBody = contact.bodyA
        let contactB:SKPhysicsBody = contact.bodyB
        
        /* Get references to the physics body parent SKSpriteNode */
        let nodeA = contactA.node as! SKSpriteNode
        let nodeB = contactB.node as! SKSpriteNode
        
        /* Was a seal involved? */
        if contactA.categoryBitMask == 2 || contactB.categoryBitMask == 2 {
//            print("SealHit: \(contact.collisionImpulse)")
            
            /* Was it more than a gentle nudge? */
            if contact.collisionImpulse > 2.0 {
//                print("seal should be removed: \(contact.collisionImpulse)")
                /* Kill Seal(s) */
                if contactA.categoryBitMask == 2 {
                    dieSeal(nodeA)
                }
                if contactB.categoryBitMask == 2 {
                    dieSeal(nodeB)
                }
            }
        }
    }
    
    func dieSeal(_ node: SKNode) {
        /* Seal death*/
        
        /* Play SFX */
        let sealSFX = SKAction.playSoundFileNamed("sfx_seal", waitForCompletion: false)
        self.run(sealSFX)
        
        /* Load our particle effect */
        let particles = SKEmitterNode(fileNamed: "SealExplosion")!
        
        /* Convert node location (currently inside LevelHolder, to scene space) */
        particles.position = convert(node.position, from: node)
        
        /* Restrict total particles to reduce runtime of particle */
        particles.numParticlesToEmit = 25
        
        /* Add particles to scene */
        addChild(particles)

        
        /* Create our seal removal action */
//        node.removeFromParent()
        node.run(SKAction.removeFromParent())
//        let sealDeath = SKAction.removeFromParent()
//        node.run(sealDeath)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        /* There will only be one touch as multi touch is not enabled by default */
        for touch in touches {
            
            /* Grab scene position of touch */
            let location = touch.location(in: self)
            
            /* Get node reference if we're touching a node */
            let touchedNode = atPoint(location)
            
            /* Is it the catapult arm? */
            if touchedNode.name == "catapultArm" {
                
                /* Reset touch node position */
                touchNode.position = location
                
                /* Spring joint touch node and catapult arm */
                touchJoint = SKPhysicsJointSpring.joint(withBodyA: touchNode.physicsBody!, bodyB: catapultArm.physicsBody!, anchorA: location, anchorB: location)
                physicsWorld.add(touchJoint!)
                

                /* Add a new penguin to the scene */
                let penguin = MSReferenceNode(fileNamed: "Penguin")
                addChild(penguin)
                
                /* Position penguin in the catapult bucket area */
                penguin.avatar.position = catapultArm.position + CGPoint(x: 32, y: 50)
                
                /* Improves physics collision handling of fast moving objects */
                penguin.avatar.physicsBody?.usesPreciseCollisionDetection = true
                
                /* Setup pin joint between penguin and catapult arm */
                penguinJoint = SKPhysicsJointPin.joint(withBodyA: catapultArm.physicsBody!, bodyB: penguin.avatar.physicsBody!, anchor: penguin.avatar.position)
                physicsWorld.add(penguinJoint!)
                
                /* Set camera to follow penguin */
                trackerNode = penguin.avatar
                
            }
        }
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        /* Called when a touch moved */
        
        /* There will only be one touch as multi touch is not enabled by default */
        for touch in touches {
            
            /* Grab scene position of touch and update touchNode position */
            let location = touch.location(in: self)
            touchNode.position = location
            
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        /* Called when a touch ended */
        
        /* Let it fly!, remove joints used in catapult launch */
        if let touchJoint = touchJoint {
            physicsWorld.remove(touchJoint)
        }
        
        if let penguinJoint = penguinJoint {
            physicsWorld.remove(penguinJoint)
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        
        /* Check there is a node to track and camera is present */
        if let trackerNode = trackerNode, let camera = camera {
            
            /* Calculate horizontal distance to move */
            let moveDistance = trackerNode.position.x - lastTrackerPosition.x
            
            /* Duration is time between updates */
            let moveDuration = currentTime - lastTimeInterval
            
//            /* Create a move action for the camera */
//            let moveCamera = SKAction.moveBy(x: moveDistance, y: 0, duration: moveDuration)
//            camera.run(moveCamera)
            
            /* Create a move action for the camera */
            if camera.position.x + moveDistance >= 0 && camera.position.x + moveDistance <= 392 {
                let moveCamera = SKAction.moveBy(x: moveDistance, y: 0, duration: moveDuration)
                camera.run(moveCamera)
            }
            
            /* Store last tracker position */
            lastTrackerPosition = trackerNode.position
            
            /* Has penguin come to a near stand still */
            let idleVelocity:CGFloat = 0.15
            
            /* Is the penguin currently joined to the catapult */
            let nodeJoints = trackerNode.physicsBody?.joints.count
            
            if trackerNode.physicsBody!.velocity.length() < idleVelocity &&
                nodeJoints == 0 {
                
                /* Reset tracker node */
                self.trackerNode = nil
                
                /* Move camera back to start position */
                camera.run(SKAction.moveTo(x: 0, duration: 1.0))

                
                /* Reset catapult arm */
                catapultArm.physicsBody?.velocity = CGVector(dx:0,dy:0)
                catapultArm.physicsBody?.angularVelocity = 0.0
                catapultArm.zRotation = 0
                catapultArm.position = CGPoint(x:-81,y:31)
                
                /* Remove penguin */
//                let removeNode = SKAction.removeFromParent()
//                trackerNode.run(removeNode)
                trackerNode.run(SKAction.removeFromParent())

            }
        }
        
        /* Store current update step time */
        lastTimeInterval = currentTime
        

        
    }
}

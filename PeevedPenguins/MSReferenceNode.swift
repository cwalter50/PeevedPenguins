//
//  MSPhysicsNode.swift
//  Make School
//
//  Created by Martin Walsh on 15/03/2016.
//  Copyright © 2016 Martin Walsh. All rights reserved.
//

import SpriteKit

class MSReferenceNode: SKReferenceNode {
    
    /* Avatar node connection */
    var avatar: SKSpriteNode!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(fileNamed fileName: String?) {
        super.init(fileNamed: fileName)
    }
    
    override func didLoad(_ node: SKNode?) {
        /* Set reference to avatar node */
        avatar = childNode(withName: "//avatar") as! SKSpriteNode
    }
}

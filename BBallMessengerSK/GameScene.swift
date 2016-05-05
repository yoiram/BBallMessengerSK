//
//  GameScene.swift
//  BBallMessengerSK
//
//  Created by Mario Youssef on 2016-05-04.
//  Copyright (c) 2016 Mario Youssef. All rights reserved.
//

import SpriteKit
import AVFoundation

class GameScene: SKScene,SKPhysicsContactDelegate {
    
    //init constants and variables
    var fingerIsOnBall = false
    var thrown = false
    let ballCategoryName = "ball"
    var backgroundMusicPlayer = AVAudioPlayer()
    let ballCategory:UInt32 = 0x1 << 0              // 000000001
    let bottomCategory:UInt32 = 0x1 << 1            // 000000010
    let rimCategory:UInt32 = 0x1 << 2               // 000000100
    var leftRim = SKSpriteNode()
    var rightRim = SKSpriteNode()
    
    override init(size: CGSize) {
        super.init(size: size)
        
        self.physicsWorld.contactDelegate = self
        
        //init music
        let musicURL = NSBundle.mainBundle().URLForResource("Y'all ready for this", withExtension: "mp3")
        do {
            backgroundMusicPlayer = try AVAudioPlayer(contentsOfURL: musicURL!)
        } catch {
            print("ERROR: Music not found")
        }
        backgroundMusicPlayer.numberOfLoops = -1
        backgroundMusicPlayer.prepareToPlay()
        backgroundMusicPlayer.play()
        
        //init gravity
        self.physicsWorld.gravity = CGVectorMake(0, -9.8)
        
        //to have sides with no borders
//        let topBorder = SKPhysicsBody(edgeFromPoint: CGPointMake(0, self.frame.size.height), toPoint: CGPointMake(self.frame.size.width,self.frame.size.height))
//        let bottomBorder = SKPhysicsBody(edgeFromPoint: CGPointMake(0, 0), toPoint: CGPointMake(self.frame.size.width,0))
//        self.physicsBody = topBorder
//        self.physicsBody = bottomBorder
//        self.physicsBody?.friction = 0
        
        //for border all around frame
        let worldBorder = SKPhysicsBody(edgeLoopFromRect: self.frame)
        self.physicsBody = worldBorder
        self.physicsBody?.friction = 0
        
        //init bottom rectangle for scoring
        let bottomRect = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, 1)
        let bottom = SKNode()
        bottom.physicsBody = SKPhysicsBody(edgeLoopFromRect: bottomRect)
        self.addChild(bottom)
        
        //init rim edges
        let rimL = SKSpriteNode(color: UIColor.redColor(), size: CGSizeMake(10,10))
        let rimR = SKSpriteNode(color: UIColor.redColor(), size: CGSizeMake(10,10))
        rimL.name = "rimL"
        rimR.name = "rimR"
        rimL.position = CGPointMake(self.frame.size.width/2 - 60, self.frame.size.height - 160)
        rimR.position = CGPointMake(self.frame.size.width/2 + 60, self.frame.size.height - 160)
        
        self.addChild(rimL)
        self.addChild(rimR)
        
        rimL.physicsBody = SKPhysicsBody(circleOfRadius: 7)
        rimR.physicsBody = SKPhysicsBody(circleOfRadius: 7)
        rimL.physicsBody?.affectedByGravity = false
        rimR.physicsBody?.affectedByGravity = false
        rimL.physicsBody?.friction = 0.2
        rimL.physicsBody?.allowsRotation = false
        rimR.physicsBody?.friction = 0.2
        rimR.physicsBody?.allowsRotation = false
        rimL.physicsBody?.pinned = true
        rimR.physicsBody?.pinned = true
        
        leftRim = rimL
        rightRim = rimR
        
        //init net
        let net = SKSpriteNode(imageNamed: "basketball_basket-512")
        net.size = CGSizeMake(200.0, 200.0)
        net.name = "net"
        net.position = CGPointMake(self.frame.size.width/2, self.frame.size.height - 150)
        
        self.addChild(net)
        
        //init ball
        let ball = SKSpriteNode(imageNamed: "basketball")
        ball.size = CGSizeMake(95, 75)
        ball.name = ballCategoryName
        ball.position = CGPointMake(self.frame.size.width/2, self.frame.size.height/2)
        
        self.addChild(ball)
        
        ball.physicsBody = SKPhysicsBody(circleOfRadius: 35)
        ball.physicsBody?.friction = 0.2
        ball.physicsBody?.restitution = 0.6
        ball.physicsBody?.linearDamping = 0.1
        ball.physicsBody?.allowsRotation = true
        
        //assign bitmasks
        bottom.physicsBody?.categoryBitMask = bottomCategory
        ball.physicsBody?.categoryBitMask = ballCategory
        rimL.physicsBody?.categoryBitMask = rimCategory
        rimR.physicsBody?.categoryBitMask = rimCategory
        ball.physicsBody?.contactTestBitMask = bottomCategory
        
    }
    
    //initial position of ball
    var firstPos: CGPoint?
    
    //only works if finger starts on ball
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let touch = touches.first
        let touchLocation = touch!.locationInNode(self)
        
        let body:SKPhysicsBody? = self.physicsWorld.bodyAtPoint(touchLocation)
        
        if body?.node?.name == ballCategoryName {
            print("ball touched")
            fingerIsOnBall = true
        }
        firstPos = (self.childNodeWithName(ballCategoryName)?.position)!
//        self.childNodeWithName("rimL")?.removeFromParent() //removes rims from self
//        self.childNodeWithName("rimR")?.removeFromParent()
    }
    
    //will shoot if finger started on ball
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if fingerIsOnBall {
            let touch = touches.first
            let touchLocation = touch?.locationInNode(self)
            let x : CGFloat = touchLocation!.x - firstPos!.x
            let y : CGFloat = touchLocation!.y - firstPos!.y
            let desiredImpulse : CGFloat = 245.0 * 245.0
            let a = ((x*x) + (y*y)) / desiredImpulse //original v^2 over the desired v^2
            let newX = sqrt((x*x)/a)
            let newY = sqrt((y*y)/a)
            let vector = CGVectorMake(newX, newY) //create a vector whos impulse is equal to the root of desiredImpulse
            self.childNodeWithName(ballCategoryName)?.physicsBody?.applyImpulse(vector)
            firstPos = nil
        }
        fingerIsOnBall = false
        thrown = true
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        var firstBody = SKPhysicsBody()
        var secondBody = SKPhysicsBody()
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        if firstBody.categoryBitMask == ballCategory && secondBody.categoryBitMask == bottomCategory {
            if thrown {
                //TODO: if scored, increment score counter and put ball in new position
                //TODO: else reset score and ball
                print("touched 1")
                thrown = false
            } else {
                //TODO: do nothing
                print("touched 2")
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

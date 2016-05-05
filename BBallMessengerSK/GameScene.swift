//
//  GameScene.swift
//  BBallMessengerSK
//
//  Created by Mario Youssef on 2016-05-04.
//  Copyright (c) 2016 Mario Youssef. All rights reserved.
//

import SpriteKit
import AVFoundation

struct scoreKey {
    static let highScore = "highScore"
}

class GameScene: SKScene,SKPhysicsContactDelegate {
    
    //init constants and variables
    var fingerIsOnBall = false
    var thrown = false
    var passedTop = false
    let ballCategoryName = "ball"
    var backgroundMusicPlayer = AVAudioPlayer()
    let ballCategory:UInt32 = 0x1 << 0              // 000000001
    let bottomCategory:UInt32 = 0x1 << 1            // 000000010
    let rimCategory:UInt32 = 0x1 << 2               // 000000100
    let scoreCategory:UInt32 = 0x1 << 3             // 000001000
    let loadRimCategory:UInt32 = 0x1 << 4           // 000010000
    var basketBall = SKSpriteNode()
    var leftRim = SKSpriteNode()
    var rightRim = SKSpriteNode()
    var scoringNode = SKSpriteNode()
    var loadingRimNode = SKSpriteNode()
    var scoreLabel = SKLabelNode()
    var highScoreLabel = SKLabelNode()
    var score = 0
    var scored = false
    let defaults = NSUserDefaults.standardUserDefaults()
    
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
        leftRim = SKSpriteNode(color: UIColor.redColor(), size: CGSizeMake(10,10))
        rightRim = SKSpriteNode(color: UIColor.redColor(), size: CGSizeMake(10,10))
        leftRim.name = "rimL"
        rightRim.name = "rimR"
        leftRim.position = CGPointMake(self.frame.size.width/2 - 60, self.frame.size.height - 160)
        rightRim.position = CGPointMake(self.frame.size.width/2 + 60, self.frame.size.height - 160)
        
        leftRim.physicsBody = SKPhysicsBody(circleOfRadius: 7)
        rightRim.physicsBody = SKPhysicsBody(circleOfRadius: 7)
        leftRim.physicsBody?.affectedByGravity = false
        rightRim.physicsBody?.affectedByGravity = false
        leftRim.physicsBody?.friction = 0.1
        rightRim.physicsBody?.friction = 0.1
        leftRim.physicsBody?.allowsRotation = false
        rightRim.physicsBody?.allowsRotation = false
        leftRim.physicsBody?.dynamic = false
        rightRim.physicsBody?.dynamic = false
        
        //init net
        let net = SKSpriteNode(imageNamed: "basketball_basket-512")
        net.size = CGSizeMake(200.0, 200.0)
        net.name = "net"
        net.position = CGPointMake(self.frame.size.width/2, self.frame.size.height - 150)
        self.addChild(net)
        
        //init scoring node
        scoringNode.size = CGSize(width: 110, height: 1)
        scoringNode.position = CGPoint(x: self.frame.size.width/2, y: self.frame.size.height - 165)
        scoringNode.name = "scoring"
        
        scoringNode.physicsBody = SKPhysicsBody(rectangleOfSize: scoringNode.size)
        scoringNode.physicsBody?.affectedByGravity = false
        scoringNode.physicsBody?.dynamic = false
    
        //init loading node
        loadingRimNode.size = CGSize(width: self.frame.size.width, height: 1)
        loadingRimNode.position = CGPoint(x: self.frame.size.width/2, y: self.frame.size.height - 160)
        loadingRimNode.name = "loading"
        loadingRimNode.hidden = true
        
        loadingRimNode.physicsBody = SKPhysicsBody(rectangleOfSize: loadingRimNode.size)
        loadingRimNode.physicsBody?.affectedByGravity = false
        loadingRimNode.physicsBody?.dynamic = false
        
        self.addChild(loadingRimNode)
        
        //init ball
        basketBall = SKSpriteNode(imageNamed: "basketball")
        basketBall.size = CGSizeMake(95, 75)
        basketBall.name = ballCategoryName
        basketBall.position = CGPointMake(self.frame.size.width/2, basketBall.frame.size.height/2)

        basketBall.physicsBody = SKPhysicsBody(circleOfRadius: 35)
        basketBall.physicsBody?.friction = 0.2
        basketBall.physicsBody?.restitution = 0.6
        basketBall.physicsBody?.linearDamping = 0.1
        basketBall.physicsBody?.allowsRotation = true
        
        self.addChild(basketBall)

        //init scoreLabel
        scoreLabel = SKLabelNode()
        scoreLabel.fontSize = 26
        scoreLabel.position = CGPoint(x: self.frame.size.width/2, y: self.frame.size.height/2)
        scoreLabel.fontColor = UIColor.darkGrayColor()
        scoreLabel.text = "Score: 0"
        
        self.addChild(scoreLabel)
        
        //init highScoreLabel
        highScoreLabel = SKLabelNode()
        highScoreLabel.fontSize = 26
        highScoreLabel.position = CGPoint(x: self.frame.size.width/2, y: self.frame.size.height/2 - (scoreLabel.frame.height*1.5))
        highScoreLabel.fontColor = UIColor.darkGrayColor()
        highScoreLabel.text = "High Score: \(defaults.integerForKey(scoreKey.highScore))"
        
        self.addChild(highScoreLabel)
        
        //assign bitmasks
        bottom.physicsBody?.categoryBitMask = bottomCategory
        
        basketBall.physicsBody?.categoryBitMask = ballCategory
        basketBall.physicsBody?.collisionBitMask = bottomCategory | rimCategory
        basketBall.physicsBody?.contactTestBitMask = bottomCategory

        leftRim.physicsBody?.categoryBitMask = rimCategory
        rightRim.physicsBody?.categoryBitMask = rimCategory
        
        scoringNode.physicsBody?.categoryBitMask = scoreCategory
        scoringNode.physicsBody?.collisionBitMask = 0
        scoringNode.physicsBody?.contactTestBitMask = ballCategory
        
        loadingRimNode.physicsBody?.categoryBitMask = loadRimCategory
        loadingRimNode.physicsBody?.collisionBitMask = 0
        loadingRimNode.physicsBody?.contactTestBitMask = ballCategory
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
        let firstBody = contact.bodyA
        let secondBody = contact.bodyB
        
        //if scored, increment score counter, update scorelabel and set bool to true
        if firstBody.categoryBitMask == ballCategory && secondBody.categoryBitMask == scoreCategory || firstBody.categoryBitMask == scoreCategory && secondBody.categoryBitMask == ballCategory {
            scored = true
            score += 1
        
            let highScore = defaults.integerForKey(scoreKey.highScore)
                
            //update stored highScore if current score is higher
            if score > highScore {
                defaults.setValue(score, forKey: scoreKey.highScore)
            }
            
            defaults.synchronize()
            
            scoreLabel.text = "Score: \(score)"
            highScoreLabel.text = "High Score: \(defaults.integerForKey(scoreKey.highScore))"
        }
        
        //handle all cases when ball reaches the bottom
        if firstBody.categoryBitMask == ballCategory && secondBody.categoryBitMask == bottomCategory || firstBody.categoryBitMask == bottomCategory && secondBody.categoryBitMask == ballCategory {
            if thrown {
                if scored {
                    reset()
                    let ball = basketBall
                    let possiblePositions = Int (self.frame.size.width/ball.size.width)
                    ball.position.x = CGFloat.random(possiblePositions) * ball.size.width
                    self.addChild(ball)
                } else {
                    if !passedTop {
                        self.childNodeWithName(ballCategoryName)?.removeFromParent()
                        if (score == 0) {
                            self.addChild(basketBall)
                        } else {
                            let ball = basketBall
                            let possiblePositions = Int (self.frame.size.width/ball.size.width)
                            ball.position.x = CGFloat.random(possiblePositions) * ball.size.width
                            self.addChild(ball)
                        }
                    } else {
                        score = 0
                        scoreLabel.text = "Score: 0"
                        highScoreLabel.text = "High Score: \(defaults.integerForKey(scoreKey.highScore))"
                        reset()
                        self.addChild(basketBall)
                    }
                }
                print("touched 1")
                scored = false
                thrown = false
                passedTop = false
            } else {
                //DO NOTHING
                print("touched 2")
            }
        }
    }
    
    func didEndContact(contact: SKPhysicsContact) {
        let firstBody = contact.bodyA
        let secondBody = contact.bodyB
        
        //once ball crosses the loading node, add all net scoring components
        if firstBody.categoryBitMask == ballCategory && secondBody.categoryBitMask == loadRimCategory || firstBody.categoryBitMask == loadRimCategory && secondBody.categoryBitMask == ballCategory {
            self.childNodeWithName("loading")?.removeFromParent()
            self.addChild(leftRim)
            self.addChild(rightRim)
            self.addChild(scoringNode)
            self.childNodeWithName("rimL")?.hidden = true
            self.childNodeWithName("rimR")?.hidden = true
            self.childNodeWithName("scoring")?.hidden = true

            passedTop = true
        }
    }
    
    func reset() { //reset node for clearing up the view
        self.childNodeWithName(ballCategoryName)?.removeFromParent()
        self.childNodeWithName("rimL")?.removeFromParent() //removes rims from self
        self.childNodeWithName("rimR")?.removeFromParent()
        self.childNodeWithName("scoring")?.removeFromParent()
        self.addChild(loadingRimNode)
        self.childNodeWithName("loading")?.hidden = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

private extension CGFloat {
    static func random(max: Int) -> CGFloat {
        return CGFloat(arc4random() % UInt32(max))
    }
}

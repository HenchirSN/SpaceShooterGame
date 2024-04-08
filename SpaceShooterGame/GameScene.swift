//
//  GameScene.swift
//  SpaceShooterGame
//
//  Created by Henchir on 28/01/2024.
//  Coded by Henchir and Gerges during the TP sessions and outside
//  Mostly in the Crous café with countless coffees and pain au chocolat ( very tasty )
//
//  We Used Youtube and Documentation and online materials to help us do this TP
//  

import SpriteKit

// For setting masks for the nodes
enum CollisionType : UInt32 {
    case player = 1
    case playerWeapon = 2
    case enemy = 4
    case monster = 8
}

enum EnemyType {
    case normal
    case monster
}

class GameScene: SKScene {

    // Declarations
    var enemySpawnTimer: Timer?
    var monsterSpawnTimer: Timer?
    let enemyCategory: UInt32 = 4
    let bulletCategory: UInt32 = 8
    let monsterCategory: UInt32 = 16

   
    let downwardBulletCategory: UInt32 = 32
    var score = 0
    var scoreLabel: SKLabelNode!
    var magicParticles: SKEmitterNode?

   
    let player = SKSpriteNode(imageNamed: "player");
    var isMovingUp = false
    var isMovingDown = false

    override func didMove(to view: SKView) {
        
        
        let hintLabel = SKLabelNode(text: "Press SPACE and D to shoot")
        hintLabel.position = CGPoint(x: frame.minX + 200, y: frame.maxY - 50)
        hintLabel.fontSize = 22
            addChild(hintLabel)
        
        
        let hintLabelsound = SKLabelNode(text: "This game is better when sound ON")
        hintLabelsound.position = CGPoint(x: frame.minX + 200, y: frame.maxY - 90)
        hintLabelsound.fontSize = 22
            addChild(hintLabelsound)
        
        
        // Making a special background that looks like a real night sky (idea taken from a youtube video Tutorial; Some assests (images) as well
        if let particles = SKEmitterNode(fileNamed: "Starfield"){
            particles.position = CGPoint(x: 1000, y: 0);
            particles.zPosition = -1;
            particles.advanceSimulationTime(180);
            addChild(particles);

            view.window?.acceptsMouseMovedEvents = true
            view.window?.makeFirstResponder(self)
        }

        // Making the mountain part a little bit special : as a green magic effect
        if let magic = SKEmitterNode(fileNamed: "Magic") {
            magic.position = CGPoint(x: frame.maxX, y: frame.minY + 30)
            magic.zPosition = -1
            magic.emissionAngle = CGFloat.pi
            magic.advanceSimulationTime(180)
            addChild(magic)
            magicParticles = magic
        }

        player.name="player";
        player.position.x = frame.minX + 80
        player.zPosition = 1;
        addChild(player);

        player.physicsBody = SKPhysicsBody(texture: player.texture!, size: player.texture!.size())
        player.physicsBody?.categoryBitMask = CollisionType.player.rawValue
        player.physicsBody?.collisionBitMask = CollisionType.enemy.rawValue
        player.physicsBody?.contactTestBitMask = CollisionType.enemy.rawValue | CollisionType.monster.rawValue

        
        
        player.physicsBody?.isDynamic = false

        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsWorld.contactDelegate = self

        startEnemySpawning()

        //This this for the score
        scoreLabel = SKLabelNode(text: "Score: 0")
        scoreLabel.position = CGPoint(x: frame.midX, y: frame.maxY - 50)
        addChild(scoreLabel)
    }

    //This is for updating score
    func updateScoreLabel() {
        scoreLabel.text = "Score: \(score)"
    }

    override func update(_ currentTime: TimeInterval) {
        if let magicParticles = magicParticles {
            let moveAction = SKAction.moveBy(x: -1, y: 0, duration: 0.1)
            magicParticles.run(moveAction)

            if magicParticles.position.x < frame.minX {
                magicParticles.position.x = frame.maxX
            }
        }

        if isMovingUp {
            movePlayer(up: true)
        } else if isMovingDown {
            movePlayer(up: false)
        }
    }

    //This is for handeling keyboard controls
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 126 {
            isMovingUp = true
            //Make a special sound as the player move
            run(SKAction.playSoundFileNamed("ShipSound.mp3", waitForCompletion: false))

        } else if event.keyCode == 125 {
            isMovingDown = true
            run(SKAction.playSoundFileNamed("ShipSound.mp3", waitForCompletion: false))

        }

        // On press "Space" button
        if event.keyCode == 49 {
            shootBullet()
        }

        // On press "d" button : we chose d for buttom ( Yeah everything is thought of )
        if event.keyCode == 2 {
            shootDownwardBullet()
        }
    }

    // Shoot in the down direction
    func shootDownwardBullet() {
        guard player.parent != nil else {
            return
        }

        let downwardBullet = SKSpriteNode(imageNamed: "playerWeaponDown")
        downwardBullet.position = player.position
        downwardBullet.zPosition = 1
        downwardBullet.size=CGSize(width: 15, height: 25);
        downwardBullet.physicsBody = SKPhysicsBody(rectangleOf: downwardBullet.size)
        downwardBullet.physicsBody?.categoryBitMask = bulletCategory
        downwardBullet.physicsBody?.collisionBitMask = 0
        downwardBullet.physicsBody?.contactTestBitMask = monsterCategory
        downwardBullet.physicsBody?.isDynamic = true
        addChild(downwardBullet)
        
        //Sound effect when shooting bullet
        run(SKAction.playSoundFileNamed("SinusBomb.mp3", waitForCompletion: false))
        let moveAction = SKAction.moveBy(x: 0, y: -1000, duration: 3.0)
        let removeAction = SKAction.removeFromParent()
        downwardBullet.run(SKAction.sequence([moveAction, removeAction]))
    }

    override func keyUp(with event: NSEvent) {
        if event.keyCode == 126 {
            isMovingUp = false
        } else if event.keyCode == 125 {
            isMovingDown = false
        }
    }

    private func movePlayer(up: Bool) {
        let speed: CGFloat = 50.0
        let direction: CGFloat = up ? 1.0 : -1.0

        let newPosition = CGPoint(x: player.position.x, y: player.position.y + direction * speed * CGFloat(self.frame.size.height) / 1000)

        if newPosition.y > frame.minY && newPosition.y < frame.maxY {
            let moveAction = SKAction.move(to: newPosition, duration: 0.1)
            player.run(moveAction)
        }
    }

    
    // Shoot in the horizantal direction
    private func shootBullet() {
        guard player.parent != nil else {
            return
        }
        let bullet = SKSpriteNode(imageNamed: "playerWeapon")
        bullet.position = player.position
        bullet.zPosition = 1
        bullet.physicsBody = SKPhysicsBody(rectangleOf: bullet.size)
        bullet.physicsBody?.categoryBitMask = bulletCategory
        bullet.physicsBody?.collisionBitMask = 0
        bullet.physicsBody?.contactTestBitMask = monsterCategory
        bullet.physicsBody?.isDynamic = true
        addChild(bullet)
        run(SKAction.playSoundFileNamed("BulletSound.mp3", waitForCompletion: false))
        let moveAction = SKAction.moveBy(x: 1000, y: 0, duration: 3.0)
        let removeAction = SKAction.removeFromParent()
        bullet.run(SKAction.sequence([moveAction, removeAction]))
    }

    
    // Setting Time for enemy spawing
    func startEnemySpawning() {
        enemySpawnTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(spawnEnemy), userInfo: nil, repeats: true)
        monsterSpawnTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(spawnSingleMonster), userInfo: nil, repeats: false)
    }
    
    @objc func spawnSingleMonster() {
        spawnMonster()
         monsterSpawnTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(spawnSingleMonster), userInfo: nil, repeats: false)
    }
    
    
    //Spawn Enemies in specific places not depassing the game scene
    @objc func spawnEnemy() {
        let yOffset = CGFloat.random(in: -130...300)
        let enemy = SKSpriteNode(imageNamed: "enemy")
        enemy.position = CGPoint(x: frame.maxX, y: frame.midY + yOffset)
        enemy.zPosition = 1

        enemy.physicsBody = SKPhysicsBody(rectangleOf: enemy.size)
        enemy.physicsBody?.categoryBitMask = enemyCategory
        enemy.physicsBody?.collisionBitMask = 0
        enemy.physicsBody?.contactTestBitMask = bulletCategory  // Use bulletCategory for contact with bullets
        enemy.physicsBody?.isDynamic = true

        addChild(enemy)

        let moveActionLeft = SKAction.moveBy(x: -(frame.width / 4), y: -(frame.height / 8), duration: 1.0)
        let moveActionRight = SKAction.moveBy(x: -(frame.width / 4), y: frame.height / 8, duration: 1.0)
        let removeAction = SKAction.removeFromParent()

        let zigzagAction = SKAction.sequence([moveActionLeft, moveActionRight, moveActionLeft, moveActionRight])
        let fullSequence = SKAction.sequence([zigzagAction, removeAction])

        enemy.run(fullSequence)
    }


    @objc func spawnMonster() {
        guard let magicParticles = magicParticles else {
            return
        }

        let monster = SKSpriteNode(imageNamed: "Monster")
        let verticalOffset = CGFloat.random(in: -10...40)
        let spawnY = magicParticles.frame.midY + verticalOffset
        monster.position = CGPoint(x: frame.maxX, y: spawnY)
        monster.zPosition = 1
        let monsterSize = CGSize(width: 60, height: 60)
        monster.size = monsterSize
        monster.physicsBody = SKPhysicsBody(rectangleOf: monster.size)
        monster.physicsBody?.categoryBitMask = monsterCategory
        monster.physicsBody?.collisionBitMask = 0
        monster.physicsBody?.contactTestBitMask = bulletCategory  // Use bulletCategory for contact with bullets
        monster.physicsBody?.contactTestBitMask = CollisionType.player.rawValue
        monster.physicsBody?.isDynamic = true
        addChild(monster)
        let moveAction = SKAction.moveBy(x: -(frame.width + monster.size.width), y: 0, duration: 5.0)
        let removeAction = SKAction.removeFromParent()
        let sequence = SKAction.sequence([moveAction, removeAction])
        monster.run(sequence)
    }

    
    func showExplosion(at position: CGPoint) {
        let explosion = SKSpriteNode(imageNamed: "explosion")
        explosion.size = CGSize(width: 50, height: 50)
        explosion.position = position
        explosion.zPosition = 2
        addChild(explosion)
        run(SKAction.playSoundFileNamed("Explosion.mp3", waitForCompletion: false))
        let scaleAction = SKAction.scale(by: 2.0, duration: 0.5)
        let fadeAction = SKAction.fadeOut(withDuration: 0.5)
        let removeAction = SKAction.removeFromParent()
        let explosionSequence = SKAction.sequence([SKAction.group([scaleAction, fadeAction]), removeAction])
        explosion.run(explosionSequence)
    }
}

extension GameScene: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        guard let nodeA = contact.bodyA.node, let nodeB = contact.bodyB.node else {
                    return
                }

        // Check if one of the nodes is the player and the other is an enemy
        if (nodeA.name == "player" && nodeB.physicsBody?.categoryBitMask == enemyCategory) ||
           (nodeB.name == "player" && nodeA.physicsBody?.categoryBitMask == enemyCategory) {
            // Player collided with enemy - remove player from the scene
            nodeA.removeFromParent()
            nodeB.removeFromParent()
            showGameOver()
            print("Player collided with enemy!")
        }
        
        
        //  handle player-monster collision
                if (nodeA.name == "player" && nodeB.physicsBody?.categoryBitMask == monsterCategory) ||
                   (nodeB.name == "player" && nodeA.physicsBody?.categoryBitMask == monsterCategory) {
                    // Player collided with monster - remove player from the scene
                    nodeA.removeFromParent()
                    nodeB.removeFromParent()
                    showGameOver()
                    print("Player collided with monster!")
                }

        // Check if one of the nodes is a bullet and the other is an enemy or monster
        if (nodeA.physicsBody?.categoryBitMask == bulletCategory && (nodeB.physicsBody?.categoryBitMask == enemyCategory || nodeB.physicsBody?.categoryBitMask == monsterCategory)) ||
           (nodeB.physicsBody?.categoryBitMask == bulletCategory && (nodeA.physicsBody?.categoryBitMask == enemyCategory || nodeA.physicsBody?.categoryBitMask == monsterCategory)) {
            // Handle bullet-enemy or bullet-monster collision
            print("Bullet collided with enemy or monster!")

            score += 1
            print("Score: \(score)")

            // Show explosion effect at the enemy's or monster's position
            showExplosion(at: nodeA.position)

            // Remove both the bullet and the enemy or monster from the scene
            nodeA.removeFromParent()
            nodeB.removeFromParent()

            updateScoreLabel()
        }

        // Check if one of the nodes is a downward bullet and the other is an enemy or monster
        if (nodeA.physicsBody?.categoryBitMask == downwardBulletCategory && (nodeB.physicsBody?.categoryBitMask == enemyCategory || nodeB.physicsBody?.categoryBitMask == monsterCategory)) ||
           (nodeB.physicsBody?.categoryBitMask == downwardBulletCategory && (nodeA.physicsBody?.categoryBitMask == enemyCategory || nodeA.physicsBody?.categoryBitMask == monsterCategory)) {
            // Handle downward bullet-enemy or downward bullet-monster collision
            print("Downward bullet collided with enemy or monster!")

            score += 1
            print("Score: \(score)")

            // Show explosion effect at the enemy's or monster's position
            showExplosion(at: nodeA.position)

            // Remove both the downward bullet and the enemy or monster from the scene
            nodeA.removeFromParent()
            nodeB.removeFromParent()

            updateScoreLabel()
        }
    
    }
    
    

    func showGameOver() {
        //Sound for GameOver
        run(SKAction.playSoundFileNamed("GameOver.mp3", waitForCompletion: true))

        
        // For example, you might present a new scene or show a game over label
        let gameOverLabel = SKLabelNode(text: "Looser ! You could not protect the universe from the threat!")
        gameOverLabel.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(gameOverLabel)
        
        // Add a restart button
        let restartButton = SKLabelNode(text: "Play Again")
        restartButton.position = CGPoint(x: frame.midX, y: frame.midY - 50)
        restartButton.name = "restartButton" // Name of the button for click detection
        addChild(restartButton)

        // Add a quit button
        let quitButton = SKLabelNode(text: "Quit")
        quitButton.position = CGPoint(x: frame.midX, y: frame.midY - 100)
        quitButton.name = "quitButton" // Name of the button for click detection
        addChild(quitButton)
    }

    
    override func mouseDown(with event: NSEvent) {
        let location = event.location(in: self)
        let nodesAtPoint = nodes(at: location)

        for node in nodesAtPoint {
            if node.name == "restartButton" {
                restartGame()
            } else if node.name == "quitButton" {
                quitGame()
            }
           
        }
    }
    
    
    func quitGame() {
        exit(0)
    }
    
    func restartGame() {
        // Reset game-related variables
        score = 0

        // Remove all existing nodes
        removeAllChildren()

        // Reinitialize the game state
        didMove(to: view!)

    
    }
}

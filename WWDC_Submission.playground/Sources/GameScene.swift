import PlaygroundSupport
import SpriteKit
import GameplayKit
import AVFoundation

//Categories
let BallCategory   : UInt32 = 0x1 << 0
let BottomCategory : UInt32 = 0x1 << 1
let BlockCategory  : UInt32 = 0x1 << 2
let PlayerCategory : UInt32 = 0x1 << 3
let BorderCategory : UInt32 = 0x1 << 4
let EnemyCategory : UInt32 = 0x1 << 5

//MARK: - GameScene class
public class GameScene: SKScene, SKPhysicsContactDelegate {
    
    public var ball = SKSpriteNode()
    public var enemy = SKSpriteNode(imageNamed: "paddleRed")
    public var player = SKSpriteNode()
    public var levelNumber: Int = 1
    public var playerActualColor: String = ""
    public var movingRight = false
    public var movingLeft = false
    public var canSkip = false
    
    let textures: [SKTexture] = [SKTexture(imageNamed: "yellow"), SKTexture(imageNamed: "red"), SKTexture(imageNamed: "blue")]
    let borderSound = SKAction.playSoundFileNamed("borderSound", waitForCompletion: false)
    let paddleSound = SKAction.playSoundFileNamed("paddleSound", waitForCompletion: false)
    let enemySound = SKAction.playSoundFileNamed("punch", waitForCompletion: false)
    let breakSound = SKAction.playSoundFileNamed("breakSound", waitForCompletion: false)
    let victorySound = SKAction.playSoundFileNamed("victorySound", waitForCompletion: false)
    let gameOverSound = SKAction.playSoundFileNamed("gameOver", waitForCompletion: false)
    let startSound = SKAction.playSoundFileNamed("startSound", waitForCompletion: false)
    let emitterNodeBall = SKEmitterNode(fileNamed: "animationBall")
    let blockTry = SKSpriteNode(imageNamed: "yellow")
    let animationBall = SKNode()
    var backgroundSound: AVAudioPlayer?
    
    public lazy var gameStatus: GKStateMachine = GKStateMachine(states: [
                                                                    Play(scene: self),
                                                                    PauseScene(scene: self),
                                                                    End(scene: self)])
    
    var gameWon : Bool = false {
        didSet {
            let gameOver = childNode(withName: "pressStartMessage") as! SKSpriteNode
            let textureName = gameWon ? "won" : "lost"
            let texture = SKTexture(imageNamed: textureName)
            let actionSequence = SKAction.sequence([SKAction.setTexture(texture),
                                                    SKAction.scale(to: 1.0, duration: 0.25)])
            isLevelWon(isWon: gameWon)
            gameOver.run(actionSequence)
        }
    }
    
    //MARK: - didMove
    public override func didMove(to view: SKView) {
        //Init
        ball = self.childNode(withName: "ball") as! SKSpriteNode
        player = self.childNode(withName: "player") as! SKSpriteNode
        
        //Border
        let borderBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        borderBody.restitution = 1
        borderBody.friction = 0
        self.physicsBody = borderBody
        physicsWorld.gravity = CGVector(dx: 0.0, dy: 0.0)
        physicsWorld.contactDelegate = self
        
        //Bottom
        let bottomRect = CGRect(x: frame.origin.x - 150, y: frame.origin.y + 10, width: frame.size.width + 150, height: 1)
        let bottom = SKNode()
        bottom.physicsBody = SKPhysicsBody(edgeLoopFrom: bottomRect)
        addChild(bottom)
                
        //Categories init
        bottom.physicsBody!.categoryBitMask = BottomCategory
        ball.physicsBody!.categoryBitMask = BallCategory
        player.physicsBody!.categoryBitMask = PlayerCategory
        borderBody.categoryBitMask = BorderCategory
        
        //Contact category
        ball.physicsBody!.contactTestBitMask = BottomCategory | BlockCategory | BorderCategory | PlayerCategory | EnemyCategory
        ball.physicsBody?.collisionBitMask = PlayerCategory | BorderCategory | BlockCategory | EnemyCategory
        
        //Ball animation
        setupBallAnimation()
        
        //Init blocks
        iniLevel()

        //load UI
        loadUI(showing: true)
        loadStartMessage()
    }
    
    //MARK: - didBegin
    public func didBegin(_ contact: SKPhysicsContact) {
        if gameStatus.currentState is Play {
            enemyMove()
            var firstBody: SKPhysicsBody
            var secondBody: SKPhysicsBody
            if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
                firstBody = contact.bodyA
                secondBody = contact.bodyB
            } else {
                firstBody = contact.bodyB
                secondBody = contact.bodyA
            }
            if firstBody.categoryBitMask == BallCategory && secondBody.categoryBitMask == BottomCategory {
                gameStatus.enter(End.self)
                gameWon = false
                backgroundSound?.stop()
                run(gameOverSound)
            }
            if firstBody.categoryBitMask == BallCategory && secondBody.categoryBitMask == BlockCategory {
                destroyBlock(node: secondBody.node!, didEnemyDestroyed: false)
                run(breakSound)
                if (levelNumber != 3) {
                    if isWon() {
                        run(victorySound)
                        gameStatus.enter(End.self)
                        backgroundSound?.stop()
                        gameWon = true
                        levelNumber += 1
                    }
                }
            }
            if firstBody.categoryBitMask == BallCategory && secondBody.categoryBitMask == BorderCategory {
                run(borderSound)
            }
            if firstBody.categoryBitMask == BallCategory && secondBody.categoryBitMask == PlayerCategory {
                run(paddleSound)
                checkPaddleSide()
            }
            if firstBody.categoryBitMask == BallCategory && secondBody.categoryBitMask == EnemyCategory { //TODO
                run(victorySound)
                destroyEnemy()
                backgroundSound?.stop()
                run(enemySound)
                gameWon = true
                gameStatus.enter(End.self)
                levelNumber = 1
            }
        }
    }
    
    //MARK: - Override methods
    public override func update(_ currentTime: TimeInterval) {
        gameStatus.update(deltaTime: currentTime)
        if gameStatus.currentState is Play {
            checkBuggyBall()
            if movingLeft {
                let paddleX = (player.position.x) - player.size.width/2
                if paddleX.rounded() < 720 && paddleX.rounded() > 0 {
                    player.position.x -= 7
                }
                else {
                    movingLeft = false
                }
            }
            if movingRight {
                let paddleX = (player.position.x) + player.size.width/2
                if paddleX.rounded() < 720 && paddleX.rounded() > 0 {
                    player.position.x += 7
                }
                else {
                    movingRight = false
                }
            }
        }
    }
    
    public override func keyDown(with event: NSEvent) {
        switch (event.keyCode) {
        case 123: //left
            movingLeft = true
        case 124: //right
            movingRight = true
        case 49: //space
            switch gameStatus.currentState {
            case is PauseScene:
                gameStatus.enter(Play.self)
                run(startSound)
                playLevelSound()
            case is End:
                if canSkip == true {
                    let newScene = GameScene(fileNamed: "GameScene")
                    newScene?.levelNumber = levelNumber
                    newScene?.scaleMode = .aspectFit
                    let transi = SKTransition.fade(withDuration: 0.5)
                    self.view?.presentScene(newScene!, transition: transi)
                }
            default:
                break
            }
        case 14: //e
            changeBallColor(colorIndicator: childNode(withName: "colorIndicator") as! SKShapeNode)
            
        case 15: //r
            if gameStatus.currentState is Play {
                let newScene = GameScene(fileNamed: "GameScene")
                newScene?.levelNumber = levelNumber
                newScene?.scaleMode = .aspectFit
                let transi = SKTransition.fade(withDuration: 0.5)
                self.view?.presentScene(newScene!, transition: transi)
            }
        default:
            break
        }
    }
    
    public override func keyUp(with event: NSEvent) {
        switch (event.keyCode) {
        case 123: //left
            movingLeft = false
        case 124: //right
            movingRight = false
        default:
            break
        }
    }
    
    // MARK: - Functions
    func isWon() -> Bool {
        var numberOfBlocks = 0
        self.enumerateChildNodes(withName: "yellow") {
            node, stop in
            numberOfBlocks = numberOfBlocks + 1
        }
        self.enumerateChildNodes(withName: "red") {
            node, stop in
            numberOfBlocks = numberOfBlocks + 1
        }
        self.enumerateChildNodes(withName: "blue") {
            node, stop in
            numberOfBlocks = numberOfBlocks + 1
        }
        return numberOfBlocks == 0
    }
    
    func checkPaddleSide() {
        var angleBefore : CGFloat
        var angleAfter : CGFloat
        let speedBall = sqrt(((ball.physicsBody?.velocity.dx)! * (ball.physicsBody?.velocity.dx)!) + (ball.physicsBody?.velocity.dy)! * (ball.physicsBody?.velocity.dy)!)
        let midRectangle = player.size.width/2
        angleBefore = -((ball.position.x - player.position.x) / midRectangle * CGFloat.pi/3)
        
        if ball.physicsBody?.velocity.dx == 0 {
            angleAfter = CGFloat.pi/2
        }
        else {
            angleAfter = atan2((ball.physicsBody?.velocity.dy)!, (ball.physicsBody?.velocity.dx)!)
        }
        angleBefore += CGFloat.pi/2
        angleBefore = (angleBefore + angleAfter)/2
        ball.physicsBody?.velocity.dx = speedBall * cos(angleBefore)
        ball.physicsBody?.velocity.dy = speedBall * sin(angleBefore)
    }
    
    func iniLevel() {
        switch levelNumber {
        case 1:
            loadLevelOne(nbBlocks: 12) //12
        case 2:
            loadLevelTwo(nbBlocks: 12, nbLines: 2) //12 2
        case 3:
            loadLevelThree(nbBlocks: 15, nbLines: 2) //15 2
        default:
            break
        }
    }
    
    func loadLevelOne(nbBlocks: Int) {
        let numberOfBlocks = nbBlocks
        let blockWidth = SKSpriteNode(imageNamed: "yellow").size.width
        let blockHeight = SKSpriteNode(imageNamed: "yellow").size.height
        let totalBlocksWidth = blockWidth * CGFloat(numberOfBlocks)
        let blocksDistance = (frame.width - totalBlocksWidth) / 2
        for i in 0..<numberOfBlocks {
            let blockColor = "yellow"
            let block = SKSpriteNode(imageNamed: blockColor)
            block.position = CGPoint(x: blocksDistance + CGFloat(CGFloat(i) + 0.5) * blockWidth,
                                     y: frame.height * (0.8) - (blockHeight + 0.1))
            applyPhysics(block: block, blockColor: blockColor)
            addChild(block)
        }
    }
    
    func loadLevelTwo(nbBlocks: Int, nbLines: Int) {
        let numberOfBlocks = nbBlocks
        let numerOfLines = nbLines
        let blockWidth = SKSpriteNode(imageNamed: "yellow").size.width
        let blockHeight = SKSpriteNode(imageNamed: "yellow").size.height
        let totalBlocksWidth = blockWidth * CGFloat(numberOfBlocks)
        let blocksDistance = (frame.width - totalBlocksWidth) / 2
        for l in 0..<numerOfLines {
            for b in 0..<numberOfBlocks {
                let blockColor = randomColor()
                let block = SKSpriteNode(imageNamed: blockColor)
                block.position = CGPoint(x: blocksDistance + CGFloat(CGFloat(b) + 0.5) * blockWidth,
                                         y: frame.height * (0.8) - (blockHeight + 0.1)  * CGFloat(l))
                applyPhysics(block: block, blockColor: blockColor)
                addChild(block)
            }
        }
        for b in 1...numberOfBlocks/2 {
            let blockColor = randomColor()
            let block = SKSpriteNode(imageNamed: blockColor)
            block.position = CGPoint(x: blocksDistance + CGFloat(CGFloat(b) + 2.5) * blockWidth,
                                     y: frame.height * (0.95) - (blockHeight + 0.1))
            applyPhysics(block: block, blockColor: blockColor)
            addChild(block)
        }
    }
    
    func loadLevelThree(nbBlocks: Int, nbLines: Int) {
        let numberOfBlocks = nbBlocks
        let numerOfLines = nbLines
        let blockWidth = SKSpriteNode(imageNamed: "yellow").size.width
        let blockHeight = SKSpriteNode(imageNamed: "yellow").size.height
        let totalBlocksWidth = blockWidth * CGFloat(numberOfBlocks)
        let blocksDistance = (frame.width - totalBlocksWidth) / 2
        for l in 0..<numerOfLines {
            for b in 0..<numberOfBlocks {
                let blockColor = randomColor()
                let block = SKSpriteNode(imageNamed: blockColor)
                block.position = CGPoint(x: blocksDistance + CGFloat(CGFloat(b) + 0.5) * blockWidth,
                                         y: frame.height * (0.80) - (blockHeight + 0.1)  * CGFloat(l))
                applyPhysics(block: block, blockColor: blockColor)
                addChild(block)
            }
        }
        for b in 1...numberOfBlocks/3 {
            let blockColor = randomColor()
            let block = SKSpriteNode(imageNamed: blockColor)
            block.position = CGPoint(x: blocksDistance + CGFloat(CGFloat(b) + 9.5) * blockWidth,
                                     y: frame.height * (0.50) - (blockHeight + 0.1))
            applyPhysics(block: block, blockColor: blockColor)
            addChild(block)
        }
        for b in 1...numberOfBlocks/3 {
            let blockColor = randomColor()
            let block = SKSpriteNode(imageNamed: blockColor)
            block.position = CGPoint(x: blocksDistance + CGFloat(CGFloat(b) - 0.5) * blockWidth,
                                     y: frame.height * (0.60) - (blockHeight + 0.1))
            applyPhysics(block: block, blockColor: blockColor)
            addChild(block)

        }
        addEnnemy()
    }
    
    
    func randomColor() -> String {
        let randomInt = Int.random(in: 1...99)
        
        if (randomInt <= 33) {
            return "yellow"
        }
        else if (randomInt <= 66) {
            return "blue"
        }
        else {
            return "red"
        }
    }
    
    
    func applyPhysics(block: SKSpriteNode, blockColor: String) {
        block.physicsBody = SKPhysicsBody(rectangleOf: block.frame.size)
        block.physicsBody!.allowsRotation = false
        block.physicsBody!.friction = 0.0
        block.physicsBody!.affectedByGravity = false
        block.physicsBody!.isDynamic = false
        block.name = blockColor
        block.physicsBody!.categoryBitMask = BlockCategory
        block.zPosition = 2
        block.physicsBody?.restitution = 1
    }
    
    func changeBallColor(colorIndicator: SKShapeNode) {
        if colorIndicator.fillColor == SKColor.yellow {
            colorIndicator.fillColor = SKColor.cyan
            emitterNodeBall!.particleColorSequence = SKKeyframeSequence(keyframeValues: [SKColor.cyan, SKColor.cyan, SKColor.white], times: [0.0, 1.0, 2.0])
            playerActualColor = "blue"
        }
        else if colorIndicator.fillColor == SKColor.cyan {
            colorIndicator.fillColor = SKColor.red
            emitterNodeBall!.particleColorSequence = SKKeyframeSequence(keyframeValues: [SKColor.red, SKColor.red, SKColor.white], times: [0.0, 1.0, 2.0])
            playerActualColor = "red"
        }
        else {
            colorIndicator.fillColor = SKColor.yellow
            emitterNodeBall!.particleColorSequence = SKKeyframeSequence(keyframeValues: [SKColor.yellow, SKColor.yellow, SKColor.white], times: [0.0, 1.0, 2.0])
            playerActualColor = "yellow"
        }
    }
    
    func playLevelSound() {
        var level: String = ""
        switch levelNumber {
        case 1:
            level = "levelOne.mp3"
        case 2:
            level = "levelTwo.mp3"
        case 3:
            level = "levelThree.mp3"
        default:
            level = "levelOne.mp3"
        }
        let path = Bundle.main.path(forResource: level, ofType:nil)!
        let url = URL(fileURLWithPath: path)
        do {
            backgroundSound = try AVAudioPlayer(contentsOf: url)
            backgroundSound?.numberOfLoops = -1
            backgroundSound?.play()
        } catch {
        }
    }
    
    func loadUI(showing : Bool) {
        let labelColorIndicator = scene?.childNode(withName: "labelColorIndicator")
        let levelIndicator = scene?.childNode(withName: "level")
        let texture = SKTexture(imageNamed: "lvl\(levelNumber)")
        let colorIndicator = childNode(withName: "colorIndicator") as! SKShapeNode
        levelIndicator?.run(SKAction.setTexture(texture))
        if levelNumber >= 2 && showing == true {
            colorIndicator.fillColor = SKColor.yellow
            labelColorIndicator?.isHidden = false
            colorIndicator.isHidden = false
            labelColorIndicator?.run(SKAction.sequence([
                SKAction.wait(forDuration: 10),
                SKAction.fadeOut(withDuration: 1)
            ]))
            
        } else {
            labelColorIndicator?.isHidden = true
            colorIndicator.isHidden = true
        }
    }
    
    func setupBallAnimation() {
        if levelNumber >= 2 {
            addChild(animationBall)
            emitterNodeBall?.particleColorSequence = SKKeyframeSequence(keyframeValues: [SKColor.yellow, SKColor.yellow, SKColor.yellow], times: [0.0, 1.0, 2.0])
            emitterNodeBall?.targetNode = animationBall
            ball.addChild(emitterNodeBall!)
            playerActualColor = "yellow"
        }
    }
    
    func addOneBlock() {
        var textureArray = [SKTexture]()
        let textureY = "yellow"
        let textureYY = SKTexture(imageNamed: textureY)
        textureArray.append(textureYY)
        let textureR = "red"
        let textureRR = SKTexture(imageNamed: textureR)
        textureArray.append(textureRR)
        let textureG = "blue"
        let textureGG = SKTexture(imageNamed: textureG)
        textureArray.append(textureGG)
        let animate = SKAction.animate(with: textureArray, timePerFrame: 0.5)
        blockTry.run(SKAction.repeatForever(animate))
    }
    
    func isLevelWon(isWon : Bool) {
        if levelNumber == 1 && isWon == true {
            displayUnlockedMessage()
        }
        if levelNumber == 2 && isWon == true {
            displayPressSpaceMessage(state: "continue")
            loadUI(showing: false)
        }
        if levelNumber == 3 && isWon == true {
            displayPressSpaceMessage(state: "finished")
            loadUI(showing: false)
        }
        if isWon == false {
            displayPressSpaceMessage(state: "restart")
        }
    }
    
    func displayPressSpaceMessage(state : String) {
        run(SKAction.sequence([
            SKAction.wait(forDuration: 1),
            SKAction.run {
                let next = self.childNode(withName: "pressStartMessage") as! SKSpriteNode
                let texture = SKTexture(imageNamed: state)
                if state == "finished" {
                    next.size.height = 105
                }
                let action = SKAction.sequence([SKAction.setTexture(texture),
                                                SKAction.scale(to: 1.0, duration: 0.25)])
                next.run(action)
                self.canSkip = true
            }
        ]))
    }
    
    func displayUnlockedMessage() {
        let infoMessage = SKSpriteNode(imageNamed: "unlocked")
        infoMessage.name = "unlocked"
        infoMessage.position = CGPoint(x: frame.midX, y: frame.midY - 50)
        infoMessage.zPosition = 4
        infoMessage.setScale(0.0)
        addChild(infoMessage)
        let actionSequenceInfo = SKAction.sequence([SKAction.fadeIn(withDuration: 1),
                                                    SKAction.scale(to: 1, duration: 0.25)])
        let infoNode = childNode(withName: "unlocked") as! SKSpriteNode
        infoNode.run(actionSequenceInfo)
        
        blockTry.position = CGPoint(x:  frame.midX + 105, y: frame.midY - 50)
        addOneBlock()
        run(SKAction.sequence([
            SKAction.wait(forDuration: 1.50),
            SKAction.run { [self] in
                addChild(blockTry)
                displayPressSpaceMessage(state: "continue")
            }
        ]))
    }
    
    func randomFloat(from:CGFloat, to:CGFloat) -> CGFloat {
      let rand:CGFloat = CGFloat(Float(arc4random()) / Float(0xFFFFFFFF))
      return (rand) * (to - from) + from
    }
    
    func loadStartMessage() {
        let startMessage = SKSpriteNode(imageNamed: "start")
        startMessage.name = "pressStartMessage"
        startMessage.position = CGPoint(x: frame.midX, y: frame.midY)
        startMessage.zPosition = 4
        startMessage.setScale(0.0)
        addChild(startMessage)
        gameStatus.enter(PauseScene.self)
    }
    
    func addEnnemy() {
        let enemyBody = SKPhysicsBody(edgeLoopFrom: enemy.frame)
        enemy.position = CGPoint(x: frame.midX, y: 500)
        enemy.size.width = player.size.width
        enemy.size.height = player.size.height
        enemyBody.friction = 0
        enemy.physicsBody = enemyBody
        enemy.physicsBody?.categoryBitMask = EnemyCategory
        addChild(enemy)
    }
    
    func enemyMove() {
        let posBallX = ball.position.x
        let posBallY = ball.position.y
        let posEnemyX = enemy.position.x
        
        if posEnemyX.rounded() < 720 && posEnemyX.rounded() > 0  {
            let xRdm = CGFloat.random(in: 52...688)
            
            if posBallX >= 480 && posBallY >= 300 {
                enemy.run(SKAction.moveTo(x: 100, duration: 1))
            }
            else if posBallX <= 240 && posBallY >= 300 {
                enemy.run(SKAction.moveTo(x: 600, duration: 1))
            }
            else {
                enemy.run(SKAction.sequence([
                    SKAction.moveTo(x: xRdm, duration: 1),
                ]))
            }
        }
    }
    
    func checkBuggyBall() {
        if ball.position.x > frame.maxX || ball.position.x < frame.minX || ball.position.y > frame.maxY || ball.position.y < frame.minY {
            ball.position.x = frame.midX
        }
    }
    
    func destroyBlock(node: SKNode, didEnemyDestroyed: Bool) {
        if node.name == playerActualColor || levelNumber == 1 {
            if levelNumber == 1 {
                playerActualColor = "yellow"
            }
            let emitterNodePlateform = SKEmitterNode(fileNamed: "animationBreak")
            emitterNodePlateform?.particleTexture = SKTexture(imageNamed: playerActualColor)
            emitterNodePlateform?.position = node.position
            addChild(emitterNodePlateform!)
            emitterNodePlateform?.run(SKAction.sequence([SKAction.wait(forDuration: 1), SKAction.removeFromParent()]))
            node.removeFromParent()
        }
        else if didEnemyDestroyed != true {
            run(borderSound)
        }
    }
    
    func destroyEnemy() {
        let emitterNodePlateform = SKEmitterNode(fileNamed: "animationBreakEnemy")
        emitterNodePlateform?.position = enemy.position
        addChild(emitterNodePlateform!)
        emitterNodePlateform?.run(SKAction.sequence([SKAction.wait(forDuration: 1), SKAction.removeFromParent()]))
        enemy.removeFromParent()
        cleanAllSprite()
    }
    
    func cleanAllSprite() {
        let levelIndicator = scene?.childNode(withName: "level")
        for child in self.children {
            playerActualColor = "yellow"
            destroyBlock(node: child, didEnemyDestroyed: true)
            playerActualColor = "red"
            destroyBlock(node: child, didEnemyDestroyed: true)
            playerActualColor = "blue"
            destroyBlock(node: child, didEnemyDestroyed: true)
            player.isHidden = true
            levelIndicator?.isHidden = true
            
        }
    }
}

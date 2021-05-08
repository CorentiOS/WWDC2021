import SpriteKit
import GameplayKit

public class Play: GKState {
    public unowned let scene: GameScene
    
    public init(scene: SKScene) {
        self.scene = scene as! GameScene
        super.init()
    }
    
    public override func didEnter(from previousState: GKState?) {
        if previousState is PauseScene {
            let ball = scene.childNode(withName: "ball") as! SKSpriteNode
            ball.physicsBody?.applyImpulse(CGVector(dx: -10, dy: -10))
        }
    }
    
    public override func update(deltaTime seconds: TimeInterval) {
        let ball = scene.childNode(withName: "ball") as! SKSpriteNode
        let speed = sqrt(ball.physicsBody!.velocity.dx * ball.physicsBody!.velocity.dx + ball.physicsBody!.velocity.dy * ball.physicsBody!.velocity.dy)
        let speedX = sqrt(ball.physicsBody!.velocity.dx * ball.physicsBody!.velocity.dx)
        let speedY = sqrt(ball.physicsBody!.velocity.dy * ball.physicsBody!.velocity.dy)
        
        if speedX <= 10.0 {
            ball.physicsBody!.applyImpulse(CGVector(dx: randomDirection(), dy: 0.0))
        }
        if speedY <= 10.0 {
            ball.physicsBody!.applyImpulse(CGVector(dx: 0.0, dy: randomDirection()))
        }
        
        if speed > 450 {
            ball.physicsBody!.linearDamping = 0.2
            
        } else {
            ball.physicsBody!.linearDamping = 0.0
        }
    }
    
    func randomDirection() -> CGFloat {
      let speedFactor: CGFloat = 3.0
      if scene.randomFloat(from: 0.0, to: 100.0) >= 50 {
        return -speedFactor
      } else {
        return speedFactor
      }
    }
    
}

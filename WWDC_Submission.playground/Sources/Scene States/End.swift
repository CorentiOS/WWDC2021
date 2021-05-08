import SpriteKit
import GameplayKit

public class End: GKState {
    public unowned let scene: GameScene
    
    public init(scene: SKScene) {
        self.scene = scene as! GameScene
        super.init()
        
    }
    
    public override func didEnter(from previousState: GKState?) {
        if previousState is Play {
            let ball = scene.childNode(withName: "ball") as! SKSpriteNode
            ball.removeFromParent()
            
        }
        
    }
    
}

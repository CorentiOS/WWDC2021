import SpriteKit
import GameplayKit

public class PauseScene: GKState {
    public unowned let scene: GameScene
    
    public init(scene: SKScene) {
        self.scene = scene as! GameScene
        super.init()
        
    }
    
    public override func didEnter(from previousState: GKState?) {
        let scale = SKAction.scale(to: 1.0, duration: 0.25)
        scene.childNode(withName: "pressStartMessage")!.run(scale)
        
    }
    public override func willExit(to nextState: GKState) {
        let scale = SKAction.scale(to: 0, duration: 0.4)
        scene.childNode(withName: "pressStartMessage")!.run(scale)
    }
    
    
}

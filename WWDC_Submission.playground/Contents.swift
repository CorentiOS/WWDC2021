/*:
# *Welcome to Breakout!*
  The arcade game of the time
 
 ## How to play ?
 - Use arrow keys :  **←** (Left) and  **→** (Right)
 - Use **E** letter to change the color of your ball
 - Use **Space Bar** to move through the menus
 - Use **R** letter to restart the level

 The objective of the game is to break all the bricks with your ball by making it bounce with your paddle.
 If you drop the ball, you lose.
 
 - Note: If you are stuck, or want to go directly to a level, edit the line below *let level = 1* and change the number according to the level you want. (1 or 2 or 3)
 */
let level = 1
/*:
The game is composed of three levels, I hope you will be strong enough to finish them! 😛

 ## **Good Luck and Have Fun !**
 
 - Credits :
 
 Images : "Paddle", "Ball", "Blocks", "Trees", "Montains", "BackMoutain", "Background", "Forest" of *Kenney.nl* & *ansimuz*
 
 Sounds : "Victory", "Start", "Paddle", "Game Over", "Break", "Border" of *Shiru* & *OwlishMedia* & *captaincrunch80* & *zuvizu*

 
 and Musics : "Level One", "Level Two", "Level Three" of *nene*
 
 are under the **CC0 Public Domain license** of *OpenGameArt.org*
 */
import PlaygroundSupport
import SpriteKit

let sceneView = SKView(frame: CGRect(x:0 , y:0, width: 720, height: 520))
if let scene = GameScene(fileNamed: "GameScene") {
    scene.scaleMode = .aspectFill
    scene.levelNumber = level
    sceneView.presentScene(scene)
}
PlaygroundSupport.PlaygroundPage.current.liveView = sceneView

//
//  GameScene.swift
//  FlappyBird
//
//  Created by Chan Yama on 2020/09/24.
//  Copyright © 2020 moe.hatori2. All rights reserved.
//

import SpriteKit
import AVFoundation


class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var scrollNode:SKNode!
    var wallNode:SKNode!
    var bird:SKSpriteNode!
    var orangeNode:SKNode! //アイテム用の宣言
    var flappySoundNode:SKAudioNode! //音出す用の宣言
    
    // 衝突判定カテゴリー
    let birdCategory: UInt32 = 1 << 0       // 0...00001
    let groundCategory: UInt32 = 1 << 1     // 0...00010
    let wallCategory: UInt32 = 1 << 2       // 0...00100
    let scoreCategory: UInt32 = 1 << 3      // 0...01000
    let orangeCategory: UInt32 = 1 << 4     // 0...10000   オレンジスコア用
    

    // スコア用
    var score = 0
    let userDefaults:UserDefaults = UserDefaults.standard
    var scoreLabelNode:SKLabelNode!
    var bestScoreLabelNode:SKLabelNode!
    
    //アイテム（オレンジ）用のスコア
    var orangescore = 0
    var orangeLabelNode:SKLabelNode!
    
    // SKView上にシーンが表示されたときに呼ばれるメソッド
    override func didMove(to view: SKView) {

        // 重力を設定
        physicsWorld.gravity = CGVector(dx: 0, dy: -4)
        physicsWorld.contactDelegate = self

        // 背景色を設定
        backgroundColor = UIColor(red: 0.15, green: 0.75, blue: 0.90, alpha: 1)

        // スクロールするスプライトの親ノード
        scrollNode = SKNode()
        addChild(scrollNode)

        // 壁用のノード
        wallNode = SKNode()
        scrollNode.addChild(wallNode)
        
        //オレンジ用のノード
        orangeNode = SKNode()
        scrollNode.addChild(orangeNode)
        
        //オーディオ用のノード
        //flappySoundNode = SKAudioNode(fileNamed: "Flappysound.mp3")
        flappySoundNode = SKAudioNode(url: Bundle.main.url(forResource: "Flappysound", withExtension: "mp3")!)
        flappySoundNode.autoplayLooped = false
        scrollNode.addChild(flappySoundNode)

        // 各種スプライトを生成する処理をメソッドに分割
        setupGround()
        setupCloud()
        setupWall()
        setupBird()
        setupOrange()  //item用
        
        setupScoreLabel()
    }
    
    
    //item(orange)用のメソッド
    
    func setupOrange(){
        
        //オレンジを表示するためのメソッド
        let orangeTexture = SKTexture(imageNamed: "orange")
        orangeTexture.filteringMode = .linear
        
        
        // 移動する距離を計算
        let movingDistance_orange = CGFloat(self.frame.size.width + orangeTexture.size().width)

        // 画面外まで移動するアクションを作成
        let moveOrange = SKAction.moveBy(x: -movingDistance_orange, y: 0, duration:4)

        // 自身を取り除くアクションを作成
        let removeOrange = SKAction.removeFromParent()

        // 2つのアニメーションを順に実行するアクションを作成
        let orangeAnimation = SKAction.sequence([moveOrange, removeOrange])
        
        let random_orange_range = orangeTexture.size().height * 3

        // オレンジを生成するアクションを作成
        let createOrangeAnimation = SKAction.run({

           // オレンジ関連のノードを乗せるノードを作成
            let orange = SKNode()
            //オレンジ関連のノードの中心座標
            orange.position = CGPoint(x: self.frame.size.width/2, y:self.frame.size.height/2)
            orange.zPosition = -50
        
            //オレンジの位置を少しずらすためのランダムを生成
            let random_orange_y = CGFloat.random(in: 0..<random_orange_range)

            // オレンジを作成
            let position_orange = SKSpriteNode(texture: orangeTexture)
            position_orange.size = CGSize(width: orangeTexture.size().width/3, height: orangeTexture.size().height/3)
            position_orange.position = CGPoint(x: random_orange_y, y: random_orange_y)
            
            //物理演算を受け付けるようにする
            position_orange.physicsBody = SKPhysicsBody(circleOfRadius:orangeTexture.size().height / 3)
            position_orange.physicsBody?.categoryBitMask = self.orangeCategory
            //オレンジが動かないようにしている
            position_orange.physicsBody?.isDynamic = false
        
            // 衝突のカテゴリー設定
            position_orange.physicsBody?.categoryBitMask = self.orangeCategory
            position_orange.physicsBody?.contactTestBitMask = self.birdCategory
            

            orange.addChild(position_orange)

            orange.run(orangeAnimation)

            self.orangeNode.addChild(orange)

         })

            // 次のオレンジ作成までの時間待ちのアクションを作成
            let waitAnimation_orange = SKAction.wait(forDuration:2)

            // オレンジを作成->時間待ち->オレンジを作成を無限に繰り返すアクションを作成
            let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createOrangeAnimation, waitAnimation_orange]))

            orangeNode.run(repeatForeverAnimation)
        
        }
        
    
    
    //groundを表示するためのメソッド
   func setupGround() {
        // 地面の画像を読み込む
        let groundTexture = SKTexture(imageNamed: "ground")
        groundTexture.filteringMode = .nearest

        // 必要な枚数を計算
        let needNumber = Int(self.frame.size.width / groundTexture.size().width) + 2

        // スクロールするアクションを作成
        // 左方向に画像一枚分スクロールさせるアクション
        let moveGround = SKAction.moveBy(x: -groundTexture.size().width , y: 0, duration: 5)

        // 元の位置に戻すアクション
        let resetGround = SKAction.moveBy(x: groundTexture.size().width, y: 0, duration: 0)

        // 左にスクロール->元の位置->左にスクロールと無限に繰り返すアクション
        let repeatScrollGround = SKAction.repeatForever(SKAction.sequence([moveGround, resetGround]))

        // groundのスプライトを配置する
        for i in 0..<needNumber {
            let sprite = SKSpriteNode(texture: groundTexture)

            // スプライトの表示する位置を指定する
            sprite.position = CGPoint(
                x: groundTexture.size().width / 2  + groundTexture.size().width * CGFloat(i),
                y: groundTexture.size().height / 2
            )

            // スプライトにアクションを設定する
            sprite.run(repeatScrollGround)

            // スプライトに物理演算を設定する
            sprite.physicsBody = SKPhysicsBody(rectangleOf: groundTexture.size())

            // 衝突のカテゴリー設定
            sprite.physicsBody?.categoryBitMask = groundCategory

            // 衝突の時に動かないように設定する
            sprite.physicsBody?.isDynamic = false

            // スプライトを追加する
            scrollNode.addChild(sprite)
        }
    }
    
    //雲を表示するためのメソッド
    func setupCloud(){
        
        // 雲の画像を読み込む
        let cloudTexture = SKTexture(imageNamed: "cloud")
        cloudTexture.filteringMode = .nearest

        // 必要な枚数を計算
        let needCloudNumber = Int(self.frame.size.width / cloudTexture.size().width) + 2

        // スクロールするアクションを作成
        // 左方向に画像一枚分スクロールさせるアクション
        let moveCloud = SKAction.moveBy(x: -cloudTexture.size().width , y: 0, duration: 20)

        // 元の位置に戻すアクション
        let resetCloud = SKAction.moveBy(x: cloudTexture.size().width, y: 0, duration: 0)

        // 左にスクロール->元の位置->左にスクロールと無限に繰り返すアクション
        let repeatScrollCloud = SKAction.repeatForever(SKAction.sequence([moveCloud, resetCloud]))

        // スプライトを配置する
        for i in 0..<needCloudNumber {
            let sprite = SKSpriteNode(texture: cloudTexture)
            sprite.zPosition = -100 // 一番後ろになるようにする

            // スプライトの表示する位置を指定する
            sprite.position = CGPoint(
                x: cloudTexture.size().width / 2 + cloudTexture.size().width * CGFloat(i),
                y: self.size.height - cloudTexture.size().height / 2
            )
            // スプライトにアニメーションを設定する
            sprite.run(repeatScrollCloud)

            // スプライトを追加する
            scrollNode.addChild(sprite)
          }
    }
    
    
    //障害物（壁）を表示するためのメソッド
     func setupWall() {
         // 壁の画像を読み込む
         let wallTexture = SKTexture(imageNamed: "wall")
         wallTexture.filteringMode = .linear

         // 移動する距離を計算
         let movingDistance = CGFloat(self.frame.size.width + wallTexture.size().width)

         // 画面外まで移動するアクションを作成
         let moveWall = SKAction.moveBy(x: -movingDistance, y: 0, duration:4)

         // 自身を取り除くアクションを作成
         let removeWall = SKAction.removeFromParent()

         // 2つのアニメーションを順に実行するアクションを作成
         let wallAnimation = SKAction.sequence([moveWall, removeWall])

         // 鳥の画像サイズを取得
         let birdSize = SKTexture(imageNamed: "bird_a").size()

         // 鳥が通り抜ける隙間の長さを鳥のサイズの3倍とする
         let slit_length = birdSize.height * 4

         // 隙間位置の上下の振れ幅を鳥のサイズの3倍とする
         let random_y_range = birdSize.height * 4

         // 下の壁のY軸下限位置(中央位置から下方向の最大振れ幅で下の壁を表示する位置)を計算
         let groundSize = SKTexture(imageNamed: "ground").size()
         let center_y = groundSize.height + (self.frame.size.height - groundSize.height) / 2
         let under_wall_lowest_y = center_y - slit_length / 2 - wallTexture.size().height / 2 - random_y_range / 2

         // 壁を生成するアクションを作成
         let createWallAnimation = SKAction.run({
             // 壁関連のノードを乗せるノードを作成
             let wall = SKNode()
             wall.position = CGPoint(x: self.frame.size.width + wallTexture.size().width / 2, y: 0)
             wall.zPosition = -50 // 雲より手前、地面より奥

             // 0〜random_y_rangeまでのランダム値を生成
             let random_y = CGFloat.random(in: 0..<random_y_range)
             // Y軸の下限にランダムな値を足して、下の壁のY座標を決定
             let under_wall_y = under_wall_lowest_y + random_y

             // 下側の壁を作成
             let under = SKSpriteNode(texture: wallTexture)
             under.position = CGPoint(x: 0, y: under_wall_y)

             // スプライトに物理演算を設定する
             under.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
             under.physicsBody?.categoryBitMask = self.wallCategory    // ←追加

             // 衝突の時に動かないように設定する
             under.physicsBody?.isDynamic = false

             wall.addChild(under)

             // 上側の壁を作成
             let upper = SKSpriteNode(texture: wallTexture)
             upper.position = CGPoint(x: 0, y: under_wall_y + wallTexture.size().height + slit_length)

             // スプライトに物理演算を設定する
             upper.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
             upper.physicsBody?.categoryBitMask = self.wallCategory

             // 衝突の時に動かないように設定する
             upper.physicsBody?.isDynamic = false

             wall.addChild(upper)

             // スコアアップ用のノード
             let scoreNode = SKNode()
             scoreNode.position = CGPoint(x: upper.size.width + birdSize.width / 2, y: self.frame.height / 2)
             scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.frame.size.height))
             scoreNode.physicsBody?.isDynamic = false
             scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
             scoreNode.physicsBody?.contactTestBitMask = self.birdCategory

             wall.addChild(scoreNode)
             

             wall.run(wallAnimation)

             self.wallNode.addChild(wall)
         })

         // 次の壁作成までの時間待ちのアクションを作成
         let waitAnimation = SKAction.wait(forDuration: 2)

         // 壁を作成->時間待ち->壁を作成を無限に繰り返すアクションを作成
         let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createWallAnimation, waitAnimation]))

         wallNode.run(repeatForeverAnimation)
     }
    
    //鳥を表示するためのメソッド
     func setupBird() {
        // 鳥の画像を2種類読み込む
        let birdTextureA = SKTexture(imageNamed: "bird_a")
        birdTextureA.filteringMode = .linear
        let birdTextureB = SKTexture(imageNamed: "bird_b")
        birdTextureB.filteringMode = .linear

        // 2種類のテクスチャを交互に変更するアニメーションを作成
        let texturesAnimation = SKAction.animate(with: [birdTextureA, birdTextureB], timePerFrame: 0.2)
        let flap = SKAction.repeatForever(texturesAnimation)

        // スプライトを作成
        bird = SKSpriteNode(texture: birdTextureA)
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y:self.frame.size.height * 0.7)
        
        // 物理演算を設定
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2)
        
        // 衝突した時に回転させない
        bird.physicsBody?.allowsRotation = false

        // 衝突のカテゴリー設定
        bird.physicsBody?.categoryBitMask = birdCategory
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.physicsBody?.contactTestBitMask = groundCategory | wallCategory | orangeCategory

        // アニメーションを設定
        bird.run(flap)

        // スプライトを追加する
        addChild(bird)
           
       }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if scrollNode.speed > 0 {
            // 鳥の速度をゼロにする
            bird.physicsBody?.velocity = CGVector.zero

            // 鳥に縦方向の力を与える
            bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 15))
        } else if bird.speed == 0 {
            restart()
        }
    }
    
    // SKPhysicsContactDelegateのメソッド(衝突したときに呼ばれる)
    func didBegin(_ contact: SKPhysicsContact) {
        
        var orangeBody: SKPhysicsBody
        
        
        // ゲームオーバーのときは何もしない
        if scrollNode.speed <= 0 {
            return
        }

        if (contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory {
            // スコア用の物体と衝突した
            print("ScoreUp")
            score += 1
            scoreLabelNode.text = "Score:\(score)"

            // ベストスコア更新か確認する
            var bestScore = userDefaults.integer(forKey: "BEST")
            if score > bestScore {
                bestScore = score
                bestScoreLabelNode.text = "Best Score:\(bestScore)"
                userDefaults.set(bestScore, forKey: "BEST")
                userDefaults.synchronize()
            }
            
        } else if(contact.bodyA.categoryBitMask & orangeCategory) == orangeCategory || (contact.bodyB.categoryBitMask & orangeCategory) == orangeCategory{
            //オレンジと衝突した
            print("item Score up")
            orangescore += 1
            
            orangeLabelNode.text = "ItemScore:\(orangescore)"
            
            //音を鳴らす
            let playAction = SKAction.play()
            flappySoundNode.run(playAction)
            
            //衝突したオレンジを消す処理
            //AとBのどちらがオレンジか確認する
            if (contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask){
                orangeBody = contact.bodyB
            } else {
                orangeBody = contact.bodyA
            }
            //衝突したオレンジのノードだけを消す
            orangeBody.node?.removeFromParent()
            
            
        } else {
            // 壁か地面と衝突した
            print("GameOver")

            // スクロールを停止させる
            scrollNode.speed = 0

            bird.physicsBody?.collisionBitMask = groundCategory

            let roll = SKAction.rotate(byAngle: CGFloat(Double.pi) * CGFloat(bird.position.y) * 0.01, duration:1)
            bird.run(roll, completion:{
                self.bird.speed = 0
            })
        }
    }
    
    
    
    
    
    func restart() {
        score = 0
        orangescore = 0
        scoreLabelNode.text = "Score:\(score)"
        orangeLabelNode.text = "ItemScore:\(orangescore)"

        bird.position = CGPoint(x: self.frame.size.width * 0.2, y:self.frame.size.height * 0.7)
        bird.physicsBody?.velocity = CGVector.zero
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.zRotation = 0

        wallNode.removeAllChildren()

        bird.speed = 1
        scrollNode.speed = 1
    }
    
    
    func setupScoreLabel() {
        print("score")
        score = 0
        scoreLabelNode = SKLabelNode()
        scoreLabelNode.fontColor = UIColor.black
        scoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 60)
        scoreLabelNode.zPosition = 100 // 一番手前に表示する
        scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        scoreLabelNode.text = "Score:\(score)"
        self.addChild(scoreLabelNode)

        bestScoreLabelNode = SKLabelNode()
        bestScoreLabelNode.fontColor = UIColor.black
        bestScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 90)
        bestScoreLabelNode.zPosition = 100 // 一番手前に表示する
        bestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left

        let bestScore = userDefaults.integer(forKey: "BEST")
        bestScoreLabelNode.text = "Best Score:\(bestScore)"
        self.addChild(bestScoreLabelNode)
        
        orangeLabelNode = SKLabelNode()
        orangeLabelNode.fontColor = UIColor.black
        orangeLabelNode.position = CGPoint(x: 10, y:self.frame.size.height - 120)
        orangeLabelNode.zPosition = 100
        orangeLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        orangeLabelNode.text = "Item Score:\(orangescore)"
        self.addChild(orangeLabelNode)
        
        
    }
    
    
    
    
    
    
}

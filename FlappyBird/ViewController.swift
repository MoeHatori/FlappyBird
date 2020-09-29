//
//  ViewController.swift
//  FlappyBird
//
//  Created by Chan Yama on 2020/09/24.
//  Copyright © 2020 moe.hatori2. All rights reserved.
//

import UIKit
import SpriteKit //SpriteKitのフレームワークを使う

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        //SKViewに型を変換する
        let skView = self.view as! SKView
        
        //FPSを表示：アプリ画面右下に１秒間に何回画面が更新されているかを表示する
        skView.showsFPS = true
        
        //ノードの数を表示する：アプリ画面右下にノードがいくつ画面に表示されているかを表示する
        skView.showsNodeCount = true
        
        //ビューと同じサイズでシーンを作成する
        let scene = GameScene(size:skView.frame.size)
        
        //ビューにシーンを表示する
        skView.presentScene(scene)
    }
    
    // ステータスバーを消す
    override var prefersStatusBarHidden: Bool {
        get {
            return true
        }
    }
    
    
    


}


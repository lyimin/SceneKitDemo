//
//  Display3DViewController.swift
//  fommos
//
//  Created by Eamon Liang on 2022/1/19.
//  Copyright © 2022 fommos. All rights reserved.
//

import Foundation
import UIKit
import Photos


class Display3DViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
                
        view.addSubview(bgImageView)
        bgImageView.frame = view.bounds
        
        view.addSubview(menuView)

        view.addSubview(backBtn)
        backBtn.frame = CGRect(x: view.frame.width - 88, y: 64, width: 64, height: 32)
        
        view.addSubview(snapButton)
        snapButton.frame = CGRect(x: 0, y: 0, width: 64, height: 32)
        snapButton.center = CGPoint(x: view.center.x, y: view.frame.height - 100)
        
        view.addSubview(contentView)
        view.addSubview(menuView)

        contentView.addSubview(actionButton)
        actionButton.frame = CGRect(x: 0, y: 0, width: 120, height: 48)
        actionButton.center = view.center
        
        contentView.addSubview(coverView)
        coverView.frame = view.bounds
        
        /// TIPS: transition3D会把 contenView 置到顶层，需要设置 zPosition 把 sceneView 重新置到最顶
        sceneView.layer.zPosition = 999
        view.addSubview(contentView)
        view.addSubview(sceneView)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
    }
    
    @objc private func onActionButtonPress() {
        backBtn.isHidden = false
        snapButton.isHidden = false
        sceneView.isHidden = false
        
        view.bringSubviewToFront(backBtn)
        view.bringSubviewToFront(snapButton)
        sceneView.setupScene()
    }
    
    @objc private func onBackBtnPress() {
        backBtn.isHidden = true
        snapButton.isHidden = true
        view.isUserInteractionEnabled = false
        sceneView.fadeOutAnimation()
        
        UIView.animate(withDuration: 0.56, delay: 0.56, options: .curveEaseOut) {
            self.contentView.layer.transform = CATransform3DIdentity
            self.contentView.layer.position = CGPoint(x: 0, y: self.view.bounds.midY)
            self.menuView.layer.transform = self.menuTransform(fraction: 0)
            self.coverView.alpha = 0
        } completion: { [weak self]_ in
            Timer.after(1) { [weak self] in 
                self?.remove3DSceneView()
                self?.contentView.isUserInteractionEnabled = true
                self?.view.isUserInteractionEnabled = true
            }
        }
    }
    
    @objc private func onSnapBtnPress() {
        if let image = sceneView.sceneView?.snapshot() {
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { success, err in
                if success {
                    print("保存到相册成功")
                }
                else {
                    print("保存到相册失败")
                }
            }
        }
    }
    
    func remove3DSceneView() {
        sceneView.isHidden = true
        sceneView.didRender = false
    }
    
    // fraction: 0~1
    func menuTransform(fraction: CGFloat) -> CATransform3D {
        var identity = CATransform3DIdentity
        identity.m34 = -1.0 / 1000.0
        let angle = Double(1.0 - fraction) * -(Double.pi/2)
        let xOffset = fraction*64
        let rotateTransform = CATransform3DRotate(identity, CGFloat(angle), 0.0, 1.0, 0.0)
        let translateTransform = CATransform3DMakeTranslation(xOffset, 0.0, 0.0)
        return CATransform3DConcat(rotateTransform, translateTransform)
    }
    
    /// 3D 场景
    private lazy var sceneView: Detail3DSceneView = {
        let sceneView = Detail3DSceneView(frame: CGRect(origin: .zero, size: view.frame.size))
        sceneView.isHidden = true
        sceneView.delegate = self
        return sceneView
    }()
    
    private lazy var contentView: UIView = {
        
        var contentView = UIView()
        contentView.frame = view.bounds
        contentView.backgroundColor = .white
        return contentView
    }()
    
    private lazy var menuView: Detail3DMenuView = {
        
        var menuView = Detail3DMenuView()
        menuView.backgroundColor = .white
        menuView.frame = CGRect(x: -32, y: 0, width: 64, height: view.frame.height)
        menuView.layer.anchorPoint = CGPoint(x: 1, y: 0.5)
        menuView.layer.transform = menuTransform(fraction: 0)
        menuView.layer.zPosition = 900
        return menuView
    }()
    
    private(set) lazy var coverView: UIView = {
        
        var coverView = UIView()
        coverView.alpha = 0
        let tap = UITapGestureRecognizer(target: self, action: #selector(onBackBtnPress))
        coverView.addGestureRecognizer(tap)
        coverView.backgroundColor = UIColor.black.withAlphaComponent(0.16)
        return coverView
    }()

    
    private lazy var actionButton: UIButton = {
        
        var actionButton = UIButton()
        actionButton.backgroundColor = .red
        actionButton.setTitle("run".uppercased(), for: .normal)
        actionButton.setTitleColor(UIColor.black, for: .normal)
        actionButton.addTarget(self, action: #selector(onActionButtonPress), for: .touchUpInside)
        return actionButton
    }()
    
    private lazy var backBtn: UIButton = {
        
        var actionButton = UIButton()
        actionButton.backgroundColor = .white
        actionButton.setTitle("back".uppercased(), for: .normal)
        actionButton.setTitleColor(UIColor.black, for: .normal)
        actionButton.addTarget(self, action: #selector(onBackBtnPress), for: .touchUpInside)
        return actionButton
    }()
    
    private lazy var bgImageView: UIImageView = {
        
        var imageView = UIImageView()
        imageView.contentMode = .scaleToFill
        imageView.image = UIImage(named: "launch_bg")
        return imageView
    }()
    
    private lazy var snapButton: UIButton = {
        
        var actionButton = UIButton()
        actionButton.backgroundColor = .white
        actionButton.setTitle("截图", for: .normal)
        actionButton.setTitleColor(UIColor.black, for: .normal)
        actionButton.addTarget(self, action: #selector(onSnapBtnPress), for: .touchUpInside)
        return actionButton
    }()
    
    
}


extension Display3DViewController: Detail3DSceneViewDelegate {
    

    func onViewDidTouch(_ contentView: Detail3DSceneView) {
        
        // let transform = CATransform3DMakeRotation(Double.pi/2, 0, -1, 0)
        var transform = CATransform3DIdentity
        transform.m34 = 0.002
        transform = CATransform3DRotate(transform, Double.pi/2, 0, -1, 0)
        
        let menuTransform = CGAffineTransform(translationX: 0, y: 0)

        // 翻转动画
        UIView.animate(withDuration: 0.37) {
            self.menuView.transform = menuTransform
            self.contentView.layer.transform = transform
            self.contentView.layer.position = CGPoint(x: 0, y: self.view.bounds.midY)
        } completion: { _ in
            // FMSLog("self: \(self.contentView)")
        }
    }
    
    func didRenderScene() {
        
        contentView.isUserInteractionEnabled = false
        backBtn.isHidden = false

        var transform = CATransform3DIdentity
        transform.m34 = 0.001
        
        
        // 75°
//        transform = CATransform3DTranslate(transform, 48, 0, 0)
        transform = CATransform3DRotate(transform, Double.pi/2.4, 0, -1, 0)
        
        /// 设置 anchorPoint
        contentView.layer.anchorPoint = CGPoint(x: 0, y: 0.5)
        contentView.layer.position = CGPoint(x: 0, y: self.view.bounds.midY)

        // 翻转动画
        UIView.animate(withDuration: 0.56, delay: 0, options: .curveEaseOut) {
            self.menuView.layer.transform = self.menuTransform(fraction: 1)
            self.contentView.layer.transform = transform
            self.contentView.layer.position = CGPoint(x: 64, y: self.view.bounds.midY)
            self.coverView.alpha = 1
        } completion: { _ in
        }
    }
}

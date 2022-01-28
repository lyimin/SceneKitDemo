//
//  Detail3DSceneView.swift
//  fommos
//
//  Created by Eamon Liang on 2022/1/10.
//  Copyright © 2022 fommos. All rights reserved.
//

import Foundation
import UIKit
import SceneKit


protocol Detail3DSceneViewDelegate: AnyObject {
    
    /// 点击屏幕回调
    func onViewDidTouch(_ contentView: Detail3DSceneView)
    
    /// 渲染完场景回调
    func didRenderScene()
}

class Detail3DSceneView: UIView {
    
    weak var delegate: Detail3DSceneViewDelegate?
    
    /// 模型名称
    private let modelName = "Model.obj"
    private var firstNodeName = "material_0"
    
    /// 纹理名称
    private let grainName = "Model_0.jpg"
    
    var didRender: Bool = true
    
    /// 拿到相机的节点
    @available(iOS 11.0, *)
    private var cameraNode: SCNNode? {
        return sceneView?.defaultCameraController.pointOfView
    }
    
    private var rootNode: SCNNode? {
        return sceneView?.scene?.rootNode.childNode(withName: firstNodeName, recursively: true)
    }
    
    /// debug数据, 双击显示或隐藏
    private var isHiddenDebugViews: Bool = true
    
    /// 相机开始的情况
    private var cameraTransition: SCNMatrix4 = SCNMatrix4()
    
    /// 相机焦距,根据这个值来做缩放效果
    private var minFocalLength: CGFloat = 10
    private var maxFocalLength: CGFloat = 50
    private var originFocalLength: CGFloat = 30
    private var focalLength: CGFloat = 30
    private var endFocalLength: CGFloat = 30
    
    /// 模型展示位置
    private var fromPosition = SCNVector3(x: 0, y: 320, z: 80)
    private var toPosition = SCNVector3(x: 0, y: 180, z: 80)
    
    /// 旋转角度
    private var fromRotation = SCNVector4(x: 0, y: 1, z: 0, w: Float(Double.pi))
    private var toRotation = SCNVector4(x: 0, y: 1, z: 0, w: Float(0))
    
    /// 缩放
    private var fromScale: Float = 0.4
    private var toScale: Float = 0.5
    
    /// 默认：Metal渲染 性能很好
    private(set) weak var sceneView: SCNView?
//    private lazy var sceneView = SCNView(frame: CGRect(origin: .zero, size: Device.screenSize))
    
    /// OpenGL渲染
//    private lazy var sceneView = SCNView(frame: CGRect(origin: .zero, size: Device.screenSize), options: [SCNView.Option.preferredRenderingAPI.rawValue: SCNRenderingAPI.openGLES2.rawValue])

    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupUI()
        // setupScene()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        
        rootNodeLabel.frame = CGRect(x: 12, y: 60, width: frame.width-24, height: 84)
        cameraNodeLabel.frame = CGRect(x: 12, y: 144, width: frame.width-24, height: 150)
        addSubview(rootNodeLabel)
        addSubview(cameraNodeLabel)
    }
    
    
    func setupScene() {
        
        removeTarget()
        let sceneView = SCNView(frame: CGRect(origin: .zero, size: frame.size))
        sceneView.backgroundColor = .clear
        sceneView.delegate = self
        self.sceneView = sceneView
//        scene?.rootNode.geometry = SCNSphere(radius: 1)
//        scene?.rootNode.addChildNode(omniNode)
        sceneView.scene = SCNScene(named: modelName)
        sceneView.allowsCameraControl = true
        if #available(iOS 11.0, *) {
            sceneView.defaultCameraController.interactionMode = .orbitTurntable
            sceneView.defaultCameraController.inertiaEnabled = true
        }
        
        sceneView.rendersContinuously = true
        // 默认灯光
        sceneView.autoenablesDefaultLighting = false
        // fps
        sceneView.preferredFramesPerSecond = 60
        // 抗锯齿
        sceneView.antialiasingMode = .multisampling4X
        // log
        sceneView.showsStatistics = !isHiddenDebugViews
        
        firstNodeName = sceneView.scene?.rootNode.childNodes.first?.name ?? ""

        // 渲染纹理
        let metarial = rootNode?.geometry?.materials.last
        metarial?.lightingModel = .physicallyBased
        metarial?.diffuse.contents = UIImage(named: grainName)
        metarial?.emission.contents = UIColor.black
        sceneView.scene?.rootNode.addChildNode(rootNode!)
        
        /// 灯光配置
        // 周围光
        let light1 = SCNNode()
        light1.light = SCNLight()
        light1.light?.color = UIColor.white
        light1.light?.type = .ambient
        light1.light?.intensity = 300
        light1.light?.zNear = 0
        light1.position = SCNVector3(x: 0, y: 180, z: 100)
        light1.rotation = SCNVector4(1, 0, 0, Float.pi/2.0)
        sceneView.scene?.rootNode.addChildNode(light1)

        // 定向光
        let light2 = SCNNode()
        light2.light = SCNLight()
        light2.light?.color = UIColor.white
        light2.light?.type = .directional
        light2.light?.intensity = 1200
        light2.light?.zNear = 0
        light2.position = SCNVector3(x: 0, y: 320, z: 100)
        light2.rotation = SCNVector4(-1, 0, 0, Float.pi/2.0)
        sceneView.scene?.rootNode.addChildNode(light2)

        // 设置节点位置（动画前）
        // anchorPoint
        rootNode?.pivot = SCNMatrix4MakeTranslation(0.5, 0.5, 0.5)
        rootNode?.position = fromPosition
        rootNode?.scale = SCNVector3(x: fromScale, y: fromScale, z: fromScale)
        rootNode?.rotation = fromRotation
        
        // camera参数配置
        if #available(iOS 11.0, *) {
            /// 限制缩放大小的值
            cameraNode?.camera?.zFar = 5000
            cameraNode?.camera?.zNear = 10
            
            /// 焦距
            focalLength = cameraNode?.camera?.focalLength ?? 30
            originFocalLength = focalLength
            endFocalLength = focalLength
        }
        
//        sceneView.scene?.rootNode.addChildNode(cameraNode)
//        sceneView.scene?.rootNode.addChildNode(ambientLightNode)

        /// 只需要Pan 而且单指滑动手势，禁止其它手势
        for gesture in sceneView.gestureRecognizers ?? [] {
            if let g = gesture as? UIPanGestureRecognizer {
                g.minimumNumberOfTouches = 1
                g.maximumNumberOfTouches = 1
//                g.delegate = self
            }
            else  {
                gesture.isEnabled = false
            }
        }
        
        /// 自定义缩放手势
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(onSceneViewPinch(_:)))
        pinch.delegate = self
        sceneView.addGestureRecognizer(pinch)
        
        /// 自定义pan手势
//        let pan = UIPanGestureRecognizer(target: self, action: #selector(onSceneViewPan(_:)))
//        pan.delegate = self
//        sceneView.addGestureRecognizer(pan)
        
        /// 调试工具双击隐藏或显示
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(onSceneViewDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        sceneView.addGestureRecognizer(doubleTap)
        
        addSubview(sceneView)
        didRender = false
    }
    
    public func removeTarget() {
        sceneView?.removeFromSuperview()
        sceneView = nil
    }
    
    @available(iOS 11.0, *)
    public func fadeInAnimation() {
        print("--- 3D: fadeInAnimation")

        let duration: TimeInterval = 0.56
        
        let scaleAction = SCNAction.scale(to: CGFloat(toScale), duration: duration)
        let positionAction = SCNAction.move(to: toPosition, duration: duration)
        let rotationAction = SCNAction.rotate(toAxisAngle: toRotation, duration: duration)
        let group = SCNAction.repeat(SCNAction.group([scaleAction, positionAction, rotationAction]), count: 1)
        group.duration = duration
        group.timingMode = .easeOut
        rootNode?.runAction(group, forKey: "fadeInAnim")
        
        Timer.after(duration) { [weak self] in
            self?.startAutoRotateAnimation()
        }
    }
    
    @available(iOS 11.0, *)
    private func willFadeOutAnimation() {
        
        // 清除摄像机胶卷
        sceneView?.defaultCameraController.clearRoll()
        // 停止当前的惯性
        sceneView?.defaultCameraController.stopInertia()

        let duration: TimeInterval = 0.56
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = duration
        /// 恢复相机位置
        cameraNode?.camera?.focalLength = originFocalLength
        cameraNode?.position = SCNVector3(x: cameraTransition.m41, y: cameraTransition.m42, z: cameraTransition.m43)
        cameraNode?.rotation = SCNVector4Zero
        
//        /// 恢复根节点位置
        rootNode?.rotation = toRotation
        SCNTransaction.commit()
        
        print("--- 3D: willFadeOutAnimation")
    }
    
    public func fadeOutAnimation() {
        stopAutoRotateAnimation()
        if #available(iOS 11.0, *) {
            // 调整位置再进行
            willFadeOutAnimation()
        }
        
        Timer.after(0.56) { [weak self] in
            guard let self = self else { return }
            print("--- 3D: fadeOutAnimation")
            let duration: TimeInterval = 0.56
            let scaleAction = SCNAction.scale(to: CGFloat(self.fromScale), duration: duration)
            let positionAction = SCNAction.move(to: self.fromPosition, duration: duration)
            let rotationAction = SCNAction.rotate(toAxisAngle: self.fromRotation, duration: duration)
            let group = SCNAction.repeat(SCNAction.group([scaleAction, positionAction, rotationAction]), count: 1)
            group.duration = duration
            group.timingMode = .easeOut
            self.rootNode?.runAction(group, forKey: "fadeOutAnim")
        }
    }
    
    @objc private func onSceneViewPinch(_ pinch: UIPinchGestureRecognizer) {
        if pinch.numberOfTouches < 2 {
            return
        }
        // TIPS: pinch state有时不走.end 好坑啊。
        // 得用个变量在下次开始是将上传的scale赋值给这个变量
        if pinch.state == .began {
            focalLength = endFocalLength
        }
        
        let delta = (pinch.scale - 1) * 20
        var currFocalLength = delta + focalLength
        print("currFocalLength:\(currFocalLength)")
        /// 设置最大缩放、最小缩放
        currFocalLength = min(currFocalLength, maxFocalLength)
        currFocalLength = max(currFocalLength, minFocalLength)
        
        if #available(iOS 11.0, *) {
            cameraNode?.camera?.focalLength = currFocalLength
        }
        endFocalLength = currFocalLength
    }
    
    @objc private func onSceneViewDoubleTap(_ tap: UITapGestureRecognizer) {
        let flag = !isHiddenDebugViews
        isHiddenDebugViews = flag
        
        rootNodeLabel.isHidden = flag
        cameraNodeLabel.isHidden = flag
        sceneView?.showsStatistics = !flag
    }
    
    var currentAngleX: Float = 0
    var currentAngleY: Float = 0
    
    @objc private func onSceneViewPan(_ pan: UIPanGestureRecognizer) {
        
        
        let translation = pan.translation(in: pan.view)

        var newAngleX = (Float)(translation.y)*(Float)(Float.pi)/180.0
        newAngleX += currentAngleX
        var newAngleY = (Float)(translation.x)*(Float)(Float.pi)/180.0
        newAngleY += currentAngleY

        rootNode?.eulerAngles.x = newAngleX
        rootNode?.eulerAngles.y = newAngleY

        if(pan.state == .ended) {
            currentAngleX = newAngleX
            currentAngleY = newAngleY
        }
//
//        let velocity = pan.velocity(in: sceneView)
//        let location = pan.location(in: sceneView)
//
//
//
//        var currRotation = rootNode?.rotation ?? toRotation
//        /// x：控制左右
//        currRotation.w -= (Float(velocity.x)/5000)
//        /// y: 控制上下
//        currRotation.x -= (Float(velocity.y)/5000)
//        if currRotation.w >= 2*Float.pi || currRotation.w <= -2*Float.pi {
//            currRotation.w = 0
//        }
//        if currRotation.x >= 2*Float.pi || currRotation.x <= -2*Float.pi {
//            currRotation.x = 0
//        }
//
//        rootNode?.rotation = currRotation
//        
//        FMSLog("velocity:(\(velocity.x), \(velocity.y)) location:(\(location.x), \(location.y)")
    }
    
    @objc private func onSliderChange() {
//        FMSLog("r:\(r) g:\(g) b:\(b)")
//        ambientLightNode.light?.color = UIColor.rgb(red: r, green: g, blue: b)
    }
    
    @available(iOS 11.0, *)
    func startAutoRotateAnimation() {
        print("--- 3D: startAutoRotateAnimation")
        
        // 保存相机node最初的变换
        cameraTransition = sceneView?.defaultCameraController.pointOfView?.transform ?? SCNMatrix4()
        
        /// 旋转动画
        let action = SCNAction.repeatForever(SCNAction.rotate(by: 0.5, around: SCNVector3(x: 0, y: -1, z: 0), duration: 1))
        rootNode?.runAction(action, forKey: "rotateAnim")
    }
    
    func stopAutoRotateAnimation() {
        print("--- 3D: stopAutoRotateAnimation")
        let rootNode = sceneView?.scene?.rootNode.childNode(withName: firstNodeName, recursively: true)
        rootNode?.removeAllActions()
    }
    
    
    
//    private lazy var cameraNode: SCNNode = {
//
//        let cameraNode = SCNNode()
//        cameraNode.camera = SCNCamera()
////        cameraNode.camera?.automaticallyAdjustsZRange = true
//        cameraNode.position = toPosition
//        return cameraNode
//    }()
    
//    private lazy var omniNode: SCNNode = {
//
//        let lightNode = SCNNode()
//        lightNode.light = SCNLight()
//        lightNode.light?.type = .omni
//        lightNode.position = toPosition
//        return lightNode
//    }()
    
    /// 环境光
    private lazy var ambientLightNode: SCNNode = {
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light?.type = .ambient
        ambientLightNode.light?.color = UIColor.white
        ambientLightNode.light?.castsShadow = true
        ambientLightNode.light?.shadowColor = UIColor.black.withAlphaComponent(0.5)
        ambientLightNode.light?.shadowMode = .forward
        return ambientLightNode
    }()
    
    private(set) lazy var closeBtn: UIButton = {
        var closeBtn = UIButton()
        closeBtn.setImage(UIImage(named: "base_nav_close"), for: .normal)
        return closeBtn
    }()
    
    
    private(set) lazy var rootNodeLabel: UILabel = {
        
        var titleLabel = UILabel()
        titleLabel.isHidden = isHiddenDebugViews
        titleLabel.numberOfLines = 0
        titleLabel.font = UIFont.systemFont(ofSize: 12)
        titleLabel.textColor = UIColor.black.withAlphaComponent(0.87)
        return titleLabel
    }()
    
    private(set) lazy var cameraNodeLabel: UILabel = {
        
        var titleLabel = UILabel()
        titleLabel.isHidden = isHiddenDebugViews
        titleLabel.numberOfLines = 0
        titleLabel.font = UIFont.systemFont(ofSize: 12)
        titleLabel.textColor = UIColor.black.withAlphaComponent(0.87)
        return titleLabel
    }()
}

/// 手势处理,当触碰到屏幕时，禁掉自动旋转动画

extension Detail3DSceneView: UIGestureRecognizerDelegate {
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {

        stopAutoRotateAnimation()
        
        return super.gestureRecognizerShouldBegin(gestureRecognizer)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // tips: 触摸屏幕是停止旋转

        stopAutoRotateAnimation()
        super.touchesBegan(touches, with: event)

        delegate?.onViewDidTouch(self)
    }
}

extension Detail3DSceneView: SCNSceneRendererDelegate {
    
    /// 加载场景回调
    func renderer(_ renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            /// 打印物体的坐标
            let childNode = self.sceneView?.scene?.rootNode.childNode(withName: self.firstNodeName, recursively: true)
            let position = childNode?.position ?? SCNVector3Zero
            let rotation = childNode?.rotation ?? SCNVector4Zero
            let scale = childNode?.scale ?? SCNVector3Zero
            self.rootNodeLabel.text = "模型:\n position (x):\(position.x) (y): \(position.y) (z): \(position.z) \n rotation (x):\(rotation.x) (y): \(rotation.y) (z): \(rotation.z) w:\(rotation.w) \n scale (x):\(scale.x) (y): \(scale.y) (z): \(scale.z)"
            
            /// 打印相机的坐标
            if #available(iOS 11.0, *) {
                let cameraNode = self.sceneView?.defaultCameraController.pointOfView
                let position = cameraNode?.position ?? SCNVector3Zero
                let rotation = cameraNode?.rotation ?? SCNVector4Zero
                let scale = cameraNode?.scale ?? SCNVector3Zero
                let zFar = cameraNode?.camera?.zFar ?? 0
                let zNear = cameraNode?.camera?.zNear ?? 0
                let focalLength = cameraNode?.camera?.focalLength ?? 0
                let focusDistance = cameraNode?.camera?.focusDistance ?? 0

                self.cameraNodeLabel.text = "相机:\n position (x):\(position.x) (y): \(position.y) (z): \(position.z) \n rotation (x):\(rotation.x) (y): \(rotation.y) (z): \(rotation.z) w:\(rotation.w) \n scale (x):\(scale.x) (y): \(scale.y) (z): \(scale.z) \n focalLength:\(focalLength) \n zFar:\(zFar)  zNear:\(zNear) focusDistance:\(focusDistance)"
            }
           
            
            if self.didRender || self.isHidden {
                return
            }
           
            self.didRender = true
            
            /// 执行进场动画
            Timer.after(0.24) { [weak self] in
                if #available(iOS 11.0, *) {
                    self?.fadeInAnimation()
                }
                self?.delegate?.didRenderScene()
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        //
    }
}


//extension float4x4 {
//    init(translation vector: float3) {
//        self.init(float4(1, 0, 0, 0),
//                  float4(0, 1, 0, 0),
//                  float4(0, 0, 1, 0),
//                  float4(vector.x, vector.y, vector.z, 1))
//    }
//}

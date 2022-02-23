//
//  ViewController.swift
//  ARImageTracking
//
//  Created by leejungchul on 2022/02/23.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    var heartNode:SCNNode?
    var diamondNode: SCNNode?
    var straightArrowNode: SCNNode?
    var leftTurnArrowNode: SCNNode?
    
    var imageNodes = [SCNNode]()
    var isJumping = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
        sceneView.showsStatistics = true
        sceneView.autoenablesDefaultLighting = true
        
        let heartScene = SCNScene(named: "Heart.scn")
        let diamondScene = SCNScene(named: "Diamond.scn")
        let straightArrowScene = SCNScene(named: "StraightArrow.scn")
        let leftTurnArrowScene = SCNScene(named: "LeftTurnArrow.scn")
        
        heartNode = heartScene?.rootNode
        diamondNode = diamondScene?.rootNode
        straightArrowNode = straightArrowScene?.rootNode
        leftTurnArrowNode = leftTurnArrowScene?.rootNode
        
        sceneView.debugOptions = [.showFeaturePoints, .showWorldOrigin]
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let worldConfig = ARWorldTrackingConfiguration()
        let configuration = ARImageTrackingConfiguration()
        worldConfig.planeDetection = .horizontal
        if let trackingImages = ARReferenceImage.referenceImages(inGroupNamed: "testImage", bundle: Bundle.main) {
            configuration.trackingImages = trackingImages
            configuration.maximumNumberOfTrackedImages = 4
        }
        
        sceneView.session.run(worldConfig)
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        
        let node = SCNNode()
        
        // 앵커를 이미지 앵커로 다운캐스팅
        if let imageAnchor = anchor as? ARImageAnchor {
            // 이미지들의 물리적 사이즈
            let size = imageAnchor.referenceImage.physicalSize
            // 감지된 이미지 위에 평면체 오버레이, 크기를 이미지와 맞춤
            let plane = SCNPlane(width: size.width, height: size.height)
            // 평면체의 색, 질감 조정
            plane.firstMaterial?.diffuse.contents = UIColor.brown.withAlphaComponent(0.8)
            // 평면체의 모서리 둥글게
            plane.cornerRadius = 0.005
            // 평면체의 노드 설정
            let planeNode = SCNNode(geometry: plane)
            // 평면체의 기울기 설정
            planeNode.eulerAngles.x = -.pi / 2
            node.addChildNode(planeNode)
            
            // 물체의 노드를 지정
            var shapeNode: SCNNode?
            // 이미지 인식하여 이미지의 이름에 따라 다른 노드와 매핑
            switch imageAnchor.referenceImage.name {
            case CardType.IMG_5470.rawValue:
                shapeNode = heartNode
            case CardType.IMG_5471.rawValue:
                shapeNode = diamondNode
            case CardType.airpod.rawValue:
                shapeNode = leftTurnArrowNode
            case CardType.drug.rawValue:
                shapeNode = straightArrowNode
            default:
                break
            }
            
            // 3D모델을 수평회전 시킴
            let shapeSpin = SCNAction.rotateBy(x: 0, y: 2 * .pi, z: 0, duration: 10)
            // 회전은 계속 지속시킴
            let repeatSpin = SCNAction.repeatForever(shapeSpin)
            // 노드에 회전 액션을 부여
            shapeNode?.runAction(repeatSpin)
                    
            guard let shape = shapeNode else { return nil }
            
            // 해당 노드 등록
            node.addChildNode(shape)
            
            imageNodes.append(node)
            
            return node
        }
        
        return nil
    }
    // 액션, 애니메이션 및 물리가 평가되기 전에 발생해야 하는 업데이트를 수행하도록 대리자에게 지시합니다.
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if imageNodes.count == 2 {
            let positionOne = SCNVector3ToGLKVector3(imageNodes[0].position)
            let positionTwo = SCNVector3ToGLKVector3(imageNodes[1].position)
            
            let distance = GLKVector3Distance(positionOne, positionTwo)
            
            if distance < 0.10 {
                print(" closed!!!")
                spinJump(node: imageNodes[0])
                spinJump(node: imageNodes[1])
                isJumping = true
            } else {
                isJumping = false
            }
        }
    }
    
    func spinJump(node: SCNNode) {
        if isJumping { return }
        let shapeNode = node.childNodes[1]
        
        let shapeSpin = SCNAction.rotateBy(x: 0, y: 2 * .pi, z: 0, duration: 1)
        shapeSpin.timingMode = .easeInEaseOut
        
        let up = SCNAction.moveBy(x: 0, y: 0.1, z: 0, duration: 0.5)
        up.timingMode = .easeInEaseOut
        let down = up.reversed()
        // 액션의 순서를 만듬
        let upDown = SCNAction.sequence([up, down])
        
        shapeNode.runAction(shapeSpin)
        shapeNode.runAction(upDown)
    }
    
    
    enum CardType: String {
        case IMG_5470 = "IMG_5470"
        case IMG_5471 = "IMG_5471"
        case airpod = "airpod"
        case drug = "drug"
    }
}

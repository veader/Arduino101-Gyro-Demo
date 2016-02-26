//
//  GyroSceneViewController.swift
//  BLE101
//
//  Created by Shawn Veader on 2/24/16.
//  Copyright © 2016 V8 Logic. All rights reserved.
//

import UIKit
import CoreBluetooth
import SceneKit
import Darwin

class GyroSceneViewController: UIViewController, CentralManagerDelegate {

    @IBOutlet weak var sceneView: SCNView!
    @IBOutlet weak var disconnectButton: UIBarButtonItem!
    @IBOutlet weak var coordinateButton: UIBarButtonItem!

    var arduinoBoard: SCNNode = SCNNode()
    var peripheral: CBPeripheral?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneSetup()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        CentralManager.sharedInstance.delegate = self
        if let p = peripheral {
            CentralManager.sharedInstance.connectToPeripheral(p)
        }
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        // cleanup
        disconnectFromPeripheral(self)
        CentralManager.sharedInstance.delegate = nil
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Scene
    func sceneSetup() {
        let scene = SCNScene()

        self.arduinoBoard = ArduinoBoard().board
        scene.rootNode.addChildNode(self.arduinoBoard)

        self.sceneView.scene = scene
        self.sceneView.autoenablesDefaultLighting = true
        self.sceneView.allowsCameraControl = true
    }

    // MARK: - IBAction Methods
    @IBAction func disconnectFromPeripheral(sender: AnyObject) {
        guard let p = peripheral else { return }
        CentralManager.sharedInstance.unsubscribeToGyroCharacteristics(p)
        CentralManager.sharedInstance.disconnectFromPeripheral(p)
    }

    // MARK: - CentralManager Delegate Methods
    func managerDiscoveredPeripheral(manager: CentralManager) { }

    func managerConnectedToPeripheral(peripheral: CBPeripheral, manager: CentralManager) {
        if peripheral == self.peripheral {
            self.disconnectButton.enabled = true
            // wait till we discover characteristics below to subscribe
        }
    }

    func managerDisconnectedFromPeripheral(peripheral: CBPeripheral, manager: CentralManager) {
        self.disconnectButton.enabled = false
    }

    func managerDidUpdateValueOfCharacteristic(characteristic: CBCharacteristic, manager: CentralManager) {
        let coordString = "Y: \(manager.yaw) | P: \(manager.pitch) | R: \(manager.roll)"
        self.coordinateButton.title = coordString

        let yawRads   = degressToRadians(manager.yaw)
        let rollRads  = degressToRadians(manager.roll)
        let pitchRads = degressToRadians(manager.pitch)

        SCNTransaction.begin()
        SCNTransaction.setAnimationDuration(0.5) // BLE chars update every half second...
        self.arduinoBoard.eulerAngles = SCNVector3Make(pitchRads, yawRads, rollRads)
        SCNTransaction.commit()
    }

    func managerDidUpdateCharacteristicsOfPeripheral(peripheral: CBPeripheral, manager: CentralManager) {
        CentralManager.sharedInstance.subscribeToGyroCharacteristics(peripheral)
    }

    // MARK: - Helper Methods
    func degressToRadians(degress: Float) -> Float {
        return (degress * -1) * Float(M_PI / 180)
    }
}

//
//  ArduinoBoard.swift
//  BLE101
//
//  Created by Shawn Veader on 2/24/16.
//  Copyright © 2016 V8 Logic. All rights reserved.
//

import UIKit
import SceneKit


class ArduinoBoard {
    let board: SCNNode = SCNNode()

    init() {
        setupBoard()
    }

    func setupBoard() {
        // arduino 101 is 53.4mm wide and 68.6mm long -- https://www.arduino.cc/en/Main/ArduinoBoard101
        let boardLength: CGFloat = 68.6
        let boardWidth: CGFloat = 53.4
        let boardHeight: CGFloat = 1.5

        let boardBox = SCNBox(width: boardWidth, height: boardHeight, length: boardLength, chamferRadius: 0.0)
        let boardNode = SCNNode(geometry: boardBox)
        boardNode.position = SCNVector3Make(0, 0, 0)
        self.board.addChildNode(boardNode)

        // usb connector
        let usbLength: CGFloat = 16.0
        let usbWidth: CGFloat = 12.0
        let usbHeight: CGFloat = 10.0
        let usbBox = SCNBox(width: usbWidth, height: usbHeight, length: usbLength, chamferRadius: 0.1)
        let usbNode = SCNNode(geometry: usbBox)
        // usb connector sits:
        //      - 6mm off the front edge
        //      - 9mm off the left side edge
        usbNode.position = SCNVector3Make(
            Float(0 - boardWidth/2 + usbWidth/2 + 9),
            Float(boardHeight/2 + usbHeight/2),
            Float(boardLength/2 - usbLength/2 + 6))
        self.board.addChildNode(usbNode)

        // power connector
        let powerBlockLength: CGFloat = 3.5
        let powerBlockWidth: CGFloat = 9.0
        let powerBlockHeight: CGFloat = 11.0
        let powerBlockBox = SCNBox(width: powerBlockWidth, height: powerBlockHeight, length: powerBlockLength, chamferRadius: 0.1)
        let powerBlockNode = SCNNode(geometry: powerBlockBox)
        // front of the power connector is a box that sits:
        //      - 4mm off the right edge
        //      - 1.5mm off the front edge
        powerBlockNode.position = SCNVector3Make(
            Float(boardWidth/2 - powerBlockWidth/2 - 4),
            Float(boardHeight/2 + powerBlockHeight/2),
            Float(boardLength/2 - powerBlockLength/2 + 1.5))
        self.board.addChildNode(powerBlockNode)
        let powerCylLength: CGFloat = 10.0
        let powerCylRadius: CGFloat = powerBlockWidth/2
        let powerCylinder = SCNCylinder(radius: powerCylRadius, height: powerCylLength)
        let powerCylNode = SCNNode(geometry: powerCylinder)
        // cylinder portion of power connector sits right behind the front "box"
        powerCylNode.position = SCNVector3Make(
            Float(boardLength/2 - powerBlockWidth*2 + 2),
            Float(boardHeight/2 + powerBlockHeight/2),
            Float(boardLength/2 - powerBlockLength/2 - powerCylLength/2))
        powerCylNode.eulerAngles = SCNVector3Make(1.57, 0, 0)
        self.board.addChildNode(powerCylNode)

        let headerWidth: CGFloat = 2.0
        let headerHeight: CGFloat = 9.0

        // analog header
        let analHeaderLength: CGFloat = 16.0
        let analHeaderBox = SCNBox(width: headerWidth, height: headerHeight, length: analHeaderLength, chamferRadius: 0.1)
        let analHeaderNode = SCNNode(geometry: analHeaderBox)
        // header sits:
        //      - 1.5mm off right edge
        //      - 4mm off back edge
        analHeaderNode.position = SCNVector3Make(
            Float(boardWidth/2 - headerWidth/2 - 1.5),
            Float(boardHeight/2 + headerHeight/2),
            Float(0 - boardLength/2 + analHeaderLength/2 + 4))
        self.board.addChildNode(analHeaderNode)

        // power header
        let powerHeaderLength: CGFloat = 21.0
        let powerHeaderBox = SCNBox(width: headerWidth, height: headerHeight, length: powerHeaderLength, chamferRadius: 0.1)
        let powerHeaderNode = SCNNode(geometry: powerHeaderBox)
        // power header sits:
        //      - 1.5mm off right edge
        //      - 21mm off back edge (or 2mm off analog header)
        powerHeaderNode.position = SCNVector3Make(
            Float(boardWidth/2 - headerWidth/2 - 1.5),
            Float(boardHeight/2 + headerHeight/2),
            Float(0 - boardLength/2 + powerHeaderLength/2 + 21))
        self.board.addChildNode(powerHeaderNode)

        // digital header #1 (0-7)
        let digHeader1Length: CGFloat = 21.0
        let digHeader1Box = SCNBox(width: headerWidth, height: headerHeight, length: digHeader1Length, chamferRadius: 0.1)
        let digHeader1Node = SCNNode(geometry: digHeader1Box)
        // digital header 1 sits:
        //      - 1.5mm off left edge
        //      - 4mm off back edge
        digHeader1Node.position = SCNVector3Make(
            Float(0 - boardWidth/2 + headerWidth/2 + 1.5),
            Float(boardHeight/2 + headerHeight/2),
            Float(0 - boardLength/2 + powerHeaderLength/2 + 4))
        self.board.addChildNode(digHeader1Node)

        // digital header #2 (8-13+)
        let digHeader2Length: CGFloat = 26.0
        let digHeader2Box = SCNBox(width: headerWidth, height: headerHeight, length: digHeader2Length, chamferRadius: 0.1)
        let digHeader2Node = SCNNode(geometry: digHeader2Box)
        // digital header2 sits:
        //      - 1.5mm off left edge
        //      - 28mm off back edge (or 1mm off digital header1)
        digHeader2Node.position = SCNVector3Make(
            Float(0 - boardWidth/2 + headerWidth/2 + 1.5),
            Float(boardHeight/2 + headerHeight/2),
            Float(0 - boardLength/2 + powerHeaderLength/2 + 28))
        self.board.addChildNode(digHeader2Node)
    }
}
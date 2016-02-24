//
//  PeripheralTableViewController.swift
//  BLE101
//
//  Created by Shawn Veader on 2/24/16.
//  Copyright © 2016 V8 Logic. All rights reserved.
//

import UIKit
import CoreBluetooth

class PeripheralTableViewController: UITableViewController, CentralManagerDelegate {

    var peripherals: [CBPeripheral] = [CBPeripheral]()
    var refreshTimer: NSTimer?

    @IBOutlet weak var refreshButton: UIBarButtonItem!
    @IBOutlet weak var stopButton: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        CentralManager.sharedInstance.delegate = self
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        // cleanup
        stopScan()
        CentralManager.sharedInstance.delegate = nil
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - IBAction Methods
    @IBAction func refreshPeripherals(sender: AnyObject) {
        self.refreshButton.enabled = false
        self.stopButton.enabled = true
        CentralManager.sharedInstance.startScan()

        // stop scanning after 20 seconds
        self.refreshTimer = NSTimer.scheduledTimerWithTimeInterval(20, target: self, selector: "stopScan", userInfo: nil, repeats: false)
    }

    @IBAction func stopRefresh(sender: AnyObject) {
        stopScan()
    }

    func stopScan() {
        if let timer = self.refreshTimer {
            timer.invalidate()
            self.refreshTimer = nil
        }

        self.stopButton.enabled = false
        self.refreshButton.enabled = true
        CentralManager.sharedInstance.stopScan()
    }

    // MARK: - TableView DataSource Methods
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.peripherals.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("peripheralCell", forIndexPath: indexPath)

        let peripheral = self.peripherals[indexPath.row]
        cell.textLabel!.text = peripheral.name!
        cell.detailTextLabel!.text = peripheral.identifier.UUIDString

        return cell
    }

    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let ident = segue.identifier {
            if ident == "segueGyro" {
                let dest = segue.destinationViewController as! GyroSceneViewController
                let cell = sender as! UITableViewCell
                if let indexPath = self.tableView.indexPathForCell(cell) {
                    let peripheral = self.peripherals[indexPath.row]
                    dest.peripheral = peripheral
                }
            }
        }
    }

    // MARK: - CentralManager Delegate Methods
    func managerDiscoveredPeripheral(manager: CentralManager) {
        self.peripherals = manager.peripherals
        self.tableView.reloadData()
    }

    func managerConnectedToPeripheral(peripheral: CBPeripheral, manager: CentralManager) { }

    func managerDisconnectedFromPeripheral(peripheral: CBPeripheral, manager: CentralManager) { }

    func managerDidUpdateValueOfCharacteristic(characteristic: CBCharacteristic, manager: CentralManager) { }

    func managerDidUpdateCharacteristicsOfPeripheral(peripheral: CBPeripheral, manager: CentralManager) { }

}

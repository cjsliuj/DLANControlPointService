//
//  ViewController.swift
//  Demo
//
//  Created by 刘杰 on 2018/4/19.
//  Copyright © 2018年 jerry. All rights reserved.
//

import UIKit
import DLANControlPointService
class ViewController: UIViewController,UITableViewDataSource,UITableViewDelegate,DLNAControlPointServiceDelegate {
    
    @IBOutlet weak var _tbv: UITableView!
    private var _ds: [RendererDevice] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        _tbv.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        DLNAControlPointService.share.start { (isStartAsControlPointSuccess) in
            
        }
    }
    @IBAction func onClickSearch(_ sender: Any) {
        
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return 1;
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        return cell
    }
    
    func onDeviceEvent(event: DeviceEvent, device: RendererDevice) {
        switch event {
        case .add:
            if !_ds.contains(device){
                _ds.append(device)
            }
        case .invalid, .remove:
            if let hitIndex = _ds.index(of: device){

            }
        case .update:
        }
    }
}


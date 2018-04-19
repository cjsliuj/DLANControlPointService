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
    @IBOutlet weak var _searchBtn: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        _tbv.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        //首先需要启动（将当前设备作为 Control Point这个角色）
        DLNAControlPointService.share.start { (isStartAsControlPointSuccess) in
            assert(isStartAsControlPointSuccess, "启动失败")
        }
        DLNAControlPointService.share.addDelegate(self)
    }
    @IBAction func onClickSearch(_ sender: Any) {
        _searchBtn.isEnabled = false
        _searchBtn.setTitle("正在搜索...", for: .normal)
        DLNAControlPointService.share.searchRenderDevices(timeoutInterval: 10) { [weak self] in
            self?._searchBtn.isEnabled = true
            self?._searchBtn.setTitle("开始搜索设备", for: .normal)
        }
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return _ds.count;
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = _ds[indexPath.row].friendlyName
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let device = _ds[indexPath.row]
        //这里的url 必须是个远程地址
        device.playAVWithURL(url: "http://192.168.1.2:8080/111.mp4") { (isPerformPlayActionSuccess) in
            assert(isPerformPlayActionSuccess, "播放失败")
        }
       
    }
    func onDeviceEvent(event: DeviceEvent, device: RendererDevice) {
        switch event {
        case .add:
            if !_ds.contains(device){
                _ds.append(device)
                _tbv.reloadData()
            }
        case .invalid, .remove:
            if let hitIndex = _ds.index(of: device){
                _ds.remove(at: hitIndex)
                _tbv.reloadData()
            }
        case .update:
            if let hitIndex = _ds.index(of: device){
                let oldDev = _ds[hitIndex]
                if oldDev.friendlyName != device.friendlyName{
                    _ds.replaceSubrange(hitIndex..<hitIndex+1, with: [device])
                    _tbv.reloadData()
                }
            }else{
                _ds.append(device)
                _tbv.reloadData()
            }
        }
    }
    @IBAction func onclickVolumeIncrease(_ sender: Any) {
        let device = _ds[0]
        device.getVolume { (volume: Int?) in
            print("当前音量：\(volume!)")
            device.setVolume(volume: volume! + 1, completion: { (issuc) in
                print("设置结果：\(issuc)")
            })
        }
    }
    @IBAction func onclickVolumeDecrease(_ sender: Any) {
        let device = _ds[0]
        device.getVolume { (volume: Int?) in
            print("当前音量：\(volume!)")
            device.setVolume(volume: volume! - 1, completion: { (issuc) in
                print("设置结果：\(issuc)")
            })
        }
    }
    
    deinit {
        DLNAControlPointService.share.stop()
    }
}


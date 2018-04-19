//
//  DLNAControlPointService.swift
//  DLNASample
//
//  Created by 刘杰 on 2018/4/11.
//

import Foundation
import ClinkcFramework
public class RendererDevice:NSObject{
    public init(cgRenderer: CGUpnpAvRenderer) {
        super.init()
        _cgRenderer = cgRenderer
    }
    public var udn:          String { return _cgRenderer.udn() }
    public var friendlyName: String { return _cgRenderer.friendlyName() }
    public var isPlaying:    Bool   { return _cgRenderer.isPlaying() }
    
    public var _cgRenderer: CGUpnpAvRenderer!

    override public var hash: Int{
        return self.udn.hash;
    }
    override public func isEqual(_ object: Any?) -> Bool {
        return self.udn == (object! as! RendererDevice).udn
    }
    
    public func playAVWithURL(url: String, completion: @escaping (_ isSuccess: Bool) -> Void){
        DispatchQueue.global().async {  [weak self] in
            let ret = (self?._cgRenderer.setAVTransportURI(url) ?? false) && (self?._cgRenderer.play() ?? false)
            completion(ret)
        }
    }
    
    public func play(completion: @escaping (_ isSuccess: Bool) -> Void){
        DispatchQueue.global().async {  [weak self] in
            let ret = self?._cgRenderer.play() ?? false
            completion(ret)
        }
    }
    
    public func stop(completion: @escaping (_ isSuccess: Bool)->Void){
        DispatchQueue.global().async {  [weak self] in
            let ret = self?._cgRenderer.stop() ?? false
            completion(ret)
        }
    }
    
    public func pause(completion: @escaping (_ isSuccess: Bool)->Void){
        DispatchQueue.global().async {  [weak self] in
            let ret = self?._cgRenderer.pause() ?? false
            completion(ret)
        }
    }
    
//    public func seek(completion: @escaping (_ isSuccess: Bool)->Void){
//        DispatchQueue.global().async {  [weak self] in
//            let ret = self?._cgRenderer.seek(<#T##absTime: Float##Float#>) ?? false
//            completion(ret)
//        }
//    }
     
}
@objc public protocol DLNAControlPointServiceDelegate{
    func onDeviceEvent(event: DeviceEvent, device: RendererDevice)
}

@objc public enum DeviceEvent: Int{
    case add
    case update
    case invalid
    case remove
}

public class DLNAControlPointService:NSObject, CGUpnpControlPointDelegate{
    public static let share = DLNAControlPointService()
    public var rendererDevices: [RendererDevice] = []
    private var _avCtrl: CGUpnpControlPoint!
    private var _delegates: NSHashTable<DLNAControlPointServiceDelegate> = NSHashTable<DLNAControlPointServiceDelegate>.weakObjects()
    private var _isSearching: Bool = false
    
    public func searchRenderDevices(timeoutInterval: Int, completion:@escaping ()->Void){
        if _isSearching {
            return
        }
        _isSearching = true
        _avCtrl.setSsdpSearchMX(timeoutInterval)
        _avCtrl.search(withST: "urn:schemas-upnp-org:device:MediaRenderer:1")
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(timeoutInterval)) {[weak self] in
            completion()
            self?._isSearching = false
        }
    }
    public func addDelegate(_ delegate: DLNAControlPointServiceDelegate){
        if !_delegates.contains(delegate) {
            _delegates.add(delegate)
        }
    }
    public func start(completion:@escaping (_ isSuccess: Bool) -> Void){
        if !_avCtrl.isRunning() {
            DispatchQueue.global().async { [weak self] in
                let ret = self?._avCtrl.start() ?? false
                completion(ret)
            }
        }else{
            DispatchQueue.global().async {
                completion(true)
            }
        }
    }
    @discardableResult
    public func stop() -> Bool{
        _isSearching = false
        if _avCtrl.isRunning() {
            return _avCtrl.stop()
        }else{
            return true
        }
    }
    
    public func controlPoint(_ controlPoint: CGUpnpControlPoint!, deviceAdded deviceUdn: String!) {
        _onDeviceEvent(event: .add, deviceUdn: deviceUdn)
    }
    public func controlPoint(_ controlPoint: CGUpnpControlPoint!, deviceUpdated deviceUdn: String!) {
        _onDeviceEvent(event: .update, deviceUdn: deviceUdn)
    }
    public func controlPoint(_ controlPoint: CGUpnpControlPoint!, deviceInvalid deviceUdn: String!) {
        _onDeviceEvent(event: .invalid, deviceUdn: deviceUdn)
    }
    public func controlPoint(_ controlPoint: CGUpnpControlPoint!, deviceRemoved deviceUdn: String!) {
        _onDeviceEvent(event: .remove, deviceUdn: deviceUdn)
    }
    
    private override init() {
        super.init()
        _avCtrl = CGUpnpAvController()
        _avCtrl.delegate = self;
    }
    
    private func _onDeviceEvent(event: DeviceEvent, deviceUdn: String){
        if !_isSearching {
            return;
        }
//        print("------------------");
//        let device = _avCtrl.device(forUDN: deviceUdn)!
//        
//        print("event: \(event) name: \(device.friendlyName()!) udn: \(device.udn()!) deviceType: \(device.deviceType()!)");
//        for ser: CGUpnpService in (device.services() as! [CGUpnpService]) {
//            print("serviceType: \(ser.serviceType()!)");
//        }
//        print("-+++++++++++++++++");
        let hitIdx = rendererDevices.index { (dev) -> Bool in
            return dev.udn == deviceUdn
        }
        
        let cgDevice = _avCtrl.device(forUDN: deviceUdn)!
        
        if cgDevice.getServiceForType("AVTransport:1") != nil {
            return;
        }
        
        var eventDev: RendererDevice? = nil
        switch event {
        case .add:
            if hitIdx == nil {
                let cgRenderer = CGUpnpAvRenderer.init(cObject: cgDevice.cObject)
                let  rendererDev = RendererDevice.init(cgRenderer: cgRenderer!)
                rendererDevices.append(rendererDev)
                eventDev = rendererDev
            }
        case .update:
            let cgRenderer = CGUpnpAvRenderer.init(cObject: cgDevice.cObject)
            let  rendererDev = RendererDevice.init(cgRenderer: cgRenderer!)
            if let idx = hitIdx {
                rendererDevices.remove(at: idx)
                rendererDevices.append(rendererDev)
            }else{
                rendererDevices.append(rendererDev)
            }
            eventDev = rendererDev
        case .invalid:
            if let index = hitIdx{
                eventDev = rendererDevices.remove(at: index)
            }
        case .remove:
            if let index = hitIdx{
                eventDev = rendererDevices.remove(at: index)
            }
        }
        if let dev = eventDev {
            for delegate in _delegates.objectEnumerator(){
                let dt = delegate as! DLNAControlPointServiceDelegate
                DispatchQueue.main.async {
                    dt.onDeviceEvent(event: event, device: dev)
                }
            }
        }
    }
}

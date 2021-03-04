//
//  UDPViewController.swift
//  KKSocketDemo
//
//  Created by 看影成痴 on 2021/2/25.
//

import UIKit

class UDPViewController: UIViewController, UDPSocketDelegate, GCDAsyncUdpSocketDelegate {

    @IBOutlet weak var hostTF: UITextField!
    @IBOutlet weak var portTF: UITextField!
    @IBOutlet weak var messageTF: UITextField!
    @IBOutlet weak var localPortTF: UITextField!
    @IBOutlet weak var logTV: UITextView!
    @IBOutlet weak var listenBtn: UIButton!
    
    var logStr = ""
    var bGCD = true     // 是否使用第三方库CocoaAsyncSocket
    var bListening = false
    var udpSocketServer: GCDAsyncUdpSocket?
    var udpSocketClient: GCDAsyncUdpSocket?
    var tag = 0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.hostTF.text = "255.255.255.255"
        self.portTF.text = "5000"
        self.messageTF.text = "aaa"
        self.localPortTF.text = "6000"
        
        UDPSocket.sharedInstance().delegate = self
        self.udpSocketClient = GCDAsyncUdpSocket(delegate: self, delegateQueue: .global())
        self.udpSocketServer = GCDAsyncUdpSocket(delegate: self, delegateQueue: .global())
    }
    

    @IBAction func sendAction(_ sender: Any) {

        guard let message = self.messageTF.text,
              let messageData = message.data(using: .utf8),
              let host = self.hostTF.text,
              let portStr = self.portTF.text,
              let port = UInt16(portStr)
              else {
            print("format error!")
            return
        }
        
        if bGCD {
            do {
                try self.udpSocketClient?.enableBroadcast(true)
            } catch {
                print("breadcast error")
            }
            self.udpSocketClient?.send(messageData, toHost: host, port: port, withTimeout: -1, tag: tag)
            tag += 1
        }else {
            UDPSocket.sharedInstance().send(messageData, host: host, port: port)
        }
    }
    

    @IBAction func listenAction(_ sender: Any) {
        
        guard let portStr = self.localPortTF.text,
              let port = Int32(portStr),
              port>=0 && port<65536 else {
            print("format error!")
            return
        }
        
        if self.udpSocketServer == nil {
            self.udpSocketServer = GCDAsyncUdpSocket(delegate: self, delegateQueue: .main)
        }
        
        if self.bListening  {
            
            self.bListening = false
            self.listenBtn.setTitle("Listen", for: .normal)
            
            if bGCD {
                self.udpSocketServer?.close()
                self.udpSocketServer = nil
            }else {
                UDPSocket.sharedInstance().stop()
            }

        }else {
            
            self.bListening = true
            self.listenBtn.setTitle("Stop", for: .normal)
            
            if bGCD {
                do {
                    try self.udpSocketServer?.bind(toPort: UInt16(port))
                    try self.udpSocketServer?.beginReceiving()
                } catch {
                    self.udpSocketServer?.close()
                    self.udpSocketServer = nil
                    print("bind / beginReceiving error")
                    self.bListening = false
                    self.listenBtn.setTitle("Listen", for: .normal)
                }
            }else {
                DispatchQueue.global().async {
                    UDPSocket.sharedInstance().listen(port)
                }
            }
        }
    }
    
    
    @IBAction func cleanAction(_ sender: Any) {
        
        self.logStr = ""
        self.logTV.text = ""
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        self.view.endEditing(true)
    }
    
    
    //MARK: - UDPSocketDelegate
    
    func udpSocketEvent(_ event: UDPSocketEvent, message: String) {
        DispatchQueue.main.async {
            
            self.showMessage(message)
            
            if event == .listenError {
                self.bListening = false
                self.listenBtn.setTitle("Listen", for: .normal)
            }
        }
    }
    
    
    //MARK: - GCDAsyncUdpSocketDelegate
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didConnectToAddress address: Data) {
        
        if let str = String.init(data: address, encoding: .utf8) {
            print("didConnectToAddress \(str)")
            showMessage("didConnectToAddress " + str)
        }
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didNotConnect error: Error?) {
        
        print("didNotConnect \(String(describing: error))")
        showMessage("didNotConnect " + String(describing: error))
    }

    func udpSocket(_ sock: GCDAsyncUdpSocket, didSendDataWithTag tag: Int) {
        
        DispatchQueue.main.async {
            print("send: \(self.messageTF.text!), tag: \(tag)")
            self.showMessage("send: \(self.messageTF.text!), tag: \(tag)")
        }
    }

    func udpSocket(_ sock: GCDAsyncUdpSocket, didNotSendDataWithTag tag: Int, dueToError error: Error?) {
        
        print("didNotSendDataWithTag: \(tag), error: \(String(describing: error))")
        showMessage("didNotSendDataWithTag, error: \(String(describing: error))")
    }

    func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        
        if let dataStr = String.init(data: data, encoding: .utf8) {
            print("receive: " + dataStr)
            showMessage("receive: " + dataStr)
        }
    }
    
    func udpSocketDidClose(_ sock: GCDAsyncUdpSocket, withError error: Error?) {
        
        print("error: \(String(describing: error))")
        showMessage("error: \(String(describing: error))")
    }
    
    
    //MARK: - private
    
    func showMessage(_ message: String) {
        DispatchQueue.main.async {
            self.logStr.append(message + "\r")
            self.logTV.text = self.logStr
            self.logTV.scrollRangeToVisible(NSRange(location: self.logTV.text.count, length: 1))
        }
    }
}

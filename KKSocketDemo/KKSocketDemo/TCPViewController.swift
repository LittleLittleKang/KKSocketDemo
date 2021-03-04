//
//  TCPViewController.swift
//  KKSocketDemo
//
//  Created by 看影成痴 on 2021/2/25.
//

import UIKit

enum TCPType {
    case GCD;
    case BSD;
    case stream;
}

class TCPViewController: UIViewController, StreamSocketDelegate, TCPClientDelegate, TCPServerDelegate, GCDAsyncSocketDelegate {

    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var ipTF: UITextField!
    @IBOutlet weak var portTF: UITextField!
    @IBOutlet weak var connectBtn: UIButton!
    @IBOutlet weak var messageTF: UITextField!
    @IBOutlet weak var sendBtn: UIButton!
    @IBOutlet weak var cleanBtn: UIButton!
    @IBOutlet weak var textView: UITextView!
    
    var isClientMode = true
    var isOpen = false
    var logStr = ""
    var tcpServer: GCDAsyncSocket?
    var tcpClient: GCDAsyncSocket?
    var tcpClients: [GCDAsyncSocket?]?
    
    var tcpType: TCPType = .GCD // 使用 stream socket 还是 BSD socket 还是GCD
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.ipTF.text = "0.0.0.0"
        self.portTF.text = "7000"
        self.messageTF.text = "bbb"
        self.connectBtn.setTitle("Connect", for: .normal)
        self.sendBtn.isEnabled = false
        
        StreamSocket.shared.delegate = self
        TCPClient.sharedInstance().delegate = self
        TCPServer.sharedInstance().delegate = self
        self.tcpClient = GCDAsyncSocket(delegate: self, delegateQueue: .global())
        self.tcpServer = GCDAsyncSocket(delegate: self, delegateQueue: .global())
        self.tcpClients = [GCDAsyncSocket?]()
    }
    
    
    @IBAction func segmentControlValueChanged(_ sender: Any) {
        
        if self.segmentedControl.selectedSegmentIndex == 0 {
            self.isClientMode = true
            self.connectBtn.setTitle("Connect", for: .normal)
        }else {
            self.isClientMode = false
            self.connectBtn.setTitle("Listen", for: .normal)
        }
    }
    
    
    @IBAction func connectAction(_ sender: Any) {
        
        if self.isOpen {    // 已连接
            
            if self.isClientMode {      // client mode
                
                switch tcpType {
                case .GCD:
                    self.tcpClient?.disconnect()
                    break
                case .BSD:
                    // 使用 BSD socket
                    TCPClient.sharedInstance().disconnect()
                    break
                case .stream:
                    // 使用 stream socket
                    StreamSocket.shared.close()
                    break
                }
            } else {                    // server mode
                switch tcpType {
                case .GCD:
                    // 断开客户端的连接
                    guard self.tcpClients != nil,
                          self.tcpClients!.count > 0 else {
                        break
                    }
                    for tcpClient in self.tcpClients! {
                        tcpClient?.disconnect()
                    }
                    self.tcpServer?.disconnect()
                    break
                case .BSD:
                    TCPServer.sharedInstance().stop()
                    break
                case .stream:
                    // 不支持
                    break
                }
            }
            
            self.isOpen = false
            self.sendBtn.isEnabled = false
            if self.segmentedControl.selectedSegmentIndex == 0 {
                self.connectBtn.setTitle("Connect", for: .normal)
            }else {
                self.connectBtn.setTitle("Listen", for: .normal)
            }
            self .showMessage(message: "end")
            
        }else {             // 未连接
            
            guard let host = self.ipTF.text,
                  let portStr = self.portTF.text,
                  let port = UInt32(portStr)
            else {
                print("Format error")
                self .showMessage(message: "Format error")
                return
            }
            
            if self.isClientMode {      // client mode

                switch tcpType {
                case .GCD:
                    do {
                        try self.tcpClient?.connect(toHost: host, onPort: UInt16(port))
                    } catch {
                        print("connect error")
                        return
                    }
                    break
                case .BSD:
                    DispatchQueue.global().async {
                        TCPClient.sharedInstance().connect(withHost: host, port: Int32(port))   // host:服务端IP
                    }
                    break
                case .stream:
                    StreamSocket.shared.create(host: host, port: port)
                    break
                }
                
            } else {                    // server mode
                
                switch tcpType {
                case .GCD:
                    do {
                        try self.tcpServer?.accept(onPort: UInt16(port))
                    } catch {
                        print("accept error")
                        return
                    }
                    break
                case .BSD:
                    DispatchQueue.global().async {
                        TCPServer.sharedInstance().listen(withHost: host, port: Int32(port))        // host:本机IP或者0.0.0.0
                    }
                    break
                case .stream:
                    // 不支持
                    break
                }
            }
            
            self.isOpen = true
            self.sendBtn.isEnabled = true
            self.connectBtn.setTitle("Stop", for: .normal)
        }

    }
    
    
    @IBAction func sendAction(_ sender: Any) {
        
        guard let message = self.messageTF.text, message.count > 0 else {
            print("messageTF Format error")
            self .showMessage(message: "messageTF Format error")
            return
        }
        
        if self.isClientMode {      // client mode

            switch tcpType {
            case .GCD:
                self.tcpClient?.write(message.data(using: .utf8), withTimeout: -1, tag: 0)
                break
            case .BSD:
                TCPClient.sharedInstance().send(message.data(using: .utf8)!)
                break
            case .stream:
                StreamSocket.shared.send(data: message.data(using: .utf8)!)
                break
            }
            
        } else {                    // server mode
            
            switch tcpType {
            case .GCD:
                guard self.tcpClients != nil,
                      self.tcpClients!.count > 0 else {
                    break
                }
                for tcpClient in self.tcpClients! {
                    tcpClient?.write(message.data(using: .utf8), withTimeout: -1, tag: 0)
                }
                break
            case .BSD:
                TCPServer.sharedInstance().send(message.data(using: .utf8)!)
                break
            case .stream:
                // 不支持
                break
            }
        }
    }
    
    
    @IBAction func cleanAction(_ sender: Any) {
        
        self.logStr = ""
        self .showMessage(message: self.logStr)
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        self.view.endEditing(true)
    }

    
    //MARK: - StreamSocketDelegate
    
    // 收到事件
    func eventCode(eventCode: Stream.Event) {
        
        DispatchQueue.main.async {
            
            switch eventCode {
            
                case .openCompleted:        // 打开完毕
                    print("打开完毕")
                    self.isOpen = true
                    self.connectBtn.setTitle("Stop", for: .normal)
                    self .showMessage(message: "open completed")
                    break
                    
                case .hasBytesAvailable:    // 可读
                    print("可读")
                    break
                
                case .hasSpaceAvailable:    // 可写
                    print("可写")
                    if self.sendBtn.isEnabled {
                        if let message = self.messageTF.text {
                            self.showMessage(message: "send: " + message)
                        }
                    }
                    self.sendBtn.isEnabled = true
                    break
                    
                case .errorOccurred:        // 发生错误
                    print("发生错误")
                    if self.segmentedControl.selectedSegmentIndex == 0 {
                        self.connectBtn.setTitle("Connect", for: .normal)
                    }else {
                        self.connectBtn.setTitle("Listen", for: .normal)
                    }
                    self.showMessage(message: "error!")
                    break
                    
                case .endEncountered:       // 结束
                    print("结束")
                    self.isOpen = false
                    self.sendBtn.isEnabled = false
                    if self.segmentedControl.selectedSegmentIndex == 0 {
                        self.connectBtn.setTitle("Connect", for: .normal)
                    }else {
                        self.connectBtn.setTitle("Listen", for: .normal)
                    }
                    self.showMessage(message: "end")
                    break
                    
                default:
                    break
            }
        }

    }
    
    
    // 收到数据
    func received(data: Data) {
        
        DispatchQueue.main.async {
            if let message = String.init(data: data, encoding: .utf8) {
                self.showMessage(message: "receive: " + message)
            }
        }
    }
    
    
    //MARK: - TCPClientDelegate
    func tcpClientEvent(_ event: TCPClientEvent, message: String) {
        DispatchQueue.main.async {
            self.showMessage(message: message)
            
            if event == .connected {
                self.isOpen = true
                self.connectBtn.setTitle("Stop", for: .normal)
                self.sendBtn.isEnabled = true
            }
        }
    }
    
    
    //MARK: - TCPServerDelegate
    func tcpServerEvent(_ event: TCPServerEvent, message: String) {
        DispatchQueue.main.async {
            self.showMessage(message: message)
            
            if event == .listen {
                self.isOpen = true
                self.connectBtn.setTitle("Stop", for: .normal)
            }else if event == .accept {
                self.sendBtn.isEnabled = true
            }else if event == .error {
                self.isOpen = false
                self.connectBtn.setTitle("Listen", for: .normal)
                self.sendBtn.isEnabled = false
            }
        }
    }
    
    
    //MARK: - GCDAsyncSocketDelegate
    
    func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
        
        self.tcpClients?.append(newSocket)
        newSocket.readData(withTimeout: -1, tag: 0)
        
        DispatchQueue.main.async {
            self.sendBtn.isEnabled = true
            self.showMessage(message: "newSocket" + String(describing: newSocket))
        }
    }
    
    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        
        sock.readData(withTimeout: -1, tag: 0)
        
        DispatchQueue.main.async {
            self.isOpen = true
            self.connectBtn.setTitle("Stop", for: .normal)
            self.sendBtn.isEnabled = true
            self.showMessage(message: "connected")
        }
    }

    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        
        DispatchQueue.main.async {
            if let message = String.init(data: data, encoding: .utf8) {
                self.showMessage(message: "receive: " + message)
                print("receive: " + message)
            }
        }
        
        sock.readData(withTimeout: -1, tag: 0)
    }
    
    func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        
        DispatchQueue.main.async {
            if let message = self.messageTF.text {
                self.showMessage(message: "send: " + message)
                print("send: " + message)
            }
        }
    }

    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        
        DispatchQueue.main.async {
            let message = "error: " + String(describing: err)
            self.showMessage(message: message)
            print(message)
            
            if self.isOpen {
                self.connectAction((Any).self)
            }
        }
    }

    
    //MARK: - private
    
    // 刷新textView
    func showMessage(message: String) {
        
        self.logStr.append(message + "\r")
        self.textView.text = self.logStr
        self.textView.scrollRangeToVisible(NSRange(location: self.textView.text.count, length: 1))
    }
}

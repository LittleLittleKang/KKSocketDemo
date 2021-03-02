//
//  TCPViewController.swift
//  KKSocketDemo
//
//  Created by 看影成痴 on 2021/2/25.
//

import UIKit

class TCPViewController: UIViewController, StreamSocketDelegate, TCPClientDelegate, TCPServerDelegate {

    
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
    var bStreamSocket = false   // 使用 stream socket 还是 BSD socket
    
    
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
                if self.bStreamSocket {
                    // 使用 stream socket
                    StreamSocket.shared.close()
                }else {
                    // 使用 BSD socket
                    TCPClient.sharedInstance().disconnect()
                }
            } else {                    // server mode
                TCPServer.sharedInstance().stop()
            }
            
            self.isOpen = false
            self.sendBtn.isEnabled = false
            if self.segmentedControl.selectedSegmentIndex == 0 {
                self.connectBtn.setTitle("Connect", for: .normal)
            }else {
                self.connectBtn.setTitle("Listen", for: .normal)
            }
            self.logStr.append("end" + "\r")
            self .refreshTextView(text: self.logStr)
            
        }else {             // 未连接
            
            guard let host = self.ipTF.text,
                  let portStr = self.portTF.text,
                  let port = UInt32(portStr)
            else {
                print("Format error")
                self.logStr.append("Format error" + "\r")
                self .refreshTextView(text: self.logStr)
                return
            }
            
            if self.isClientMode {      // client mode

                if self.bStreamSocket {
                    StreamSocket.shared.create(host: host, port: port)
                }else {
                    DispatchQueue.global().async {
                        TCPClient.sharedInstance().connect(withHost: host, port: Int32(port))   // host:服务端IP
                    }
                }
                
            } else {                    // server mode
                
                DispatchQueue.global().async {
                    TCPServer.sharedInstance().listen(withHost: host, port: Int32(port))        // host:本机IP或者0.0.0.0
                }
            }
        }

    }
    
    
    @IBAction func sendAction(_ sender: Any) {
        
        guard let message = self.messageTF.text, message.count > 0 else {
            print("messageTF Format error")
            self.logStr.append("messageTF Format error" + "\r")
            self .refreshTextView(text: self.logStr)
            return
        }
        
        if self.isClientMode {      // client mode

            if self.bStreamSocket {
                StreamSocket.shared.send(data: message.data(using: .utf8)!)
            }else {
                TCPClient.sharedInstance().send(message.data(using: .utf8)!)
            }
            
        } else {                    // server mode
            TCPServer.sharedInstance().send(message.data(using: .utf8)!)
        }
    }
    
    
    @IBAction func cleanAction(_ sender: Any) {
        
        self.logStr = ""
        self .refreshTextView(text: self.logStr)
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
                    self.logStr.append("open completed" + "\r")
                    self .refreshTextView(text: self.logStr)
                    break
                    
                case .hasBytesAvailable:    // 可读
                    print("可读")
                    break
                
                case .hasSpaceAvailable:    // 可写
                    print("可写")
                    if self.sendBtn.isEnabled {
                        self.logStr.append("send: " + (self.messageTF.text ?? "") + "\r")
                        self .refreshTextView(text: self.logStr)
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
                    self.logStr.append("error!" + "\r")
                    self .refreshTextView(text: self.logStr)
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
                    self.logStr.append("end" + "\r")
                    self .refreshTextView(text: self.logStr)
                    break
                    
                default:
                    break
            }
        }

    }
    
    
    // 收到数据
    func received(data: Data) {
        
        DispatchQueue.main.async {
            if let string = String.init(data: data, encoding: .utf8) {
                self.logStr.append("receive: " + string + "\r")
                self.refreshTextView(text: self.logStr)
            }
        }
    }
    
    
    //MARK: - TCPClientDelegate
    func tcpClientEvent(_ event: TCPClientEvent, message: String) {
        DispatchQueue.main.async {
            self.logStr.append(message + "\r")
            self.refreshTextView(text: self.logStr)
            
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
            self.logStr.append(message + "\r")
            self.refreshTextView(text: self.logStr)
            
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
    
    
    //MARK: - private
    
    // 刷新textView
    func refreshTextView(text: String) {
        
        self.textView.text = text
        self.textView.scrollRangeToVisible(NSRange(location: self.textView.text.count, length: 1))
    }
    
}

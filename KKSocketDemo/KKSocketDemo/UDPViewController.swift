//
//  UDPViewController.swift
//  KKSocketDemo
//
//  Created by 看影成痴 on 2021/2/25.
//

import UIKit

class UDPViewController: UIViewController, UDPSocketDelegate {

    @IBOutlet weak var hostTF: UITextField!
    @IBOutlet weak var portTF: UITextField!
    @IBOutlet weak var messageTF: UITextField!
    @IBOutlet weak var localPortTF: UITextField!
    @IBOutlet weak var logTV: UITextView!
    @IBOutlet weak var listenBtn: UIButton!
    
    var logStr = ""
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.hostTF.text = "255.255.255.255"
        self.portTF.text = "5000"
        self.messageTF.text = "aaa"
        self.localPortTF.text = "6000"
        
        UDPSocket.sharedInstance().delegate = self
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

        UDPSocket.sharedInstance().send(messageData, host: host, port: port)
    }
    

    @IBAction func listenAction(_ sender: Any) {
        
        guard let portStr = self.localPortTF.text,
              let port = Int32(portStr),
              port != 0 else {
            print("format error!")
            return
        }
        
        DispatchQueue.global().async {
            UDPSocket.sharedInstance().listen(port)
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
    func showMessage(_ message: String) {
        DispatchQueue.main.async {
            self.logStr.append(message + "\r")
            self.logTV.text = self.logStr
            self.logTV.scrollRangeToVisible(NSRange(location: self.logTV.text.count, length: 1))
        }
    }
    
}

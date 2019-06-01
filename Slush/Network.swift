//
//  Network.swift
//  River
//
//  Created by 10fu3 on 2019/05/19.
//  Copyright © 2019 10fu3. All rights reserved.
//

import Foundation
import UIKit

public class HttpClientImpl {
    
    private let session: URLSession
    
    public init(config: URLSessionConfiguration? = nil) {
        self.session = config.map { URLSession(configuration: $0) } ?? URLSession.shared
    }
    
    public func execute(request: URLRequest) -> (NSData?, URLResponse?, NSError?) {
        var d: NSData? = nil
        var r: URLResponse? = nil
        var e: NSError? = nil
        let semaphore = DispatchSemaphore(value: 0)
        session
            .dataTask(with: request) { (data, response, error) -> Void in
                d = data as NSData?
                r = response
                e = error as NSError?
                semaphore.signal()
            }
            .resume()
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        return (d, r, e)
    }
    
    public func convertImage(url:String) -> (data:Data,image:UIImage) {
        let data = getDatafromHTTP(url: url)
        return (data,UIImage(data: data) ?? UIImage())
    }
    
    public func getStringData(url:String,encode:String.Encoding)->[String]{
        let data = getDatafromHTTP(url: url)
        
        var string = String.init(data: data, encoding: encode)?.replacingOccurrences(of: "<b>", with: "")
        if((string == nil || string!.count == 0) && encode == .shiftJIS){
           string = getStringDataWithCP932(data: data).replacingOccurrences(of: "<b>", with: "")
        }
        return string?.components(separatedBy: "\n") ?? []
    }
    
    public func getStringData(url:String,encode:String.Encoding)->String{
        let data = getDatafromHTTP(url: url)
        
        var string = String.init(data: data, encoding: encode)?.replacingOccurrences(of: "<b>", with: "")
        if((string == nil || string!.count == 0) && encode == .shiftJIS){
            string = getStringDataWithCP932(data: data).replacingOccurrences(of: "<b>", with: "")
        }
        return string ?? ""
    }
    
    public func getStringDataWithCP932(data:Data)->String{
        var testArray = [UInt8]()
        for i in data{
            testArray.append(i)
            if(String(bytes: testArray, encoding: .shiftJIS) == nil){
                testArray.remove(at: testArray.count-1)
            }
        }
        return String(bytes: testArray, encoding: .shiftJIS) ?? ""
    }
    
    public func getDatafromHTTP(url:String) -> Data {
        do{
            let url = URL(string: url)!
            let req = NSMutableURLRequest(url: url)
            let (rawdata, _, _) = execute(request: (req as URLRequest))
            if rawdata != nil{
                return Data.init(referencing: rawdata ?? NSData())
            }
        }catch let err {
            return Data()
        }
        return Data()
    }
    
    func getDataByUrl(url: String) -> Data{
        let url = URL(string: url)
        do {
            let data = try Data(contentsOf: url!)
            return data
        } catch let err {
            print("Error : \(err.localizedDescription)")
        }
        return Data()
    }
}

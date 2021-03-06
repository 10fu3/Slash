//
//  ViewController.swift
//  Slush
//
//  Copyright © 2019 10fu3. All rights reserved.
//

import UIKit
import WebKit

protocol TapbleCell {
    var onCellTouch:((_ touchdedData:Int)->Void) {get set}
}

class BasicCell: UITableViewCell,TapbleCell{
    @IBOutlet weak var title: UILabel!
    var onCellTouch:((_ touchdedData:Int)->Void) = {_ in }
    
    func setData(view:SuperTable , data:SaveTypeTag) {
        self.title.text = data.title
        
        self.onCellTouch = {
            var data = view.displayView[$0]
            var nextVC:UIViewController? = nil
            DispatchQueue.global().async {
                if(data.savetype == .CATEGORY){
                    nextVC = Manager.createBoardTable(view: view, data: data)
                }else if(data.savetype == .BOARD){
                    
                    nextVC = Manager.createThreadTable(view: view, data: data, isNow: true)
                }
                //print(data.savetype)
                if(nextVC != nil){
                    DispatchQueue.main.async {
                        view.navigationController?.pushViewController(nextVC!, animated: true)
                    }
                }
            }
        }
    }
    
}

class ThreadCell: UITableViewCell,TapbleCell {
    @IBOutlet weak var title: UILabel!
    
    @IBOutlet weak var new: UIView!
    
    @IBOutlet weak var date: UILabel!
    
    @IBOutlet weak var count: UILabel!
    
    @IBOutlet weak var ikioi: UILabel!
    
    static func create() -> UITableViewCell {
        let cell = ThreadCell()
        return cell
    }
    var onCellTouch:((_ touchdedData:Int)->Void) = {_ in }
    
    func setData(view:SuperTable , data:SaveTypeTag) {
        let thread = data as! Thread
        self.title.text = data.title
        self.date.text = Parse().jpDateFormater.string(from: thread.date)
        self.ikioi.text = String(thread.getIkioi())
        self.count.text = String(thread.resCount)
        
        if thread.isSinchaku{
            self.new.backgroundColor = #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1)
        }else{
            self.new.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0)
        }
        
        self.onCellTouch = {data in
            DispatchQueue.global().async {
                let nextVC = Manager.createResTable(view: view, data: thread)
                (nextVC as? SuperTable)?.parentData = thread
                if(nextVC != nil){
                    DispatchQueue.main.async {
                        view.navigationController?.pushViewController(nextVC!, animated: true)
                    }
                }
            }
        }
    }
}

class NewResponseCell: UITableViewCell ,UITextViewDelegate,TapbleCell{
    
    // @IBOutlet weak var treespace: NSLayoutConstraint!
    var nowview:UIViewController? = nil
    
    var selfResponses:[Res] = []
    var selfData:Res = Res()
    
    @IBOutlet weak var sinchaku:UILabel!
    
    @IBOutlet weak var num: UILabel!
    
    @IBOutlet weak var body: UITextView!
    
    @IBOutlet weak var date: UILabel!
    
    @IBOutlet weak var id: UILabel!
    
    @IBOutlet weak var name: UILabel!
    
    @IBOutlet weak var treeSpace: NSLayoutConstraint!
    
    @IBOutlet weak var treeWall: UIView!
    
    var onCellTouch:((_ touchdedData:Int)->Void) = {_ in }
    
    var treeLevel = 0
    
    //@IBOutlet weak var ref: UIButton!
    func getIDColor(isWritter:Bool,count:Int) -> UIColor {
        if(isWritter){
            return #colorLiteral(red: 0.05781959732, green: 0.7647058964, blue: 0.1966328562, alpha: 1)
        }
        if count >= 3{
            return #colorLiteral(red: 1, green: 0, blue: 0.05610767772, alpha: 1)
        }else if count == 2{
            return #colorLiteral(red: 0.5568627715, green: 0.3529411852, blue: 0.9686274529, alpha: 1)
        }else if count == 1{
            return .white
        }
        return .white
    }
    
    func getAnchorColor(count:Int) -> UIColor {
        if count >= 3{
            return #colorLiteral(red: 1, green: 0, blue: 0.05610767772, alpha: 1)
        }else if count == 2{
            return #colorLiteral(red: 0.5568627715, green: 0.3529411852, blue: 0.9686274529, alpha: 1)
        }else if count == 1{
            return #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
        }else{
            return .white
        }
    }
    
    @objc func onTouchLabel(sender:UITapGestureRecognizer) {
        let touch:UILabel = (sender.view as! UILabel)
        if(touch.tag == 1){
            //print(self.selfData.writterId)
            DispatchQueue.global().async {
                let filter = SearchFilter()
                filter.searchWord = self.selfData.writterId
                filter.filter = .ID
                filter.rawRes = self.selfResponses.map{Res(cast: $0 as SaveTypeTag)}
                Manager.addCustomSearch(all:self.selfResponses , view: self.nowview!, option: filter)
            }
        }else if(touch.tag == 2){
            //print(self.selfData.num)
            DispatchQueue.global().async {
                let filter = SearchFilter()
                filter.searchNum = [self.selfData.num]
                filter.filter = .REPLY
                filter.rawRes = self.selfResponses.map{Res(cast: $0 as SaveTypeTag)}
                Manager.addCustomSearch(all:self.selfResponses ,view: self.nowview!, option: filter)
            }
        }else if(touch.tag == 3){
            //print(self.selfData.writterName)
            DispatchQueue.global().async {
                let filter = SearchFilter()
                filter.searchWord = self.selfData.writterName
                filter.filter = .NAME
                filter.rawRes = self.selfResponses.map{Res(cast: $0 as SaveTypeTag)}
                Manager.addCustomSearch(all:self.selfResponses ,view: self.nowview!, option: filter)
            }
        }
    }
    
    func create(all:[Res],data:Res,isCustomMode:Bool,nowView:UIViewController){
        //let cell = ResCell()
        self.nowview = nowView
        self.selfResponses = all
        self.selfData = data
        
        //        if(data.isSinchaku){
        //            self.sinchaku.isHidden = false
        //        }else{
        //            self.sinchaku.frame = CGRect(x: self.sinchaku.frame.origin.x, y: self.sinchaku.frame.origin.y, width: self.sinchaku.frame.width, height: 0)
        //            self.sinchaku.isHidden = true
        //        }
        
        //self.selfThread = datas
        
        let isNotIDThread = data.writterId.count == 0 ? true : false
        let isThreadFirstWritter = all[0].writterId == data.writterId
        
        var writer_now_count = isNotIDThread ? 0 : all.reduce(0, {
            if($1.num <= data.num && $1.writterId == data.writterId){
                return $0 + 1
            }else{
                return $0
            }
        })
        writer_now_count = isNotIDThread ? 0 : writer_now_count
        var write_count = all.reduce(0, {
            if($1.writterId == data.writterId){
                return $0 + 1
            }
            return $0
        })
        
        write_count = isNotIDThread ? 0 : write_count
        //print(count)
        
        let anchorCount = data.treeChildren.count
        
        let anchorCountColor = getAnchorColor(count: anchorCount)
        
        let idColor = getIDColor(isWritter: isThreadFirstWritter , count: write_count)
        
        self.body.text = data.body
        
        
        let attributedString = NSMutableAttributedString(string: data.body)
        
        self.body.linkTextAttributes = [
            NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
        ]
        
        //print(data.urls.count)
        for url in data.urls{
            var runUrl = url
            print(url)
            let range = NSString(string: attributedString.string).range(of: runUrl)
//            if(!runUrl.hasPrefix("h")){
//                runUrl = "h"+runUrl
//            }
            attributedString.addAttribute(
                NSAttributedString.Key.link,
                value: "g"+runUrl,
                range: range)
        }
        
        for i in 0..<data.toRef.count{
            //print(i.0)
            let anchor = data.toRef[i]
            let range = NSString(string: attributedString.string).range(of: anchor.0)
            attributedString.addAttribute(
                NSAttributedString.Key.link,
                value: "res://"+anchor.1.map{String($0)}.joined(separator: "/"),
                range: range)
        }
        
        self.body.attributedText = attributedString
        
        self.date.text = data.date
        
        var id = data.writterId
        if(write_count > 1 && data.writterName != ""){
            id +=  " ("+String(writer_now_count) + "/"+String(write_count) + ")"
        }
        self.id.text = id
        self.id.textColor = idColor
        self.id.tag = 1
        self.id.isUserInteractionEnabled = true
        self.id.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ResponseCell.onTouchLabel(sender:))))
        
        self.num.text = String(data.num) + (anchorCount > 0 ? "("+String(anchorCount)+")" : "")
        self.num.textColor = anchorCountColor
        self.num.tag = 2
        self.num.isUserInteractionEnabled = true
        self.num.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ResponseCell.onTouchLabel(sender:))))
        
        self.body.textColor = .white
        
        self.name.text = data.writterName
        self.name.tag = 3
        self.name.isUserInteractionEnabled = true
        self.name.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ResponseCell.onTouchLabel(sender:))))
        
        if(isCustomMode){
            if(data.treeDepth == 0){
                self.treeWall.backgroundColor = #colorLiteral(red: 0.168627451, green: 0.1675006281, blue: 0.168627451, alpha: 1)
                self.treeSpace.constant = CGFloat(4)
            }else{
                self.treeWall.backgroundColor = #colorLiteral(red: 0.9372549057, green: 0.9372549057, blue: 0.9568627477, alpha: 1)
                self.treeSpace.constant = CGFloat((10)+(Float(8) * Float(data.treeDepth-1)))
            }
        }else{
            self.treeWall.backgroundColor = #colorLiteral(red: 0.168627451, green: 0.1675006281, blue: 0.168627451, alpha: 1)
            self.treeSpace.constant = CGFloat(4)
        }
        self.body.delegate = self
    }
    
    func textView(_ textView: UITextView,shouldInteractWith url: URL,in characterRange: NSRange,interaction: UITextItemInteraction) -> Bool {
        
        //print(url)
        
        if(url.absoluteString.hasPrefix("res://")){
            //print(url)
            //print(url.absoluteString)
            DispatchQueue.global().async {
                let removedHead = url.absoluteString.replacingOccurrences(of: "res://", with: "")
                let targetAddress = removedHead.components(separatedBy: "/").map{Int($0) ?? 0}
                //removedHead.components(separatedBy: "/").map{Int($0) ?? 0}
                //print(targetAddress)
                let filter = SearchFilter()
                filter.rawRes = self.selfResponses
                filter.searchNum = targetAddress
                filter.sourceRes = self.selfData
                print(targetAddress)
                filter.filter = .ANCHOR
                
                Manager.addCustomSearch(all: self.selfResponses, view: self.nowview!, option: filter)
            }
            
        }else if(url.absoluteString.hasPrefix("ghttp")){
            DispatchQueue.global().async {
                let link = url.absoluteString.replacingOccurrences(of: "ghttp://", with: "http://").replacingOccurrences(of: "ghttps://", with: "https://").replacingOccurrences(of: "gttps://", with: "https://").replacingOccurrences(of: "gttp://", with: "http://")
                if(link.hasSuffix(".png")||link.hasSuffix(".PNG")||link.hasSuffix(".jpg")||link.hasSuffix(".JPG")||link.hasSuffix(".gif")||link.hasSuffix(".GIF")){
                    guard let nextVC = self.nowview?.storyboard?.instantiateViewController(withIdentifier: "pictureview") as? PictureView else{
                        return
                    }
                    nextVC.urlString = link
                    self.nowview?.present(nextVC, animated: true, completion: nil)
                    
                }else{
                    guard let nextVC = self.nowview?.storyboard?.instantiateViewController(withIdentifier: "webview") as? WebView else{
                        return
                    }
                    nextVC.url = link
                    self.nowview?.present(nextVC, animated: true, completion: nil)
                }
            }
            return true
        }
        return false
    }
    
}

class ResponseCell: UITableViewCell ,UITextViewDelegate,TapbleCell{
    
    // @IBOutlet weak var treespace: NSLayoutConstraint!
    var nowview:UIViewController? = nil
    
    var selfResponses:[Res] = []
    var selfData:Res = Res()
    
    @IBOutlet weak var num: UILabel!
    
    @IBOutlet weak var body: UITextView!
    
    @IBOutlet weak var date: UILabel!
    
    @IBOutlet weak var id: UILabel!
    
    @IBOutlet weak var name: UILabel!
    
    @IBOutlet weak var treeSpace: NSLayoutConstraint!
    
    @IBOutlet weak var treeWall: UIView!
    
    var onCellTouch:((_ touchdedData:Int)->Void) = {_ in }
    
    var treeLevel = 0
    
    //@IBOutlet weak var ref: UIButton!
    func getIDColor(isWritter:Bool,count:Int) -> UIColor {
        if(isWritter){
            return #colorLiteral(red: 0.05781959732, green: 0.7647058964, blue: 0.1966328562, alpha: 1)
        }
        if count >= 3{
            return #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1)
        }else if count == 2{
            return #colorLiteral(red: 0.5568627715, green: 0.3529411852, blue: 0.9686274529, alpha: 1)
        }else if count == 1{
            return .white
        }
        return .white
    }
    
    func getAnchorColor(count:Int) -> UIColor {
        if count >= 3{
            return #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1)
        }else if count == 2{
            return #colorLiteral(red: 0.5568627715, green: 0.3529411852, blue: 0.9686274529, alpha: 1)
        }else if count == 1{
            return #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
        }else if count == 0{
            return #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        }
        return #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
    }
    
    @objc func onTouchLabel(sender:UITapGestureRecognizer) {
        //タッチした座標
        //let point = sender.location(in: nowview?.view)
        
        let touch:UILabel = (sender.view as! UILabel)
        if(touch.tag == 1){
            //print(self.selfData.writterId)
            DispatchQueue.global().async {
                let filter = SearchFilter()
                filter.searchWord = self.selfData.writterId
                filter.filter = .ID
                filter.rawRes = self.selfResponses
                Manager.addCustomSearch(all:self.selfResponses , view: self.nowview!, option: filter)
            }
        }else if(touch.tag == 2){
            //print(self.selfData.num)
            DispatchQueue.global().async {
                let filter = SearchFilter()
                filter.searchNum = [self.selfData.num]
                filter.filter = .REPLY
                filter.rawRes = self.selfResponses
                Manager.addCustomSearch(all:self.selfResponses ,view: self.nowview!, option: filter)
            }
        }else if(touch.tag == 3){
            //print(self.selfData.writterName)
            DispatchQueue.global().async {
                let filter = SearchFilter()
                filter.searchWord = self.selfData.writterName
                filter.filter = .NAME
                filter.rawRes = self.selfResponses
                Manager.addCustomSearch(all:self.selfResponses ,view: self.nowview!, option: filter)
            }
        }
    }
    
    func create(all:[Res] ,data:Res,isCustomMode:Bool,nowView:UIViewController){
        //let cell = ResCell()
        self.nowview = nowView
        self.selfResponses = all
        self.selfData = data
        
        let isNotIDThread = data.writterId.count == 0 ? true : false
        let isThreadFirstWritter = all[0].writterId == data.writterId
        
        var writer_now_count = isNotIDThread ? 0 : all.reduce(0, {
            if($1.num <= data.num && $1.writterId == data.writterId){
                return $0 + 1
            }else{
                return $0
            }
        })
        writer_now_count = isNotIDThread ? 0 : writer_now_count
        var write_count = all.reduce(0, {
            if($1.writterId == data.writterId){
                return $0 + 1
            }
            return $0
        })
        
        write_count = isNotIDThread ? 0 : write_count
        //print(count)
        
        let anchorCount = data.treeChildren.count
        
        let anchorCountColor = getAnchorColor(count: anchorCount)
        
        let idColor = getIDColor(isWritter: isThreadFirstWritter , count: write_count)
        
        self.body.text = data.body
        
        
        let attributedString = NSMutableAttributedString(string: data.body)
        
        self.body.linkTextAttributes = [
            NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
        ]
        for url in data.urls{
            let runUrl = url
            let range = NSString(string: attributedString.string).range(of: runUrl)
            attributedString.addAttribute(
                NSAttributedString.Key.link,
                value: "g"+runUrl,
                range: range)
        }
        
        let matches = Pattern.anchorRegex.matches(in: data.body, options: [], range: NSMakeRange(0, data.body.count))
        
        matches.forEach { (match) -> () in
            let range = match.range(at: 1)
            let anchor = (data.body as NSString).substring(with: match.range(at: 1))
            attributedString.addAttribute(
                NSAttributedString.Key.link,
                value: "res://"+anchor,
                range: range)
        }
        
//        for i in 0..<data.toRef.count{
//            //print(i.0)
//            let anchor = data.toRef[i]
//            
//            let range = NSString(string: attributedString.string).range(of: anchor.0, options: .backwards)
//            
//            attributedString.addAttribute(
//                NSAttributedString.Key.link,
//                value: "res://"+anchor.1.map{String($0)}.joined(separator: "/"),
//                range: range)
//        }

        self.body.attributedText = attributedString
        self.date.text = data.date
        var id = data.writterId
        if(write_count > 1 && data.writterName != ""){
            id +=  " ("+String(writer_now_count) + "/"+String(write_count) + ")"
        }
        self.id.text = id
        self.id.textColor = idColor
        self.id.tag = 1
        self.id.isUserInteractionEnabled = true
        self.id.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ResponseCell.onTouchLabel(sender:))))
        
        self.num.text = String(data.num) + (anchorCount > 0 ? "("+String(anchorCount)+")" : "")
        self.num.textColor = anchorCountColor
        self.num.tag = 2
        self.num.isUserInteractionEnabled = true
        self.num.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ResponseCell.onTouchLabel(sender:))))
        
        self.body.textColor = .white
        self.name.text = data.writterName
        self.name.tag = 3
        self.name.isUserInteractionEnabled = true
        self.name.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ResponseCell.onTouchLabel(sender:))))
        if(isCustomMode){
            if(data.treeDepth == 0){
                self.treeWall.backgroundColor = #colorLiteral(red: 0.168627451, green: 0.1675006281, blue: 0.168627451, alpha: 1)
                self.treeSpace.constant = CGFloat(2)
            }else{
                self.treeWall.backgroundColor = #colorLiteral(red: 0.9372549057, green: 0.9372549057, blue: 0.9568627477, alpha: 1)
                self.treeSpace.constant = CGFloat((Float(4) * Float(data.treeDepth)))
            }
        }else{
            self.treeWall.backgroundColor = #colorLiteral(red: 0.168627451, green: 0.1675006281, blue: 0.168627451, alpha: 1)
            self.treeSpace.constant = CGFloat(2)
        }
        self.body.delegate = self
    }
    
    func textView(_ textView: UITextView,shouldInteractWith url: URL,in characterRange: NSRange,interaction: UITextItemInteraction) -> Bool {

        
        if(url.absoluteString.hasPrefix("res://")){
            DispatchQueue.global().async {
                let removedHead = url.absoluteString.replacingOccurrences(of: "res://", with: "")
                let targetAddress = removedHead.components(separatedBy: "/").map{Int($0) ?? 0}
                let filter = SearchFilter()
                filter.rawRes = self.selfResponses
                filter.searchNum = targetAddress
                filter.sourceRes = self.selfData
                print(targetAddress)
                filter.filter = .ANCHOR
                
                Manager.addCustomSearch(all: self.selfResponses, view: self.nowview!, option: filter)
            }
            
            
        }else if(url.absoluteString.hasPrefix("gttp") || url.absoluteString.hasPrefix("ghttp")){
            let link = url.absoluteString.replacingOccurrences(of: "ghttp://", with: "http://").replacingOccurrences(of: "ghttps://", with: "https://").replacingOccurrences(of: "gttps://", with: "https://").replacingOccurrences(of: "gttp://", with: "http://")
            if(link.hasSuffix(".png")||link.hasSuffix(".PNG")||link.hasSuffix(".jpg")||link.hasSuffix(".JPG")||link.hasSuffix(".gif")||link.hasSuffix(".GIF")){
                guard let nextVC = nowview?.storyboard?.instantiateViewController(withIdentifier: "pictureview") as? PictureView else{
                    return true
                }
                nextVC.urlString = link
                nowview?.present(nextVC, animated: true, completion: nil)
                
            }else{
                guard let nextVC = nowview?.storyboard?.instantiateViewController(withIdentifier: "webview") as? WebView else{
                    return true
                }
                nextVC.url = link
                nowview?.present(nextVC, animated: true, completion: nil)
            }
            return true
        }
        return false
    }
    
}

class UIStatus {
    //Managerのインデックス
    var server:Int = -1
    var bigBoards:Int = -1
    var categoryBoards:Int = -1
    var threadUrl:String = ""
    var thread:Int = -1
    var mode:UIStatusEnum = .SERVER_LIST
}

enum UIStatusEnum :String {
    case SERVER_LIST//鯖一覧
    case BOARD_LIST//板一覧
    case BOARD_FAV//お気に入り板
    case HISTORY // 履歴
    case BOARD_HIS//閲覧履歴板
    case WRITE_HIS//書込履歴
    case CATEGORY_LIST//カテゴリー一覧
    //case BIG_CATEGORY_LIST//カテゴリー一覧
    case THREAD//スレ一覧
    case THREAD_FAV//スレお気に入り
    case THREAD_HIS//スレ履歴
    case RESPONSE//レス一覧
    case RESPONSE_TREE//レスツリー
    case RESPONSE_RESULT//レス抽出検索結果
}

//検索バーを実装しているビューの抽象クラス
protocol Searchble {
    //バー本体
    var bar:UISearchBar?{get set}
    //結果表示先
    var table:UITableView? {get set}
    
}

protocol Table {
    var nextView:SuperTable? {get set}
    var backView:SuperTable? {get set}
    var tableMode:UIStatusEnum? {get set}
    var table:UITableView? { get set }
    var displayView:[SaveTypeTag]? { get set }
    var onPutData:(()->Void)?  { get set }
    var onCellTouch:((_ touchdedData:SaveTypeTag)->Void)? {get set}
    var onCellLongTouch:((_ touchdedData:SaveTypeTag)->Void)? {get set}
    var onCreateCell:((_ num:Int,_ view: SuperTable)->UITableViewCell)? {get set}
    var cellGetter: ((_ tag:String)->UITableViewCell?)? {get set}
    var onLoadedMenu: ((Int) -> Void)? {get set}
    var onMenuTouch: [((_ view:SuperTable)->Void)?] {get set}
}

class WebView :UIViewController, WKNavigationDelegate, WKUIDelegate{
    
    
    var url:String? = ""
    
    @IBOutlet weak var titleBar: UILabel!
    
    @IBOutlet weak var webview: WKWebView!
    
    @IBOutlet weak var outOfRangeBtn: UIButton!
    
    @IBOutlet weak var progressbar: UIProgressView!
    
    @IBAction func onOutOfRange(_ sender: Any) {
        self.outOfRangeBtn.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0)
        dismiss(animated: true, completion: nil)
    }
    
    
    @IBOutlet weak var back: UIButton!
    
    @IBOutlet weak var forward: UIButton!
    
    @IBOutlet weak var reload: UIButton!
    
    @IBOutlet weak var share: UIButton!
    
    @IBOutlet weak var width: NSLayoutConstraint!
    
    @IBOutlet weak var height: NSLayoutConstraint!
    
    
    @IBAction func onBack(_ sender: Any) {
        self.webview.goBack()
    }
    
    @IBAction func onForward(_ sender: Any) {
        self.webview.goForward()
    }
    
    @IBAction func onReload(_ sender: Any) {
        self.webview.reload()
        titleBar.text = self.webview.title
    }
    
    @IBAction func onShare(_ sender: Any) {
        let alert: UIAlertController = UIAlertController(title: "共有...", message: "", preferredStyle:  UIAlertController.Style.actionSheet)
        
        let openSafari: UIAlertAction = UIAlertAction(title: "Safariで開く", style: UIAlertAction.Style.default, handler:{
            (action: UIAlertAction!) -> Void in
            let openurl = URL(string: self.url ?? "")!
            if(UIApplication.shared.canOpenURL(openurl)){
                UIApplication.shared.open(openurl)
            }
        })
        let copy: UIAlertAction = UIAlertAction(title: "クリップボードにコピー", style: UIAlertAction.Style.default, handler:{
            (action: UIAlertAction!) -> Void in
            let board = UIPasteboard.general
            board.string = self.url == nil ? board.string : self.url!
        })
        
        // Cancelボタン
        let cancelAction: UIAlertAction = UIAlertAction(title: "cancel", style: UIAlertAction.Style.cancel, handler:{(action: UIAlertAction!) -> Void in})
        
        alert.addAction(openSafari)
        alert.addAction(copy)
        alert.addAction(cancelAction)
        alert.popoverPresentationController?.sourceView = self.view
        present(alert, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        //読み込み状態が変更されたことを取得
        self.webview.addObserver(self, forKeyPath: "loading", options: .new, context: nil)
        //プログレスが変更されたことを取得
        self.webview.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
        
        self.webview.load(URLRequest(url:URL(string: url ?? "")!))
        titleBar.text = self.webview.title
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
            self.outOfRangeBtn.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.350390625)
        }
        
        var request = URLRequest(url: URL(string: url ?? "")!)
        
        self.webview.load(request)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "estimatedProgress"{
            self.progressbar.setProgress(Float(self.webview.estimatedProgress), animated: true)
        }else if keyPath == "loading"{
            UIApplication.shared.isNetworkActivityIndicatorVisible = self.webview.isLoading
            if self.webview.isLoading {
                self.progressbar.setProgress(0.1, animated: true)
            }else{
                //読み込みが終わったら0に
                self.progressbar.setProgress(0.0, animated: false)
            }
        }
    }
    
    // 端末の向き変更を検知
    override func viewDidAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(self.onOrientationChange(notification:)),name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    // 向きが変わったらframeをセットしなおして再描画
    @objc func onOrientationChange(notification: NSNotification){
        //let tableContentHeight = table?.contentSize.height ?? 0
        let width = self.view.safeAreaLayoutGuide.layoutFrame.width
        let height = self.view.safeAreaLayoutGuide.layoutFrame.height
        let small = width > height ? height : width
        self.height.constant = small
        self.width.constant = small
        //self.height.constant = self.view.bounds.width
    }
    
    override func viewDidLayoutSubviews() {
        //self.view.layoutIfNeeded()
        let width = self.view.safeAreaLayoutGuide.layoutFrame.width
        let height = self.view.safeAreaLayoutGuide.layoutFrame.height
        let small = width > height ? height : width
        self.height.constant = small
        self.width.constant = small
    }
    
    deinit{
        //消さないと、アプリが落ちる
        self.webview.removeObserver(self, forKeyPath: "estimatedProgress")
        self.webview.removeObserver(self, forKeyPath: "loading")
    }
    
    
}

class PostTable :UIViewController{
    
    
    var onSend:(()->Void)? = nil
    var titleMes = ""
    var bodyMes = ""
    
    func close() {
        self.outOfRangeBtn.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0)
        dismiss(animated: true, completion: nil)
    }
    
    @objc func onClose(recognizer: UILongPressGestureRecognizer) {
        close()
    }
    
    
    
    @IBOutlet weak var titleBar: UILabel!
    
    @IBOutlet weak var threadTitle: UITextField!
    
    @IBOutlet weak var nameField: UITextField!
    
    @IBOutlet weak var mailField: UITextField!
    
    @IBOutlet weak var threadTitleHeight: NSLayoutConstraint!
    
    
    @IBOutlet weak var bodyField: UITextView!
    @IBOutlet weak var sendBtn: UIButton!
    
    @IBOutlet weak var outOfRangeBtn: UIButton!
    
    @IBAction func onOutOfRange(_ sender: Any) {
        close()
    }

    @IBAction func onSendBtn(_ sender: Any) {
        onSend?()
    }
    
    
    @IBOutlet weak var width: NSLayoutConstraint!
    @IBOutlet weak var height: NSLayoutConstraint!
    
    override func viewDidLoad() {
        bodyField.text = bodyMes
        titleBar.text = titleMes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
            self.outOfRangeBtn.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.350390625)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    // 端末の向き変更を検知
    override func viewDidAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(self.onOrientationChange(notification:)),name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    // 向きが変わったらframeをセットしなおして再描画
    @objc func onOrientationChange(notification: NSNotification){
        //let tableContentHeight = table?.contentSize.height ?? 0
        let width = self.view.safeAreaLayoutGuide.layoutFrame.width
        let height = self.view.safeAreaLayoutGuide.layoutFrame.height
        let small = width > height ? height : width
        self.height.constant = small
        self.width.constant = small
        //self.height.constant = self.view.bounds.width
    }
    
    override func viewDidLayoutSubviews() {
        //self.view.layoutIfNeeded()
        let width = self.view.safeAreaLayoutGuide.layoutFrame.width
        let height = self.view.safeAreaLayoutGuide.layoutFrame.height
        let small = width > height ? height : width
        self.height.constant = small
        self.width.constant = small
    }
    
    
}


class popupTable : UIViewController, UITableViewDelegate , UITableViewDataSource,UIGestureRecognizerDelegate{
    
    @IBOutlet weak var message: UILabel!

    //var backView: SuperTable?
    @IBOutlet weak var outofrange: UIButton!
    
    var tableMode: UIStatusEnum?
    
    @IBOutlet weak var table: UITableView?
    
    @IBOutlet weak var height: NSLayoutConstraint!
    @IBOutlet weak var width: NSLayoutConstraint!
    
    var displayView: [SaveTypeTag]?
    
    var onPutData: (() -> Void)?
    
    var onCellTouch: ((Int) -> Void)?
    
    var onCellLongTouch: ((CGPoint,CGPoint) -> Void)?
    
    //var onCreateCell: ((Int, SuperTable) -> UITableViewCell)?
    var onCreateCell: ((Int, popupTable) -> UITableViewCell)?
    
    var cellGetter: ((String) -> UITableViewCell?)?
    
    var onLoadedMenu: ((Int) -> Void)?
    
    var onMenuTouch: [((Int) -> Void)?] = []

    var displayTitle = ""

    var parentData:SaveTypeTag? = nil
    
    func close() {
        self.outofrange.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0)
        dismiss(animated: true, completion: nil)
    }
    
    @objc func onClose(recognizer: UILongPressGestureRecognizer) {
        close()
    }
    
    @IBAction func onTouchOutOfRange(_ sender: Any) {
        close()
    }

//    // 端末の向き変更を検知
//    override func viewDidAppear(_ animated: Bool) {
//        NotificationCenter.default.addObserver(self, selector: #selector(self.onOrientationChange(notification:)),name: UIDevice.orientationDidChangeNotification, object: nil)
//
//        let tableContentHeight = table?.contentSize.height ?? 0
//        let width = self.view.safeAreaLayoutGuide.layoutFrame.width
//        let height = self.view.safeAreaLayoutGuide.layoutFrame.height
//        let small = width > height ? height : width
//        if(tableContentHeight > height){
//            self.height.constant = small
//        }else{
//            self.height.constant = tableContentHeight
//        }
//        self.width.constant = small
//    }
    
    // 向きが変わったらframeをセットしなおして再描画
    @objc func onOrientationChange(notification: NSNotification){
        let tableContentHeight = table?.contentSize.height ?? 0
        let width = self.view.safeAreaLayoutGuide.layoutFrame.width
        let height = self.view.safeAreaLayoutGuide.layoutFrame.height
        let small = width > height ? height : width
        if(tableContentHeight > height){
            self.height.constant = small
        }else{
            self.height.constant = tableContentHeight
        }
        self.width.constant = small
        //self.height.constant = self.view.bounds.width
    }
    
//    private lazy var initViewLayout : Void = {
//        self.table?.setNeedsLayout()
//        self.table?.layoutIfNeeded()
//        let tableContentHeight = table?.contentSize.height ?? 0
//        let width = self.view.safeAreaLayoutGuide.layoutFrame.width
//        let height = self.view.safeAreaLayoutGuide.layoutFrame.height
//        let small = width > height ? height : width
//        if(tableContentHeight > height){
//            self.height.constant = small
//        }else{
//            self.height.constant = tableContentHeight
//        }
//        self.width.constant = small
//    }()

    override func viewDidLayoutSubviews() {
        //super.viewDidLayoutSubviews()
        self.table?.setNeedsLayout()
        self.table?.layoutIfNeeded()
        let tableContentHeight = table?.contentSize.height ?? 0
        let width = self.view.safeAreaLayoutGuide.layoutFrame.width
        let height = self.view.safeAreaLayoutGuide.layoutFrame.height
        let small = width > height ? height : width
        if(tableContentHeight > height){
            self.height.constant = small
        }else{
            self.height.constant = tableContentHeight
        }
        self.width.constant = small
    }
    
    override func viewDidLoad() {
        self.table?.delegate = self
        self.table?.dataSource = self
        self.table?.layoutMargins = UIEdgeInsets.zero
        self.table?.separatorInset = UIEdgeInsets.zero
        self.table?.rowHeight = UITableView.automaticDimension
        self.table?.estimatedRowHeight = UITableView.automaticDimension
        self.table?.backgroundView?.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(onClose(recognizer:))))
        //self.width.constant = view.safeAreaLayoutGuide.layoutFrame.width
        
        self.message.text = self.displayTitle
        
        // UILongPressGestureRecognizer宣言
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(cellLongPressed(recognizer:)))
        
        // `UIGestureRecognizerDelegate`を設定するのをお忘れなく
        longPressRecognizer.delegate = self
        
        // tableViewにrecognizerを設定
        table?.addGestureRecognizer(longPressRecognizer)
        
        cellGetter = {
            return self.table?.dequeueReusableCell(withIdentifier: $0)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
            self.outofrange.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.350390625)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayView == nil ? 0 : displayView!.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell = onCreateCell?(indexPath.row ,self)
        if(cell == nil){
            cell = table?.dequeueReusableCell(withIdentifier: "basiccell")
            cell?.textLabel?.text = "Error"
        }
        cell!.layoutMargins = UIEdgeInsets.zero
        return cell!
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        (tableView.cellForRow(at: indexPath) as? TapbleCell)?.onCellTouch(indexPath.row)
    }
    
    //TableViewの余計な線を消すやつ https://qiita.com/edm/items/db0edf4057c2e77da308
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }
    
    //長押し
    @objc func cellLongPressed(recognizer: UILongPressGestureRecognizer) {
        // 押された位置でcellのPathを取得
        let point = recognizer.location(in: self.table)
        let indexPath = self.table?.indexPathForRow(at: point)
        
        if indexPath == nil {
            // 長押し位置に対する行数が取得できなければ何もしない
        } else if recognizer.state == UIGestureRecognizer.State.began {
            onCellLongTouch?(point,recognizer.location(in: self.view))
        }
    }
}

class ResponseEditView: UIViewController {
    
    @IBOutlet weak var titleBar: UILabel!
    
    @IBOutlet weak var body: UITextView!
    
    @IBOutlet weak var outofrange: UIButton!
    
    @IBOutlet weak var width: NSLayoutConstraint!
    
    @IBOutlet weak var height: NSLayoutConstraint!
    
    var titleMes:String? = ""
    var bodyString:String? = ""
    
    override func viewDidLoad() {
        titleBar.text = titleMes ?? ""
        body.text = bodyString ?? ""
    }
    
    @IBAction func onTouchOutOfRange(_ sender: Any) {
        self.outofrange.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0)
        dismiss(animated: true, completion: nil)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    // 端末の向き変更を検知
    override func viewDidAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(self.onOrientationChange(notification:)),name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    // 向きが変わったらframeをセットしなおして再描画
    @objc func onOrientationChange(notification: NSNotification){
        //let tableContentHeight = table?.contentSize.height ?? 0
        let width = self.view.safeAreaLayoutGuide.layoutFrame.width
        let height = self.view.safeAreaLayoutGuide.layoutFrame.height
        let small = width > height ? height : width
        self.height.constant = small
        self.width.constant = small
        //self.height.constant = self.view.bounds.width
    }
    
    override func viewDidLayoutSubviews() {
        //self.view.layoutIfNeeded()
        let width = self.view.safeAreaLayoutGuide.layoutFrame.width
        let height = self.view.safeAreaLayoutGuide.layoutFrame.height
        let small = width > height ? height : width
        self.height.constant = small
        self.width.constant = small
    }
}

class PictureView: UIViewController,UIScrollViewDelegate{
    
    @IBOutlet weak var titleBar: UILabel!
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var outofrange: UIButton!
    
    @IBOutlet weak var height: NSLayoutConstraint!
    
    @IBOutlet weak var width: NSLayoutConstraint!
    
    var urlString:String? = ""
    
    override func viewDidAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(self.onOrientationChange(notification:)),name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    // 向きが変わったらframeをセットしなおして再描画
    @objc func onOrientationChange(notification: NSNotification){
        //let tableContentHeight = table?.contentSize.height ?? 0
        let width = self.view.safeAreaLayoutGuide.layoutFrame.width
        let height = self.view.safeAreaLayoutGuide.layoutFrame.height
        let small = width > height ? height : width
        self.height.constant = small
        self.width.constant = small
        //self.height.constant = self.view.bounds.width
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        updateContentInset()
    }
    
    func updateContentInset() {
        let widthInset = max((scrollView.frame.width - imageView.frame.width) / 2, 0)
        let heightInset = max((scrollView.frame.height - imageView.frame.height) / 2, 0)
        scrollView.contentInset = .init(top: heightInset,
                                        left: widthInset,
                                        bottom: heightInset,
                                        right: widthInset)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 5
        scrollView.delegate = self
        titleBar.text = "読み込み中..."
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
            self.outofrange.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.350390625)
        }
        if(urlString != nil){
            DispatchQueue.global().async {
                let data = HttpClientImpl().convertImage(url: self.urlString!)
                if(data.image != nil){
                    let urls = self.urlString!.components(separatedBy: "/")
                    DispatchQueue.main.async {
                        self.imageView?.contentMode = .scaleToFill
                        self.imageView?.image = data.image
                        self.imageView?.isUserInteractionEnabled = true
                        self.imageView?.contentMode = .scaleAspectFit
                        self.imageView?.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.350390625)
                        self.titleBar.text = urls[urls.count-1]
                    }
                }else{
                    DispatchQueue.main.async {
                        self.titleBar.text = "エラー 画像が破損しています"
                    }
                }
            }
        }
    }
    
    @IBAction func onTouchOutOfRange(_ sender: Any) {
        self.outofrange.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0)
        dismiss(animated: true, completion: nil)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}

//このクラスをコントローラーとして用いるべきではない あまりに汚い
class SuperTable: UIViewController,UITableViewDelegate,UITableViewDataSource,UIGestureRecognizerDelegate{
    
    @IBOutlet weak var progress: UIProgressView!
    
    @IBOutlet weak var table: UITableView?
    
    
    @IBOutlet weak var FirstMenu: UIButton!
    
    @IBOutlet weak var SecondMenu: UIButton!
    
    @IBOutlet weak var ThirdMenu: UIButton!
    
    @IBOutlet weak var ForthMenu: UIButton!
    
    @IBOutlet weak var FifthMenu: UIButton!
    
    @IBOutlet weak var OtherMenu: UIBarButtonItem!
    
    //もしこのビューが一番最初にロードされるものだった（ルートビュー）ら有効にするフラグ
    var isFirst:Bool = true
    
    var isAutoScroll = false
    
    var parentData:SaveTypeTag? = nil
    
    var tableMode: UIStatusEnum? = nil
    
    var displayView: [SaveTypeTag] = []
    
    var storage:[SaveTypeTag] = []
    
    var onPutData:(() -> Void)? = nil
    
    var onCreateCell: ((_ index: Int,_ view: SuperTable)->UITableViewCell)? = nil
    
    var onCellTouch: ((Int) -> Void)? = nil
    
    var onDisappearView: [(() -> Void)] = []
    
    var onCellLongTouch: ((CGPoint,CGPoint) -> Void)? = nil
    
    var cellGetter:((_ tag:String)->UITableViewCell?)? = nil
    
    var onLoadedMenu: ((Int) -> Void)? = nil
    
    var onMenuTouch: [((_ view:SuperTable)->Void)?] = [nil,nil,nil,nil,nil,nil,nil]
    
    var onMenuLongTouch: [((_ view:SuperTable)->Void)?] = [nil,nil,nil,nil,nil,nil,nil]
    
    var menuInfo :[String] = ["","","","","","",""]
    
    var onOtherMenu: (()->Void)? = nil
    
    var timer:Timer? = nil
    
    override func viewWillAppear(_ animated: Bool) {
        self.progress.progress = 0
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        onDisappearView.forEach{$0()}
    }
    
    override func viewDidLoad() {
        if(isFirst){
            Manager.manager.fistPageReqest(view:self)
        }
        
        super.viewDidLoad()
        
        table?.delegate = self
        table?.dataSource = self
        // UILongPressGestureRecognizer宣言
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(cellLongPressed(recognizer:)))
        
        self.FifthMenu.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(self.onLongBtnOf1(sender:))))
        self.SecondMenu.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(self.onLongBtnOf2(sender:))))
        self.ThirdMenu.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(self.onLongBtnOf3(sender:))))
        self.ForthMenu.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(self.onLongBtnOf4(sender:))))
        self.FifthMenu.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(self.onLongBtnOf5(sender:))))

        
        
        // `UIGestureRecognizerDelegate`を設定するのをお忘れなく
        longPressRecognizer.delegate = self
        
        
        // tableViewにrecognizerを設定
        table?.addGestureRecognizer(longPressRecognizer)
        
        self.table?.layoutMargins = UIEdgeInsets.zero
        self.table?.separatorInset = UIEdgeInsets.zero
        
        cellGetter = {
            return self.table?.dequeueReusableCell(withIdentifier: $0)
        }
        
        onPutData = {
            self.table?.reloadData()
        }
        
        //レスモードのときは上のメニューバーを閉じる
        if(tableMode != nil){
            if(tableMode! == .THREAD || tableMode!.rawValue.contains("HIS")){
                self.progress.isHidden = false
            }else{
                self.progress.isHidden = true
                if(tableMode! == .RESPONSE){
                    ToastView.showText(text: "未読"+String((displayView.count ))+"件")
                }
            }
        }
        
        FirstMenu.titleLabel?.adjustsFontSizeToFitWidth = true
        FirstMenu.setTitle(menuInfo[1], for: .normal)
        SecondMenu.titleLabel?.adjustsFontSizeToFitWidth = true
        SecondMenu.setTitle(menuInfo[2], for: .normal)
        ThirdMenu.titleLabel?.adjustsFontSizeToFitWidth = true
        ThirdMenu.setTitle(menuInfo[3], for: .normal)
        ForthMenu.titleLabel?.adjustsFontSizeToFitWidth = true
        ForthMenu.setTitle(menuInfo[4], for: .normal)
        FifthMenu.titleLabel?.adjustsFontSizeToFitWidth = true
        FifthMenu.setTitle(menuInfo[5], for: .normal)
        
        
        //Navigational
        let label = UILabel(frame: CGRect(x:0, y:0, width:400, height:50))
        label.backgroundColor = .clear
        label.numberOfLines = 0
        label.adjustsFontSizeToFitWidth = true
        label.font = UIFont.boldSystemFont(ofSize: 16.0)
        label.textAlignment = .center
        label.textColor = .white
        label.text = self.navigationItem.title
        
        self.navigationItem.titleView = label
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayView.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = onCreateCell?(indexPath.row ,self)
        if(cell == nil){
            cell = table?.dequeueReusableCell(withIdentifier: "basiccell")
            cell?.textLabel?.text = "エラー"
        }
        cell!.layoutMargins = UIEdgeInsets.zero
        return cell!
    }
    
    //長押し
    @objc func cellLongPressed(recognizer: UILongPressGestureRecognizer) {
        // 押された位置でcellのPathを取得
        let point = recognizer.location(in: self.table)
        let indexPath = self.table?.indexPathForRow(at: point)
        
        if indexPath == nil {
            // 長押し位置に対する行数が取得できなければ何もしない
        } else if recognizer.state == UIGestureRecognizer.State.began {
            onCellLongTouch?(point,recognizer.location(in: self.view))
        }
    }
    //TableViewの余計な線を消すやつ https://qiita.com/edm/items/db0edf4057c2e77da308
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }
    
    //セルがタップされたとき
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        (tableView.cellForRow(at: indexPath) as? TapbleCell)?.onCellTouch(indexPath.row)
    }
    
    
    @IBAction func onBtnOf1(_ sender: Any) {
        onMenuTouch[1]?(self)
    }
    
    @IBAction func onBtnOf2(_ sender: Any) {
        onMenuTouch[2]?(self)
    }
    
    @IBAction func onBtnOf3(_ sender: Any) {
        onMenuTouch[3]?(self)
    }
    
    @IBAction func onBtnOf4(_ sender: Any) {
        onMenuTouch[4]?(self)
    }
    
    @IBAction func onBtnOf5(_ sender: Any) {
        onMenuTouch[5]?(self)
    }
    
    
    @objc func onLongBtnOf1(sender: UILongPressGestureRecognizer) {
        if(sender.state == UIGestureRecognizer.State.ended){
            onMenuLongTouch[1]?(self)
        }
    }
    @objc func onLongBtnOf2(sender: UILongPressGestureRecognizer) {
        if(sender.state == UIGestureRecognizer.State.ended){
            onMenuLongTouch[2]?(self)
        }
    }
    @objc func onLongBtnOf3(sender: UILongPressGestureRecognizer) {
        if(sender.state == UIGestureRecognizer.State.ended){
            onMenuLongTouch[3]?(self)
        }
    }
    @objc func onLongBtnOf4(sender: UILongPressGestureRecognizer) {
        if(sender.state == UIGestureRecognizer.State.ended){
            onMenuLongTouch[4]?(self)
        }
    }
    @objc func onLongBtnOf5(sender: UILongPressGestureRecognizer) {
        if(sender.state == UIGestureRecognizer.State.ended){
            onMenuLongTouch[5]?(self)
        }
    }
    
    @IBAction func onOtherMenu(_ sender: Any) {
        onOtherMenu?()
    }
    
}


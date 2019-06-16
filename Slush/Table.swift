//
//  ViewController.swift
//  Slush
//
//  Copyright © 2019 10fu3. All rights reserved.
//

import UIKit
import SafariServices

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
        
        
        for url in Pattern().getUrlLink(data: data.body){
            var runUrl = url
            let range = NSString(string: attributedString.string).range(of: runUrl)
            if(!runUrl.hasPrefix("h")){
                runUrl = "h"+runUrl
            }
            attributedString.addAttribute(
                NSAttributedString.Key.link,
                value: runUrl,
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
        
        self.date.text = Parse().jpDateFormater.string(from: data.date)
        
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
                self.treeSpace.constant = CGFloat((Float(8) * Float(data.treeDepth)))
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
            
            
        }else if(url.absoluteString.hasPrefix("http")){
            //let controller = SFSafariViewController(url: url)
            //self.nowview?.present(controller, animated: true)
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
        }else if count == 0{
            return #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        }
        return #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
    }
    
    @objc func onTouchLabel(sender:UITapGestureRecognizer) {
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
        
        
        for url in Pattern().getUrlLink(data: data.body){
            var runUrl = url
            let range = NSString(string: attributedString.string).range(of: runUrl)
            if(!runUrl.hasPrefix("h")){
                runUrl = "h"+runUrl
            }
            attributedString.addAttribute(
                NSAttributedString.Key.link,
                value: runUrl,
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
        
        self.date.text = Parse().jpDateFormater.string(from: data.date)
        
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
            
            
        }else if(url.absoluteString.hasPrefix("http")){
            //let controller = SFSafariViewController(url: url)
            //self.nowview?.present(controller, animated: true)
            return true
        }
        return false
    }
    
}

class EndCell: UITableViewCell {
    static func create() -> UITableViewCell {
        let cell = EndCell()
        return cell
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

enum UIStatusEnum {
    case SERVER_LIST//鯖一覧
    case BOARD_LIST//板一覧
    case BOARD_FAV//お気に入り板
    case BOARD_HIS//閲覧履歴板
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

class postTable :UIViewController{
    
    
    var titleMes = ""
    var bodyMes = ""
    
    @IBOutlet weak var titleBar: UILabel!

    @IBOutlet weak var nameField: UITextField!
    
    @IBOutlet weak var mailField: UITextField!
    
    @IBOutlet weak var bodyField: UITextView!
    @IBOutlet weak var sendBtn: UIButton!
    
    @IBOutlet weak var outOfRangeBtn: UIButton!
    
    @IBAction func onOutOfRange(_ sender: Any) {
        self.outOfRangeBtn.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0)
        dismiss(animated: true, completion: nil)
    }
    
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
    
    
    
}


class popupTable : UIViewController, UITableViewDelegate , UITableViewDataSource,UIGestureRecognizerDelegate{
    
    @IBOutlet weak var message: UILabel!

    //var backView: SuperTable?
    @IBOutlet weak var outofrange: UIButton!
    
    var tableMode: UIStatusEnum?
    
    @IBOutlet weak var table: UITableView?
    
    
    @IBOutlet weak var height: NSLayoutConstraint!
    
    var displayView: [SaveTypeTag]?
    
    var onPutData: (() -> Void)?
    
    var onCellTouch: ((Int) -> Void)?
    
    var onCellLongTouch: ((Int) -> Void)?
    
    //var onCreateCell: ((Int, SuperTable) -> UITableViewCell)?
    var onCreateCell: ((Int, popupTable) -> UITableViewCell)?
    
    var cellGetter: ((String) -> UITableViewCell?)?
    
    var onLoadedMenu: ((Int) -> Void)?
    
    var onMenuTouch: [((Int) -> Void)?] = []

    var displayTitle = ""

    var parentData:SaveTypeTag? = nil
    
    @IBAction func onTouchOutOfRange(_ sender: Any) {
        self.outofrange.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0)
        dismiss(animated: true, completion: nil)
    }

    override func viewDidLayoutSubviews() {
        self.view.layoutIfNeeded()
        if(table?.contentSize.height ?? 0 < table?.frame.size.width ?? 0){
            //            print(table?.contentSize.height ?? 0)
            //            print(table?.frame.size.width)
            self.height?.constant = self.table?.contentSize.height ?? 40
            
            //self.table?.isScrollEnabled = false
            //table?.isScrollEnabled = false
        }else{
            self.height?.constant = self.view.bounds.width
        }
    }
    
    override func viewDidLoad() {
        self.table?.delegate = self
        self.table?.dataSource = self
        self.table?.layoutMargins = UIEdgeInsets.zero
        self.table?.separatorInset = UIEdgeInsets.zero
        self.table?.rowHeight = UITableView.automaticDimension
        self.table?.estimatedRowHeight = UITableView.automaticDimension
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
        //cellheight += cell?.contentView.bounds.height ?? 0
        //print(cellheight)
        
        //変更したで
//        if(indexPath.row == (displayView?.count ?? 0)-1){
//            //print(cellheight)
//            if(table?.contentSize.height ?? 0 < table?.frame.size.width ?? 0){
//
//                height.constant = tableView.contentSize.height
//
//            }
//        }
        
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
            onCellLongTouch?(indexPath!.row)
        }
    }
}

class ResponseEditView: UIViewController {
    
    @IBOutlet weak var titleBar: UILabel!
    
    @IBOutlet weak var body: UITextView!
    
    @IBOutlet weak var outofrange: UIButton!
    
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
    //ここまでが対象
    
    //もしこのビューが一番最初にロードされるものだった（ルートビュー）ら有効にするフラグ
    var isFirst:Bool = true
    
    var parentData:SaveTypeTag? = nil
    
    var tableMode: UIStatusEnum? = nil
    
    var displayView: [SaveTypeTag] = []
    
    var storage:[SaveTypeTag] = []
    
    var onPutData:(() -> Void)? = nil
    
    var onCreateCell: ((_ index: Int,_ view: SuperTable)->UITableViewCell)? = nil
    
    var onCellTouch: ((Int) -> Void)? = nil
    
    var onCellLongTouch: ((Int) -> Void)? = nil
    
    var cellGetter:((_ tag:String)->UITableViewCell?)? = nil
    
    var onLoadedMenu: ((Int) -> Void)? = nil
    
    var onMenuTouch: [((_ view:SuperTable)->Void)?] = [nil,nil,nil,nil,nil,nil,nil]
    
    var onMenuLongTouch: [((_ view:SuperTable)->Void)?] = [nil,nil,nil,nil,nil,nil,nil]
    
    var menuInfo :[String] = ["","","","","","",""]
    
    override func viewWillAppear(_ animated: Bool) {
        self.progress.progress = 0
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
            if(tableMode! == .THREAD){
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
        //print(indexPath.row)
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
            onCellLongTouch?(indexPath!.row)
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
    
    
    @IBAction func onLongBtnOf1(_ sender: Any) {
        onMenuLongTouch[1]?(self)
    }
    @IBAction func onLongBtnOf2(_ sender: Any) {
        onMenuLongTouch[2]?(self)
    }
    @IBAction func onLongBtnOf3(_ sender: Any) {
        onMenuLongTouch[3]?(self)
    }
    @IBAction func onLongBtnOf4(_ sender: Any) {
        onMenuLongTouch[4]?(self)
    }
    @IBAction func onLongBtnOf5(_ sender: Any) {
        onMenuLongTouch[5]?(self)
    }
}


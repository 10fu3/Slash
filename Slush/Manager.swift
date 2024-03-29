//
//  Manager.swift
//  River
//
//  Created by 10fu3 on 2019/05/19.
//  Copyright © 2019 10fu3. All rights reserved.
//

import Foundation
import UIKit


class SearchFilter {
    var sourceRes: Res? = nil
    var rawRes = [Res]()
    var searchWord = ""
    var searchNum = [Int]()
    var filter = Filter.NONE
    func search() -> [Res] {
        var response = [Res]()
        switch(filter){
            case .NAME:
                response = rawRes.filter{$0.writterName == searchWord}
            case .ID:
                response = rawRes.filter{$0.writterId == searchWord}
            //対象のレス番を探す
            case .ANCHOR:
                var values = [Res]()
                for i in 0..<searchNum.count{
                    for res in (rawRes.filter{$0.num == searchNum[i]}){
                        if(!values.contains{$0.num == res.num}){
                            values.append(res)
                        }
                    }
                }
                return values
            case .MANY_RES:
                let writters = NSOrderedSet(array: rawRes.map{$0.writterId}).map {$0}
                for anywritter in writters{
                    let writter = anywritter as! String
                    let writterRess = rawRes.filter{$0.writterId == writter}
                    if(writterRess.count > 0){
                        writterRess.forEach{response.append($0)}
                    }
                }
            
            case .PICTURE_RES:
                response = rawRes.filter{$0.pictureURL.count > 0}
            case .MOVIE_RES:
                response = rawRes.filter{$0.movieURL.count > 0}
            case .NOT_PICTURE_AND_MOVIE_URL:
                return []
            case .SELF_KAKIKO:
                return []
            //返信を見る
            case .REPLY:
                //let num = self.searchNum[0]
                var values :[Res] = []
                for i in rawRes{
                    if(i.num) == searchNum[0]{
                        for resIndex in i.treeChildren{
                            values.append(rawRes[resIndex-1])
                        }
                    }
                }
                return values
            case .POPULAR:
                response = rawRes.filter{$0.treeChildren.count > 0}
            case .NONE:
                return []
        }
        return response
    }
    
    enum Filter {
        case NAME
        case ID
        case ANCHOR
        case MANY_RES
        case PICTURE_RES
        case MOVIE_RES
        case NOT_PICTURE_AND_MOVIE_URL
        case SELF_KAKIKO
        case REPLY
        case POPULAR
        case NONE
    }
}

class Manager {
    static let manager = Manager()
    
    //let realm:Realm
    var downloadedData = [Server]()
    
    var views = [SuperTable]()
    
    init() {
//        var config = Realm.Configuration()
//        config.deleteRealmIfMigrationNeeded = true
//        realm = try! Realm(configuration: config)
    }

//    static func createServerTable(view:SuperTable,data:SaveTypeTag) -> UIViewController? {
//        //サーバーのセルがタップされたとき
//
//        let server = data as! Server
//        let category = server.bigcategory
//
//        let nextVC = view.storyboard?.instantiateViewController(withIdentifier: "table") as? SuperTable
//        nextVC?.isFirst = false
//        nextVC?.displayView = category
//        nextVC?.onCreateCell = { (i:Int,v:SuperTable) in
//            let cell = v.cellGetter!("basiccell") as! BasicCell
//            cell.setData(view: v, data: category[i])
//            return cell
//        }
//        return nextVC
//    }
    
    static func createCategoryTable(view:SuperTable,data:SaveTypeTag) -> UIViewController? {
    
        let server = data as! Server
        let category = server.bigcategory

        let nextVC = view.storyboard?.instantiateViewController(withIdentifier: "table") as? SuperTable
        nextVC?.isFirst = false
        nextVC?.displayView = category
        nextVC?.storage = category
        nextVC?.parentData = server
        nextVC?.tableMode = .CATEGORY_LIST
        nextVC?.onCreateCell = { (i:Int,v:SuperTable) in
            let cell = v.cellGetter!("basiccell") as! BasicCell
            cell.setData(view: v, data: category[i])
            return cell
        }
        nextVC?.onOtherMenu = {
            nextVC?.navigationController?.pushViewController(Manager.createHistoryTable(view: nextVC!)!, animated: true)
        }
        nextVC?.navigationItem.title = server.title
        return nextVC
    }
    
    static func createBoardTable(view:SuperTable,data:SaveTypeTag) -> UIViewController? {
        
        let category = data as! Category
        let board = category.boards
        
        let nextVC = view.storyboard?.instantiateViewController(withIdentifier: "table") as? SuperTable
        nextVC?.isFirst = false
        nextVC?.displayView = board
        nextVC?.parentData = category
        nextVC?.storage = board
        nextVC?.tableMode = .BOARD_LIST
        nextVC?.onCreateCell = { (i:Int,v:SuperTable) in
            let cell = v.cellGetter!("basiccell") as! BasicCell
            cell.setData(view: v, data: board[i])
            return cell
        }
        nextVC?.onOtherMenu = {
            nextVC?.navigationController?.pushViewController(Manager.createHistoryTable(view: nextVC!)!, animated: true)
        }
        nextVC?.navigationItem.title = category.title
        return nextVC
    }
    
    static func createThreadTable(view:SuperTable,data:SaveTypeTag,isNow:Bool) -> UIViewController? {
        //サーバーのセルがタップされたとき
        let board = data as! Board
        
        //var thread = isNow ? board.nowThread : board.cache
        
        if(board.cache.count > 0){
            
        }else{
            //print(board.url)
            //Realmに対して追加処理を忘れない〜
            let getthreads = Parse().getThreads(boardUrl: board.url).nowThread
            
            board.cache = getthreads
            board.nowThread = board.cache
        }
        
        let nextVC = view.storyboard?.instantiateViewController(withIdentifier: "table") as? SuperTable
        nextVC?.isFirst = false
        nextVC?.storage = board.nowThread
        
        //TODO: NG機能を検討する際は下の行を変更する
        nextVC?.displayView = board.nowThread
        
        nextVC?.tableMode = .THREAD
        
        //board.nowThread = Parse().getThreads(boardUrl: board.url).nowThread
        nextVC?.onCreateCell = { (i:Int,v:SuperTable) in
            //print("A")
            let cell = v.cellGetter!("threadcell")
            let threadcell = cell as! ThreadCell
            threadcell.setData(view: v, data: nextVC!.displayView[i])
            threadcell.title.numberOfLines = 0
            return cell!
        }
        
        nextVC?.menuInfo[3] = "更新"
        nextVC?.onMenuTouch[3] = { view in
            DispatchQueue.global().async {
                //nextVC?.displayView = []
                //新着ラベルをつけるための処理
                //一覧取得
                let getthreads = Parse().getThreads(boardUrl: board.url).nowThread
                //すでにテーブルにセット済みのデータ
                let nowGetThreads:[Thread] = nextVC?.displayView as! [Thread]
                //すでにテーブルにセット済みのスレッド配列からIDだけ抽出した配列
                let nowGetThreadIDs = nowGetThreads.map{$0.id}
                
                //その配列にダウンロードしたスレ一覧のIDが存在しなければ新着フラグを立てる
                getthreads.filter{!nowGetThreadIDs.contains($0.id)}.forEach{$0.isSinchaku = true}
                
                //あとはセットする このとき中身が空だったらもう知らない　おそらくCP932関連のエンコードエラー
                nextVC?.storage = getthreads
                
                //
                nextVC?.displayView = nextVC?.storage.map{$0} ?? []
                
                DispatchQueue.main.async {
                    nextVC?.table?.reloadData()
                }
            }
            
            //nextVC?.displayView = []
            
            //nextVC?.displayView = board.cache
        }
        
        nextVC?.menuInfo[1] = "新着"
        nextVC?.onMenuTouch[1] = { view in
            DispatchQueue.global().async {
                let array = nextVC?.storage.sorted(by: { (a, b) -> Bool in
                    //未来になぜかスレが立ってる場合は除外
                    if !(((a as! Thread).date) > Date()){
                        return (a as! Thread).date > (b as! Thread).date
                    }else{
                        return false
                    }
                }) ?? []
                
                
                DispatchQueue.main.async {
                    nextVC?.displayView = []
                    nextVC?.displayView = array
                    nextVC?.table?.reloadData()
                }
            }
            
        }
        
        nextVC?.menuInfo[2] = "勢い"
        nextVC?.onMenuTouch[2] = { view in
            DispatchQueue.global().async {
                let array = nextVC?.storage.sorted{
                    Float(($0 as! Thread).getIkioi()) > ($1 as! Thread).getIkioi()
                    } ?? []
                
                DispatchQueue.main.async {
                    nextVC?.displayView = []
                    nextVC?.displayView = array
                    nextVC?.table?.reloadData()
                }
            }
        }
        
        nextVC?.menuInfo[5] = "スレ建て"
        nextVC?.onMenuTouch[5] = { data in
            popupPostMenu(view: nextVC!, data: [board], index: nil, isInyou: false)
        }
        nextVC?.onOtherMenu = {
            nextVC?.navigationController?.pushViewController(Manager.createHistoryTable(view: nextVC!)!, animated: true)
        }
        
        nextVC?.navigationItem.title = board.title
        
        
        return nextVC
    }
    
    static func addCustomSearch(all:[Res], view:UIViewController,option:SearchFilter) {
        var result = option.search()
        var title = ""
        let nextVC = view.storyboard?.instantiateViewController(withIdentifier: "custom") as? popupTable
        switch option.filter{
        case .NAME:
            title += "名前: "+option.searchWord
        case .ID:
            title += "ID: "+option.searchWord
        case .ANCHOR:
            title += "レス番 "+result.map{String($0.num)}.joined(separator: " ")
        case .MANY_RES:
            title += "発言数の多いIDの抽出結果"
        case .PICTURE_RES:
            title += "画像URLつきレスの検索結果"
        case .MOVIE_RES:
            title += "動画URLつきレスの検索結果"
        case .NOT_PICTURE_AND_MOVIE_URL:
            title += "URLかつ非動画像つきレスの検索結果"
        case .SELF_KAKIKO:
            title += "自分の書き込み"
        case .REPLY:
            title += ">>"+String(option.searchNum[0])+" への返信"
            
        case .POPULAR:
            title += "人気レスの抽出結果"
        case .NONE:
            title += "ERROR"
        }
        nextVC?.displayTitle = title+" ["+String(result.count)+"件]"
        nextVC?.displayView = result
        nextVC?.onCreateCell = { (i:Int,v:popupTable) in
            let cell = v.cellGetter!("rescell")
            let threadcell = cell as! ResponseCell
            threadcell.create(all: all, data: result[i], isCustomMode: false, nowView: v)
            return cell!
        }
        
        nextVC?.onCellLongTouch = { (cellPoint:CGPoint,touch:CGPoint) in
            let indexPath = nextVC?.table?.indexPathForRow(at: cellPoint)
            if(indexPath != nil){
                popupLongCellTouch(view: nil, custom: nextVC!, data: nextVC?.displayView ?? [], index: indexPath!.row, point: touch)
            }
        }
        
        if(nextVC != nil){
            if(option.filter == .ID && result.count <= 1){
                return
            }else{
                if(result.count > 0){
                    DispatchQueue.main.async {
                        view.present(nextVC!, animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
    static func createHistoryTable(view:SuperTable) -> UIViewController? {
        let nextVC = view.storyboard?.instantiateViewController(withIdentifier: "table") as? SuperTable
        nextVC?.isFirst = false
        nextVC?.tableMode = .BOARD_HIS
        nextVC?.navigationItem.title = "閲覧 板"
        nextVC?.progress?.isHidden = true
        
        nextVC?.menuInfo = ["","お気に入り","閲覧履歴","更新","書込履歴","並び順",""]
        
        return nextVC
    }
    
    static func createResTable(view:SuperTable,data:SaveTypeTag) -> UIViewController? {
        //サーバーのセルがタップされたとき
        var thread = data as! Thread
        var nextVC = view.storyboard?.instantiateViewController(withIdentifier: "table") as? SuperTable

        
        
        
        thread = Parse().getThread(thread: thread, onDownload: {
            DispatchQueue.main.async {
               var _ =  ToastView.showText(text: "ダウンロード開始")
            }
        }, onParse: { part,all in
            DispatchQueue.main.async {
                view.progress?.progress = Float(part)/Float(all)
                //print(Float(part)/Float(all))
            }
        }, onError: {
            DispatchQueue.main.async {
                let alert: UIAlertController = UIAlertController(title: "読み込みエラー", message: "オフラインの可能性があります", preferredStyle:  UIAlertController.Style.alert)
                
                let defaultAction: UIAlertAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler:{
                    // ボタンが押された時の処理を書く（クロージャ実装）
                    (action: UIAlertAction!) -> Void in
                    nextVC = nil
                })
                alert.addAction(defaultAction)
                view.present(alert, animated: true, completion: nil)
            }
        })
        
        nextVC?.isFirst = false
        nextVC?.tableMode = .RESPONSE
        DispatchQueue.main.async {
            var _ = ToastView.showText(text: "読み込み中...")
        }
        nextVC?.storage = thread.res.map{$0}
        nextVC?.displayView = thread.res.map{$0}
        nextVC?.parentData = thread
        nextVC?.onCreateCell = { (i:Int,v:SuperTable) in
            
            let cell = v.cellGetter!("rescell")
            let threadcell = cell as! ResponseCell
            threadcell.create(all: nextVC?.storage as! [Res], data: nextVC?.storage[i] as! Res, isCustomMode: false, nowView: v)
            
            return cell!
        }
        nextVC?.onCellLongTouch = {(cellPoint:CGPoint,touch:CGPoint) in
            let indexPath = nextVC?.table?.indexPathForRow(at: cellPoint)
            if(indexPath != nil){
                popupLongCellTouch(view: nextVC!, custom: nil, data: nextVC!.displayView, index: indexPath!.row, point: touch)
            }
        }
        nextVC?.onOtherMenu = {
            nextVC?.navigationController?.pushViewController(Manager.createHistoryTable(view: nextVC!)!, animated: true)
        }
        nextVC?.menuInfo[3] = "更新"
        nextVC?.onMenuTouch[3] = { data in
            
            DispatchQueue.global().async {
                let thread = nextVC!.parentData as! Thread
                
                if(thread.res.count == 0){
                    nextVC?.storage.map{$0 as! Res}.forEach{
                        thread.res.append($0)
                    }
                }
                
                thread.res.forEach{$0.isSinchaku = false}
                //差分データ
                let updatedData = Parse().updateThread(thread: thread).res
                
                if updatedData.count <= 0{
                    return
                }
                
                var newTotalData = thread.res.map{$0}
                updatedData.forEach{
                    newTotalData.append($0)
                }
                
                newTotalData = Parse.setRelationParentRes(raw: newTotalData)
                
                DispatchQueue.main.async {
                    let isTree = nextVC?.FirstMenu.titleLabel?.text == "レス順"
                    thread.res.forEach{$0.isSinchaku = false}
                    if isTree{
                        var parsedata = (Parse().parseTreeArrayPartOfUpdate(old: nextVC?.storage.map{Res(cast: $0)} ?? [], update: updatedData))
                        
                        if(parsedata.count > 0){
                            parsedata[0].isSinchaku = true
                        }
                        
                        nextVC?.displayView.removeAll()
                        nextVC?.displayView = Parse().parseTreeArray(raw: thread.res)
                        parsedata.forEach{nextVC?.displayView.append($0)}
                        
                        
                        updatedData.forEach{
                            nextVC?.storage.append($0)
                            (nextVC?.parentData as! Thread).res.append($0)
                        }
                        nextVC?.storage = Parse.setRelationParentRes(raw: nextVC?.storage.map{Res(cast: $0)} ?? [])
                    }else{
                        //TODO: Notツリーモード時に安価データベースの再構築を行う
                        if(updatedData.count > 0){
                            nextVC?.displayView.removeAll()
                            //新着フラグをつけ直す
                            for i in 0..<newTotalData.count{
                                if(updatedData[0].num == newTotalData[i].num){
                                    newTotalData[i].isSinchaku = true
                                }else{
                                    newTotalData[i].isSinchaku = false
                                }
                                nextVC?.displayView.append(Res(cast: newTotalData[i]))
                            }
                            for newRes in updatedData{
                                nextVC?.storage.append(Res(cast: newRes))
                            }
                        }
                        
                        nextVC?.storage = Parse.setRelationParentRes(raw: nextVC?.storage.map{Res(cast: $0)} ?? [])
                    }
                    ToastView.showText(text: "新着 "+String(updatedData.count)+"件")
                    //nextVC?.displayView = updatedData
                    nextVC?.onCreateCell = { (i:Int,v:SuperTable) in
                        var cell:UITableViewCell? = nil
                        let data = nextVC?.displayView[i] as! Res
                        if(data.isSinchaku){
                            cell = v.cellGetter!("newres")
                            
                            let threadcell = cell as! NewResponseCell
                            threadcell.create(all: newTotalData , data: data, isCustomMode: isTree, nowView: v)
                            return cell!
                        }else{
                            
                            cell = v.cellGetter!("rescell")
                            
                            let threadcell = cell as! ResponseCell
                            threadcell.create(all: newTotalData , data: data , isCustomMode: isTree, nowView: v)
                            
                            return cell!
                        }
                        
                        
                    }
                    (nextVC?.parentData as! Thread).res = newTotalData
                    nextVC?.table?.reloadData()
                    if(nextVC?.isAutoScroll ?? false){
                        nextVC?.table?.scrollToRow(at: IndexPath(row: (nextVC?.displayView.count ?? 1) - 1, section: 0),
                                                   at: UITableView.ScrollPosition.bottom, animated: true)
                    }
                    
                }
            }
        }
        
        nextVC?.onMenuLongTouch[3] = { table in
            
            if(nextVC?.timer == nil){
                ToastView.showText(text: "オートリロードON")
                var time = 0
                nextVC?.timer = Timer.scheduledTimer(withTimeInterval: TimeInterval.init(exactly: 5.0)!, repeats: true, block: {_ in
                    nextVC?.isAutoScroll = true
                    nextVC?.onMenuTouch[3]?(nextVC!)
                    time += 5
                    if(time >= 1800){
                        time = 0
                        nextVC?.isAutoScroll = false
                        nextVC?.timer?.invalidate()
                        nextVC?.timer = nil
                    }
                    print("アプデ開始")
                })
                
                
                nextVC?.onDisappearView.append {
                    ToastView.showText(text: "オートリロードOFF")
                    nextVC?.timer?.invalidate()
                    nextVC?.timer = nil
                }
            }else{
                nextVC?.isAutoScroll = false
                ToastView.showText(text: "オートリロードOFF")
                nextVC?.timer?.invalidate()
                nextVC?.timer = nil
            }
        }
        
        nextVC?.menuInfo[1] = "ツリー"
        nextVC?.onMenuTouch[1] = { data in
            if(nextVC?.FirstMenu.titleLabel?.text == "ツリー"){
                
                nextVC?.FirstMenu.setTitle("レス順", for: .normal)
                DispatchQueue.global().async {
                    let datas = nextVC?.storage.map{$0 as! Res} ?? []
                    let parsed = Parse().parseTreeArray(raw: datas)
                    nextVC?.displayView = parsed
                    nextVC?.onCreateCell = { (i:Int,v:SuperTable) in
                        
                        var cell:UITableViewCell? = nil
                        let data = nextVC?.displayView[i] as! Res
                        if(data.isSinchaku){
                            cell = v.cellGetter!("newres")
                            
                            let threadcell = cell as! NewResponseCell
                            threadcell.create(all: datas , data: data, isCustomMode: true, nowView: v)
                            
                            return cell!
                        }else{
                            
                            cell = v.cellGetter!("rescell")
                            
                            let threadcell = cell as! ResponseCell
                            threadcell.create(all: datas , data: data , isCustomMode: true, nowView: v)
                            
                            return cell!
                        }
                    }
                    DispatchQueue.main.async {
                        nextVC?.table?.reloadData()
                    }
                }
            }else if(nextVC?.FirstMenu.titleLabel?.text == "レス順"){
                nextVC?.FirstMenu.setTitle("ツリー", for: .normal)
                DispatchQueue.global().async {
                    nextVC?.displayView = thread.res
                    nextVC?.onCreateCell = { (i:Int,v:SuperTable) in
                        let cell = v.cellGetter!("rescell")
                        let threadcell = cell as! ResponseCell
                        let datas = nextVC?.displayView as? [Res] ?? []
                        threadcell.create(all: datas, data: datas[i], isCustomMode: false, nowView: v)
                        return cell!
                    }
                    DispatchQueue.main.async {
                        nextVC?.table?.reloadData()
                    }
                }
            }
        }
        
        nextVC?.menuInfo[5] = "移動"
        nextVC?.onMenuTouch[5] = { data in
            
            let alert: UIAlertController = UIAlertController(title: "次の場所に移動します", message: "", preferredStyle:  UIAlertController.Style.actionSheet)
            // Defaultボタン
            let first: UIAlertAction = UIAlertAction(title: "一番上", style: UIAlertAction.Style.default, handler:{
                (action: UIAlertAction!) -> Void in
                nextVC?.table?.scrollToRow(at: IndexPath(row: 0, section: 0),
                                           at: UITableView.ScrollPosition.top, animated: true)
            })
            let end: UIAlertAction = UIAlertAction(title: "一番下", style: UIAlertAction.Style.default, handler:{
                (action: UIAlertAction!) -> Void in
                nextVC?.table?.scrollToRow(at: IndexPath(row: (nextVC?.displayView.count ?? 1) - 1, section: 0),
                                           at: UITableView.ScrollPosition.bottom, animated: true)
            })
            
            // Cancelボタン
            let cancelAction: UIAlertAction = UIAlertAction(title: "キャンセル", style: UIAlertAction.Style.cancel, handler:{(action: UIAlertAction!) -> Void in})
            
            alert.addAction(first)
            alert.addAction(end)
            alert.addAction(cancelAction)
            nextVC?.present(alert, animated: true, completion: nil)
            
        }
        
        nextVC?.menuInfo[2] = "書込"
        nextVC?.onMenuTouch[2] = { data in
            popupPostMenu(view: view, data: [nextVC!.parentData!], index: nil, isInyou: false)
        }
        
        
        
        nextVC?.navigationItem.title = thread.title
        return nextVC
    }
    
    static func popupResMenu(view:SuperTable?,custom:popupTable?,index:Int,datas:[SaveTypeTag],point:CGPoint?) {
        let res = datas[index] as! Res
        let beforeView = view != nil ? view : custom
        let thread = (view?.parentData) as? Thread
        let url = thread?.url ?? ""
        
        let menu = UIAlertController(title: "", message:
            String(res.num)+" 名前: "+res.writterName+" "+res.date+" ID:"+res.writterId
            , preferredStyle: UIAlertController.Style.actionSheet)
        let copy = UIAlertAction(title: "コピー", style: UIAlertAction.Style.default, handler: {
            (formaction: UIAlertAction!) in
            if(beforeView != nil){
                popupCopyView(view: beforeView!, res: res)
            }
        })
        let reply = UIAlertAction(title: ">>"+String(res.num)+"にレス", style: UIAlertAction.Style.default, handler: {
            (formaction: UIAlertAction!) in
            popupPostMenu(view: view!, data: datas, index: index,isInyou: false)
        })
        let quote = UIAlertAction(title: ">>"+String(res.num)+"を引用", style: UIAlertAction.Style.default, handler: {
            (formaction: UIAlertAction!) in
            popupPostMenu(view: view!, data: datas, index: index,isInyou: true)
        })
        
        let setsiori = UIAlertAction(title: "しおりを挟む", style: UIAlertAction.Style.default, handler: {
            (formaction: UIAlertAction!) in
            print("siori")
        })
        
        let ng = UIAlertAction(title: "NGする", style: UIAlertAction.Style.default, handler: {
            (formaction: UIAlertAction!) in
            //ID or NAME or Number
        })

        let cancel = UIAlertAction(title: "キャンセル", style: UIAlertAction.Style.cancel, handler: {
            (formaction: UIAlertAction!) in
            print("cancel")
        })
        
        menu.addAction(copy)
        menu.addAction(reply)
        menu.addAction(quote)
        menu.addAction(setsiori)
        menu.addAction(ng)
        
        if url.contains("5ch.net"){
            let hissi = UIAlertAction(title: "必死チェッカー", style: UIAlertAction.Style.default, handler: {
                (formaction: UIAlertAction!) in
                if(url.contains("5ch.net")){
                    let id = res.writterId
                    let dateSet = res.date.components(separatedBy: "(")[0].components(separatedBy: "/")
                    let date = dateSet[0]+dateSet[1]+dateSet[2]
                    if(url.count <= 0){
                        return
                    }else{
                        let boardid = (thread?.boardID ?? "")
                        let hissiurl = "http://hissi.org/read.php/"+boardid+"/search/"
                        let params = "date="+date+"&ID="+id
                        DispatchQueue.global().async {
                            let targeturl = "http://hissi.org/read.php/"+boardid+HttpClientImpl().postUrlParsedString(url: hissiurl, params: params, encode: .utf8).replacingOccurrences(of: "<meta http-equiv=\"refresh\" content=\"0; url=..", with: "").replacingOccurrences(of: "\">", with: "")
                            print(targeturl)
                            DispatchQueue.main.async {
                                guard let nextVC = view?.storyboard?.instantiateViewController(withIdentifier: "webview") as? WebView else{
                                    return
                                }
                                nextVC.url = targeturl
                                view?.present(nextVC, animated: true, completion: nil)
                                nextVC.titleBar.text = id+" の必死 - "+date
                            }
                            
                        }
                    }
                }
            })
            
            menu.addAction(hissi)
        }
        menu.addAction(cancel)
        
        let defaultHeight = CGFloat(integerLiteral: 0)
            //UIApplication.shared.statusBarFrame.size.height+(beforeView?.navigationController?.navigationBar.frame.size.height ?? 0)
        
        if(view != nil){
            menu.popoverPresentationController?.sourceView = view!.view
            menu.popoverPresentationController?.sourceRect = CGRect(x: point?.x ?? 0, y: (point?.y ?? 0)+defaultHeight, width: 0, height: 0)
            view?.present(menu, animated: true, completion: nil)
        }else if(custom != nil){
            menu.popoverPresentationController?.sourceView = custom!.view
            menu.popoverPresentationController?.sourceRect = CGRect(x: point?.x ?? 0, y: (point?.y ?? 0)+defaultHeight , width: 0, height: 0)
            custom?.present(menu, animated: true, completion: nil)
        }
    }
    
    static func popupLongCellTouch(view:SuperTable?,custom:popupTable?,data:[SaveTypeTag],index:Int,point:CGPoint?){
        Manager.popupResMenu(view: view, custom: custom, index: index, datas: data,point: point)
    }
    
    static func popupCopyView(view:UIViewController,res:Res) {
        let popup = view.storyboard?.instantiateViewController(withIdentifier: "editres") as! ResponseEditView
        let bodyData = String(res.num)+" "+res.writterName+" "+res.date+" ID:"+res.writterId+"\n"+res.body
        
        popup.titleMes = ">>"+String(res.num)+"のコピー"
        popup.bodyString = bodyData
        
        DispatchQueue.main.async {
            view.present(popup, animated: true, completion: nil)
        }
        
    }
    
    static func popupPostMenu(view: UIViewController,data:[SaveTypeTag],index:Int?,isInyou:Bool){
        let res = data as? [Res]
        let board = data as? [Board]
        let thread = data as? [Thread]
        let popup = view.storyboard?.instantiateViewController(withIdentifier: "write") as! PostTable
        if(res != nil && index != nil){
            popup.bodyMes += ">>"+String(res![index!].num)
            popup.titleMes = ">>"+String(res![index!].num)+"への返信"
            if(isInyou){
                popup.bodyMes += "\n"
                popup.bodyMes += res![index!].body
            }
            DispatchQueue.main.async {
                view.present(popup, animated: true, completion: nil)
            }
            
        }else if(board != nil){
            DispatchQueue.main.async {
                view.present(popup, animated: true, completion: nil)
            }
        }else if(thread != nil && index == nil){
            if(thread?[0] != nil){
                popup.titleMes = "書き込み"
                popup.onSend = {
                    print(popup.nameField.text ?? "")
                    print(popup.bodyField.text ?? "")
//
//                    Post.postResTo5ch(threadD: thread![0], postText:popup.bodyField.text , name: popup.nameField.text!, mail: popup.mailField.text!, onEnded: {
//                        print($0)
//                        let alert: UIAlertController = UIAlertController(title: "INFO", message: $0, preferredStyle:  UIAlertController.Style.alert)
//
//                        let defaultAction: UIAlertAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler:{
//                            // ボタンが押された時の処理を書く（クロージャ実装）
//                            (action: UIAlertAction!) -> Void in
//                            //print("OK")
//                        })
//                        // キャンセルボタン
//                        let cancelAction: UIAlertAction = UIAlertAction(title: "キャンセル", style: UIAlertAction.Style.cancel, handler:{
//                            // ボタンが押された時の処理を書く（クロージャ実装）
//                            (action: UIAlertAction!) -> Void in
//                            //print("Cancel")
//                        })
//
//                        // ③ UIAlertControllerにActionを追加
//                        alert.addAction(cancelAction)
//                        alert.addAction(defaultAction)
//                        view.present(alert, animated: true, completion: nil)
//                    })
                    
                    popup.dismiss(animated: true, completion: nil)
                }
                DispatchQueue.main.async {
                    view.present(popup, animated: true, completion: nil)
                    popup.threadTitleHeight.constant = 0
                    popup.threadTitle.isHidden = true
                }
            }
        }
    }
    
    func fistPageReqest(view:SuperTable) {
        self.views.append(view)
        view.progress?.isHidden = true
        view.progress?.bounds = CGRect(x: view.progress?.bounds.origin.x ?? 0, y: view.progress?.bounds.origin.y ?? 0, width: view.progress?.bounds.width ?? 0, height: 0)
        
        DispatchQueue.global().async {
            let Fivechserver = Server()
            Fivechserver.title = "5ch.net"
            let Filechboard = Parse().getCategoryAndBoard(url: "http://menu.5ch.net/bbsmenu.html")
            Fivechserver.bigcategory = Filechboard
            view.displayView.append(Fivechserver)
            view.storage.append(Fivechserver)
            let open = Server()
            open.title = "おーぷん"
            let openboard = Parse().getCategoryAndBoard(url: "https://menu.open2ch.net/bbsmenu.html")
            open.bigcategory = openboard
            view.displayView.append(open)
            view.storage.append(open)
            
            view.onCreateCell = {(index:Int,view:SuperTable) -> UITableViewCell in
                let cell = view.cellGetter!("basiccell")
                let customcell = cell as! BasicCell
                customcell.title.text = view.displayView[index].title 
                customcell.onCellTouch = {
                    let data = view.displayView[$0]
                    let nextVC = Manager.createCategoryTable(view: view, data: data)
                    if(nextVC != nil){
                        view.navigationController?.pushViewController(nextVC!, animated: true)
                    }
                }
                return cell!
            }
            
            view.onOtherMenu = {
                let othermenu = Manager.createHistoryTable(view: view)
                view.navigationController?.pushViewController(othermenu!, animated: true)
            }
            
            DispatchQueue.main.async {
                view.table?.reloadData()
            }
        }
        //いた追加
        view.menuInfo[3] = "+"
        view.onMenuTouch[3] = {
            let target = $0
            
            let editform = UIAlertController(title: "掲示板の追加", message: "", preferredStyle: UIAlertController.Style.alert)
            
            let editok = UIAlertAction(title: "完了", style: UIAlertAction.Style.default, handler: {
                (formaction: UIAlertAction!) in
                //print("アクション１をタップした時の処理")
                
                let textFields:Array<UITextField>? =  editform.textFields as Array<UITextField>?
                if textFields != nil{
                    if(textFields!.count == 2){
                        let name = textFields![0].text ?? ""
                        let url = textFields![1].text ?? ""
                        
                        let failedmes = UIAlertController(title: "エラー", message: "", preferredStyle: UIAlertController.Style.alert)
                        failedmes.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        if(name.count == 0){
                            failedmes.message = "名前が入っていません"
                            target.present(failedmes, animated: true, completion: nil)
                        }else if(url.count == 0 || !url.hasPrefix("http") || !url.hasSuffix(".html")){
                            failedmes.message = "urlがおかしいです httpで始まりhtmlで終わるURLですか？"
                            target.present(failedmes, animated: true, completion: nil)
                        }else{
                            DispatchQueue.global(qos: .default).async {
                                let server = Server()
                                print(url)
                                let board = Parse().getCategoryAndBoard(url: url)
                                if(board.count == 0){
                                    failedmes.message = "取得できた板がありません"
                                    target.present(failedmes, animated: true, completion: nil)
                                }else{
                                    server.bigcategory = board
                                    failedmes.title = "成功"
                                    failedmes.message = "掲示板の追加に成功しました"
                                    target.present(failedmes, animated: true, completion: nil)
                                    server.title = name
                                    //self.downloadedData.append(server)
                                    DispatchQueue.main.async {
                                        target.displayView.append(server)
                                        target.storage.append(server)
                                        target.onCreateCell = {(index:Int,view:SuperTable) -> UITableViewCell in
                                            let cell = view.cellGetter!("basiccell")
                                            let customcell = cell as! BasicCell
                                            customcell.title.text = target.displayView[index].title
                                            customcell.onCellTouch = {
                                                
                                                let data = view.displayView[$0]
                                                let nextVC = Manager.createCategoryTable(view: target, data: data) as! SuperTable
                                                view.navigationController?.pushViewController(nextVC, animated: true)
                                            }
                                            return cell!
                                        }
                                        
                                        //更新
                                        target.onPutData?()
                                    }
                                }
                            }
                        }
                        
                    }
                }
                
                
            })
            
            editform.addTextField(configurationHandler: {
                $0.placeholder = "掲示板の名前"
            })
            editform.addTextField(configurationHandler: {
                $0.placeholder = "URL (例: https://menu.open2ch.net/bbsmenu.html)"
            })
            
            let editcancel = UIAlertAction(title: "キャンセル", style: UIAlertAction.Style.cancel, handler: {
                (action: UIAlertAction!) in
                
            })
            editform.addAction(editok)
            editform.addAction(editcancel)
            target.present(editform, animated: true, completion: nil)
        }
    }
    
}

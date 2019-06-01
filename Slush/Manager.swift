//
//  Manager.swift
//  River
//
//  Created by 10fu3 on 2019/05/19.
//  Copyright © 2019 10fu3. All rights reserved.
//

import Foundation
import RealmSwift
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
                    for index in sourceRes?.toRef[i].1 ?? []{
                        values.append(rawRes[index])
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
                        let index = i.num
                        for resIndex in i.treeChildren{
                            let re = resIndex
                            values.append(rawRes[resIndex])
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
    
    let realm = try! Realm()
    var downloadedData = [Server]()
    
    var views = [SuperTable]()
    
    func createCell(_ index:Int,_ view:SuperTable) -> UITableViewCell {
        let mode = view.tableMode
        var cell:UITableViewCell? = nil
        if(mode != nil){
            switch view.tableMode! {
                case .SERVER_LIST:
                    view.tableMode = .CATEGORY_LIST
                    cell = view.cellGetter?("basic")
                    let custom = cell as? BasicCell
                    let data = view.displayView![index] as! Server
                    custom?.title.text = data.title
                    custom?.onCellTouch = { i in
                        let j = i as! Category
                        let nextVC = view.storyboard?.instantiateViewController(withIdentifier: "table") as? SuperTable
                        nextVC?.isFirst = false
                        nextVC?.displayView = j.boards
                        if(nextVC != nil){
                            view.navigationController?.present(nextVC!, animated: true, completion: nil)
                            //view.present(nextVC!, animated: true, completion: nil)
                        }
                    }
                    
                    break
                case .BOARD_LIST:
                    view.tableMode = .THREAD
                    cell = view.cellGetter?("basic")
                    let custom = cell as? BasicCell
                    let data = view.displayView![index] as! Board
                    custom?.title.text = data.title
                    custom?.onCellTouch = { i in
                        let j = i as! Thread
                        let nextVC = view.storyboard?.instantiateViewController(withIdentifier: "table") as? SuperTable
                        nextVC?.isFirst = false
                        nextVC?.displayView = j.res
                        if(nextVC != nil){
                            view.navigationController?.present(nextVC!, animated: true, completion: nil)
                            //view.present(nextVC!, animated: true, completion: nil)
                        }
                    }
                    break
                case .CATEGORY_LIST:
                    view.tableMode = .BOARD_LIST
                    cell = view.cellGetter?("basic")
                    let custom = cell as? BasicCell
                    let data = view.displayView![index] as! Category
                    custom?.title.text = data.title
                    custom?.onCellTouch = { i in
                        let j = i as! Board
                        let nextVC = view.storyboard?.instantiateViewController(withIdentifier: "table") as? SuperTable
                        nextVC?.isFirst = false
                        nextVC?.displayView = j.nowThread
                        if(nextVC != nil){
                            view.navigationController?.present(nextVC!, animated: true, completion: nil)
                            //view.present(nextVC!, animated: true, completion: nil)
                        }
                    }
                    break
                case .THREAD:
                    view.tableMode = .RESPONSE
                    cell = view.cellGetter?("threadcell")
                    let custom = cell as? ThreadCell
                    let data = view.displayView![index] as! Thread
                    custom?.count.text = String(data.resCount)
                    custom?.date.text = Parse().jpDateFormater.string(from: data.date)
                    custom?.title.text = data.title
                    custom?.ikioi.text = String(data.getIkioi())
                    break
                case .RESPONSE:
                    cell = view.cellGetter?("rescell")
                    let custom = cell as? ResponseCell
                    let data = view.displayView![index] as! Res
                    let datas = view.displayView!.map{Res(cast: $0)}
                    
                    custom?.create(all: datas, datas: datas, data: data, isCustomMode: false, nowView: view)
                    
                    break
//                case .RESPONSE_TREE:
//                    cell = view.cellGetter?("basic")
//                    break
                default:
                    cell = view.cellGetter?("basic")
                    cell?.textLabel?.text = "Error"
            }
            
        }
        return cell!
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
        nextVC?.onCreateCell = { (i:Int,v:SuperTable) in
            let cell = v.cellGetter!("basiccell") as! BasicCell
            cell.setData(view: v, data: category[i])
            return cell
        }
        nextVC?.navigationItem.title = server.title
        return nextVC
    }
    
    static func createBoardTable(view:SuperTable,data:SaveTypeTag) -> UIViewController? {
        
        let server = data as! Category
        let board = server.boards
        
        let nextVC = view.storyboard?.instantiateViewController(withIdentifier: "table") as? SuperTable
        nextVC?.isFirst = false
        nextVC?.displayView = board
        nextVC?.onCreateCell = { (i:Int,v:SuperTable) in
            let cell = v.cellGetter!("basiccell") as! BasicCell
            cell.setData(view: v, data: board[i])
            return cell
        }
        nextVC?.navigationItem.title = server.title
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
            
            board.cache = getthreads.count > 0 ? getthreads : Parse().getThreadsBy5ch(boardUrl: board.url).nowThread
            board.nowThread = board.cache
        }
        
        let nextVC = view.storyboard?.instantiateViewController(withIdentifier: "table") as? SuperTable
        nextVC?.isFirst = false
        nextVC?.displayView = board.nowThread
        
        //board.nowThread = Parse().getThreads(boardUrl: board.url).nowThread
        nextVC?.onCreateCell = { (i:Int,v:SuperTable) in
            //print("A")
            let cell = v.cellGetter!("threadcell")
            let threadcell = cell as! ThreadCell
            threadcell.setData(view: v, data: nextVC!.displayView![i])
            threadcell.title.numberOfLines = 0
            return cell!
        }
        
        nextVC?.menuInfo[3] = "更新"
        nextVC?.onMenuTouch[3] = { view in
            DispatchQueue.global().async {
                //nextVC?.displayView = []
                let getthreads = Parse().getThreads(boardUrl: board.url).nowThread
                
                nextVC?.displayView = getthreads.count > 0 ? getthreads : Parse().getThreadsBy5ch(boardUrl: board.url).nowThread
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
                let array = nextVC?.displayView?.sorted(by: { (a, b) -> Bool in
                    return (a as! Thread).date < (b as! Thread).date
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
                let array = nextVC?.displayView?.sorted{
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
            
        }
        
        nextVC?.navigationItem.title = board.title
        
        
        return nextVC
    }
    
    static func addCustomSearch(all:[Res], view:UIViewController,option:SearchFilter) {
        var result = option.search()
        var title = ""
        let nextVC = view.storyboard?.instantiateViewController(withIdentifier: "custom") as? CustomSearchRes
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
        nextVC?.displayTitle = title
        nextVC?.displayView = result
        nextVC?.onCreateCell = { (i:Int,v:CustomSearchRes) in
            let cell = v.cellGetter!("rescell")
            let threadcell = cell as! ResponseCell
            threadcell.create(all: all, datas: result, data: result[i], isCustomMode: false, nowView: v)
            return cell!
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
    
    static func createResTable(view:SuperTable,data:SaveTypeTag) -> UIViewController? {
        //サーバーのセルがタップされたとき
        var thread = data as! Thread
        var nextVC = view.storyboard?.instantiateViewController(withIdentifier: "table") as? SuperTable
        thread = Parse().getThread(thread: thread, onDownload: {
            DispatchQueue.main.async {
                ToastView.showText(text: "ダウンロード開始")
            }
        }, onParse: { part,all in
            DispatchQueue.main.async {
                view.progress?.progress = Float(part)/Float(all)
                print(Float(part)/Float(all))
            }
        }, onError: {
            DispatchQueue.main.async {
                let alert: UIAlertController = UIAlertController(title: "読み込みエラー", message: "対象のデータにCP932のコードが含まれているか、オフラインの可能性があります", preferredStyle:  UIAlertController.Style.alert)
                
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
        nextVC?.displayView = thread.res
        nextVC?.onCreateCell = { (i:Int,v:SuperTable) in
            
            let cell = v.cellGetter!("rescell")
            let threadcell = cell as! ResponseCell
            threadcell.create(all: thread.res,datas: nextVC?.displayView as! [Res], data: nextVC?.displayView?[i] as! Res, isCustomMode: false, nowView: v)
            return cell!
        }
        
        nextVC?.menuInfo[3] = "更新"
        nextVC?.onMenuTouch[3] = { data in
            DispatchQueue.global().async {
                
                
                //nextVC?.displayView = Parse().update5chThread(thread: thread).res
                var updatedData = Parse().update5chThread(thread: thread).res
                DispatchQueue.main.async {
                    if(nextVC?.FistMenu.titleLabel?.text == "レス順"){
                        updatedData = Parse().parseTreeArray(raw:updatedData)
                    }
                    ToastView.showText(text: "新着"+String(updatedData.count-(nextVC?.displayView?.count ?? 0))+"件")
                    nextVC?.displayView = updatedData
                    
                    nextVC?.table?.reloadData()
                }
            }
        }
        
        nextVC?.menuInfo[1] = "ツリー"
        nextVC?.onMenuTouch[1] = { data in
            if(nextVC?.FistMenu.titleLabel?.text == "ツリー"){
                
                nextVC?.FistMenu.setTitle("レス順", for: .normal)
                DispatchQueue.global().async {
                    nextVC?.displayView = Parse().parseTreeArray(raw:nextVC?.displayView?.map{$0 as! Res} ?? [Res]() )
                    nextVC?.onCreateCell = { (i:Int,v:SuperTable) in
                        let cell = v.cellGetter!("rescell")
                        let threadcell = cell as! ResponseCell
                        
                        let datas = nextVC?.displayView as? [Res] ?? []
                        threadcell.create(all: datas,datas: datas , data: datas[i], isCustomMode: true, nowView: v)
                        return cell!
                    }
                    DispatchQueue.main.async {
                        nextVC?.onPutData!()
                    }
                }
            }else if(nextVC?.FistMenu.titleLabel?.text == "レス順"){
                nextVC?.FistMenu.setTitle("ツリー", for: .normal)
                DispatchQueue.global().async {
                    nextVC?.displayView = thread.res
                    nextVC?.onCreateCell = { (i:Int,v:SuperTable) in
                        let cell = v.cellGetter!("rescell")
                        let threadcell = cell as! ResponseCell
                        let datas = nextVC?.displayView as? [Res] ?? []
                        threadcell.create(all: datas,datas: datas , data: datas[i], isCustomMode: false, nowView: v)
                        return cell!
                    }
                    DispatchQueue.main.async {
                        nextVC?.table?.reloadData()
                    }
                }
            }
        }
        
        nextVC?.menuInfo[4] = "一番上"
        nextVC?.onMenuTouch[4] = { data in
            nextVC?.table?.scrollToRow(at: IndexPath(row: 0, section: 0),
                                       at: UITableView.ScrollPosition.top, animated: true)
        }
        
        nextVC?.menuInfo[5] = "一番下"
        nextVC?.onMenuTouch[5] = { data in
            nextVC?.table?.scrollToRow(at: IndexPath(row: (nextVC?.displayView?.count ?? 1) - 1, section: 0),
                                       at: UITableView.ScrollPosition.bottom, animated: true)
        }
        
        nextVC?.menuInfo[2] = "書込"
        nextVC?.onMenuTouch[2] = { data in
            
        }
        
        nextVC?.navigationItem.title = thread.title
        return nextVC
    }
    
    func fistPageReqest(view:SuperTable) {
        self.views.append(view)
        view.progress?.isHidden = true
        view.progress?.bounds = CGRect(x: view.progress?.bounds.origin.x ?? 0, y: view.progress?.bounds.origin.y ?? 0, width: view.progress?.bounds.width ?? 0, height: 0)
        
        DispatchQueue.global().async {
            let Fivechserver = Server()
            let Filechboard = Parse().getCategoryAndBoard(url: "http://menu.5ch.net/bbsmenu.html")
            Fivechserver.bigcategory = Filechboard
            view.displayView?.append(Fivechserver)
            
            
            view.onCreateCell = {(index:Int,view:SuperTable) -> UITableViewCell in
                let cell = view.cellGetter!("basiccell")
                let customcell = cell as! BasicCell
                customcell.title.text = view.displayView?[index].title ?? "Error"
                customcell.onCellTouch = {data in
                    let nextVC = Manager.createCategoryTable(view: view, data: data)
                    if(nextVC != nil){
                        view.navigationController?.pushViewController(nextVC!, animated: true)
                    }
                }
                return cell!
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
                                    self.downloadedData.append(server)
                                    DispatchQueue.main.sync {
                                        
                                        
                                        target.displayView = self.downloadedData.map{$0}
                                        
                                        target.onCreateCell = {(index:Int,view:SuperTable) -> UITableViewCell in
                                            let cell = view.cellGetter!("basiccell")
                                            let customcell = cell as! BasicCell
                                            customcell.title.text = target.displayView?[index].title ?? "Error"
                                            customcell.onCellTouch = {data in
                                                let nextVC = Manager.createCategoryTable(view: target, data: data)
                                                
                                                if(nextVC != nil){
                                                    view.navigationController?.pushViewController(nextVC!, animated: true)
                                                }
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
        
        view.boardListReq.tintColor = .yellow
    }
    
}

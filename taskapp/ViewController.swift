//
//  ViewController.swift
//  taskapp
//
//  Created by 小尾真太郎 on 2016/11/29.
//  Copyright © 2016年 小尾真太郎. All rights reserved.


import UIKit
import RealmSwift   // ←追加
import UserNotifications 

//UISearchBarDelegate

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource,UISearchBarDelegate{
    // Realmインスタンスを取得する
    let realm = try! Realm()
    var searchResult : [String] = []
    var searchResultDate : [String] = []
    var searchResultID : [Int] = []
    var soteIdToId : [Int] = []
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var categorySearch: UISearchBar!
    @IBOutlet weak var purasuButton: UIBarButtonItem!

    // DB内のタスクが格納されるリスト。
    // 日付近い順\順でソート：降順
    // 以降内容をアップデートするとリスト内は自動的に更新される。
    let taskArray = try! Realm().objects(Task.self).sorted(byProperty: "date", ascending: false)   // ←追加
    let SearchResult = try! Realm().objects(Task.self)
    
    // 入力画面から戻ってきた時に TableView を更新させる
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        categorySearch.text = ""
        categorySearch.showsCancelButton = false
        purasuButton.isEnabled = true
        tableView.reloadData()
    }
    
    //VIEW DID LOAD
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        tableView.delegate = self
        tableView.dataSource = self
        
        categorySearch.delegate = self
        categorySearch.searchBarStyle = UISearchBarStyle.default
        categorySearch.showsSearchResultsButton = false
        categorySearch.setValue("キャンセル", forKey: "_cancelButtonText")
        categorySearch.tintColor = UIColor.red
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: UITableViewDataSourceプロトコルのメソッド
    // データの数（＝セルの数）を返すメソッド
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(categorySearch.text == ""){
           return taskArray.count
        }else{
           return searchResult.count
        }
    }
    
    
    // 各セルの内容を返すメソッド
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // 再利用可能な cell を得る
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath as IndexPath)
        if(categorySearch.text == ""){
            // Cellに値を設定する.
            let task = taskArray[indexPath.row]
            cell.textLabel?.text = task.title + "::" + task.category + "::" + "\(task.id)" + ":::" + "\(indexPath.row)"
        
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
        
            let dateString:String = formatter.string(from: task.date as Date)
            cell.detailTextLabel?.text = dateString
        }else{
            let task = searchResult[indexPath.row]
            let taskDate = searchResultDate[indexPath.row]
            let taskID = searchResultID[indexPath.row]
            cell.textLabel?.text = task + "\(taskID)" + ":::" + "\(indexPath.row)"
            cell.detailTextLabel?.text = taskDate
        }
            return cell
    }
    
    // MARK: UITableViewDelegateプロトコルのメソッド
    // 各セルを選択した時に実行されるメソッド
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "cellSegue",sender: nil)
    }
    
    // セルが削除が可能なことを伝えるメソッド
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath)-> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.delete
    }
    
    // Delete ボタンが押された時に呼ばれるメソッド
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCellEditingStyle.delete {
            
            // 削除されたタスクを取得する
            let task = self.taskArray[indexPath.row]
            
            // ローカル通知をキャンセルする
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: [String(task.id)])
            
            // データベースから削除する
            try! realm.write {
                self.realm.delete(task)
                tableView.deleteRows(at: [indexPath as IndexPath], with: UITableViewRowAnimation.fade)
            }
            
            // 未通知のローカル通知一覧をログ出力
            center.getPendingNotificationRequests { (requests: [UNNotificationRequest]) in
                for request in requests {
                    print("/---------------")
                    print(request)
                    print("---------------/")
                }
            }
        }
    }
    // segue で画面遷移するに呼ばれる
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        let inputViewController:InputViewController = segue.destination as! InputViewController
        // f : soteID　--> ID
        if(taskArray.count >= 1){
            for i in (0...taskArray.count-1){
                soteIdToId.append(taskArray[i].id)
            }
        }
            if segue.identifier == "cellSegue" {
                let indexPath = self.tableView.indexPathForSelectedRow
                if(categorySearch.text == ""){
                    inputViewController.task = taskArray[indexPath!.row]
                }else{
                    let resultID = searchResultID[indexPath!.row]
                    var finishSoteID : Int = 0
                    for i in (0...taskArray.count-1){
                        if(resultID == soteIdToId[i]){
                             finishSoteID = i
                        }
                    }
                    inputViewController.task = taskArray[finishSoteID]
                }
            } else {
                let task = Task()
                task.date = NSDate()
                
                if taskArray.count != 0 {
                    task.id = taskArray.max(ofProperty: "id")! + 1
                }
                
                inputViewController.task = task
            }
    }
    
    
    //categorySearch
    //searchBar
    // 検索ボタンが押された時に呼ばれる
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
          self.view.endEditing(true)
          searchBar.showsCancelButton = true
          purasuButton.isEnabled = false
          let formatter = DateFormatter()
          formatter.dateFormat = "yyyy-MM-dd HH:mm"
        
          let result = realm.objects(Task.self).filter("category = '\(searchBar.text!)'")
          for data in result{
            searchResult.append("\(data.title)")
            searchResultDate.append("\(formatter.string(from: data.date as Date))")
            searchResultID.append(data.id)
          }
          self.tableView.reloadData()
    }
    
    // キャンセルボタンが押された時に呼ばれる
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
          searchBar.showsCancelButton = false
          purasuButton.isEnabled = true
          self.view.endEditing(true)
          searchResult = []
          searchResultDate = []
          searchResultID = []
          searchBar.text = ""
          self.tableView.reloadData()
    }
    
    // テキストフィールド入力開始前に呼ばれる
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.showsCancelButton = true
        return true
    }



}


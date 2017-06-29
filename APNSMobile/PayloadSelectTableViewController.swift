//
//  PayloadSelectTableViewController.swift
//  APNSMobile
//
//  Created by 孙翔宇 on 6/14/17.
//  Copyright © 2017 Emirates. All rights reserved.
//

import UIKit

extension Notification.Name {
    static let loadObject = Notification.Name("loadObject")
}

class PayloadSelectTableViewController: UITableViewController {
    let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first?.appending("/jsons")
    var contents: [String]!
    override func viewDidLoad() {
        super.viewDidLoad()


        self.clearsSelectionOnViewWillAppear = false

    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        do {
            contents = try FileManager.default.contentsOfDirectory(atPath: path!)
        }catch {
            contents = []
        }
        tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source


    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return contents.count
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        cell.textLabel?.text = contents[indexPath.row]
        let filePath = path!.appending("/\(contents[indexPath.row])")
        let att = try!FileManager.default.attributesOfItem(atPath: filePath)
        
        cell.detailTextLabel?.text = DateFormatter.localizedString(from: (att[FileAttributeKey.creationDate] as! Date), dateStyle: .short, timeStyle: .medium)

        return cell
    }


    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    

    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            try! FileManager.default.removeItem(atPath: path!.appending("/\(contents[indexPath.row])") )
            contents.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let pa = path!.appending("/\(contents[indexPath.row])")
        
        let ob = try! String(contentsOf: URL(fileURLWithPath: pa))
        NotificationCenter.default.post(name: .loadObject, object: self, userInfo: ["payload":ob])
        
        tabBarController?.selectedViewController = tabBarController?.viewControllers?.last
    }

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

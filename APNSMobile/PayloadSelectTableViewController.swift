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
  
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.clearsSelectionOnViewWillAppear = false
        
        
        if #available(iOS 11, *) {
            loadVNVC()
        } else {
            
        }
    }
    
    func loadVNVC()  {
        let vn = self.storyboard!.instantiateViewController(withIdentifier: "VNTextViewNavigationController")
        var vcs = self.tabBarController?.viewControllers
        vcs?.append(vn)
       self.tabBarController?.setViewControllers(vcs, animated: false)
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        JSONFileManager.shared.reloadData()
        tableView.reloadData()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        switch section {
        case 0:
            return JSONFileManager.shared.userContents.count
        default:
            return JSONFileManager.shared.templateContents.count
        }
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        
        let file = indexPath.section == 0 ? JSONFileManager.shared.userContents[indexPath.row].keys.first! : JSONFileManager.shared.templateContents[indexPath.row]
        
        cell.textLabel?.text = file
        let filePath = indexPath.section == 0 ? JSONFileManager.shared.JSONCacheFolderPath.appending("/\(file)") : JSONFileManager.shared.JSONTemplatesCacheFolderPath!.appending("/\(file)")
        let att = try!FileManager.default.attributesOfItem(atPath: filePath)
        
        cell.detailTextLabel?.text = DateFormatter.localizedString(from: (att[FileAttributeKey.creationDate] as! Date), dateStyle: .short, timeStyle: .medium)

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let file = indexPath.section == 0 ? JSONFileManager.shared.userContents[indexPath.row].keys.first! : JSONFileManager.shared.templateContents[indexPath.row]
        
        let filePath = indexPath.section == 0 ? JSONFileManager.shared.JSONCacheFolderPath.appending("/\(file)") : JSONFileManager.shared.JSONTemplatesCacheFolderPath!.appending("/\(file)")
        
        let ob = try! String(contentsOf: URL(fileURLWithPath: filePath))
        
        NotificationCenter.default.post(name: .loadObject, object: self, userInfo: ["payload":ob])
        
        tabBarController?.selectedViewController = tabBarController?.viewControllers?[1]
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Histories" : "Templates"
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 0
    }
    
    override func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Delete"
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            try! FileManager.default.removeItem(atPath:JSONFileManager.shared.JSONCacheFolderPath.appending("/\(JSONFileManager.shared.userContents[indexPath.row].keys.first!)") )
            JSONFileManager.shared.userContents.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            
        }
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

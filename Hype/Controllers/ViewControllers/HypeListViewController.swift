//
//  HypeListViewController.swift
//  Hype
//
//  Created by RYAN GREENBURG on 9/25/19.
//  Copyright © 2019 RYAN GREENBURG. All rights reserved.
//

import UIKit

class HypeListViewController: UIViewController {

   // MARK: - Class Properties
    var refresh: UIRefreshControl = UIRefreshControl()
    // MARK: - Outlets
    @IBOutlet weak var tableView: UITableView!

    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
        loadData()
    }
    
    // MARK: - Actions
    @IBAction func addHypeButtonTapped(_ sender: Any) {
        presentHypeAlert(for: nil)
    }
    
    // MARK: - Class Methods
    func setUpViews() {
        tableView.dataSource = self
        tableView.delegate = self
        refresh.attributedTitle = NSAttributedString(string: "Pull to see new Hypes")
        refresh.addTarget(self, action: #selector(loadData), for: .valueChanged)
        tableView.addSubview(refresh)
    }
    
    func updateViews() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.refresh.endRefreshing()
        }
    }
    
    @objc func loadData() {
        HypeController.shared.fetchAllHypes { (result) in
            guard let _ = try? result.get() else { return }
            self.updateViews()
        }
    }
    
    // MARK: - Day 2 changes
    func presentHypeAlert(for hype: Hype?) {
        let alertController = UIAlertController(title: "Get Hype!", message: "What is hype may never die", preferredStyle: .alert)
        
        alertController.addTextField { (textField) in
            textField.delegate = self
            textField.placeholder = "What is hype today?"
            textField.autocorrectionType = .yes
            textField.autocapitalizationType = .sentences
            if let hype = hype {
                textField.text = hype.body
            }
        }
        
        let addHypeAction = UIAlertAction(title: "Send", style: .default) { (_) in
            guard let text = alertController.textFields?.first?.text, !text.isEmpty else { return }
            if let hype = hype {
                hype.body = text
                HypeController.shared.update(hype) { (result) in
                    guard let _ = try? result.get() else { return }
                    self.updateViews()
                }
            } else {
                HypeController.shared.saveHype(with: text) { (result) in
                    guard let _ = try? result.get() else { return }
                    self.updateViews()
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alertController.addAction(addHypeAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true)
    }
}

// MARK: - TableView DataSource/Delegate Conformance
extension HypeListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return HypeController.shared.hypes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "hypeCell", for: indexPath)
        
        let hype = HypeController.shared.hypes[indexPath.row]
        cell.textLabel?.text = hype.body
        cell.detailTextLabel?.text = hype.timestamp.formatDate()
        
        return cell
    }
    
    // MARK: - Day 2 changes
    // Add functionality for update and delete rows. 
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let hype = HypeController.shared.hypes[indexPath.row]
        presentHypeAlert(for: hype)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let hypeToDelete = HypeController.shared.hypes[indexPath.row]
            guard let index = HypeController.shared.hypes.firstIndex(of: hypeToDelete) else { return }
            HypeController.shared.delete(hypeToDelete) { (result) in
                guard let _ = try? result.get() else { return }
                HypeController.shared.hypes.remove(at: index)
                DispatchQueue.main.async {
                    tableView.deleteRows(at: [indexPath], with: .fade)
                }
            }
        }
    }
}

// MARK: - TextFieldDelegate Confromance
extension HypeListViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}


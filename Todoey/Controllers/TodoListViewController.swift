//
//  ViewController.swift
//  Todoey
//
//  Created by Philipp Muellauer on 02/12/2019.
//  Copyright © 2019 App Brewery. All rights reserved.
//

import UIKit
import RealmSwift
import ChameleonFramework

class TodoListViewController: SwipeTableViewController {
    
    var todoItems: Results<Item>?
    let realm = try! Realm()
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var sortByButton: UISegmentedControl!
    
    
    // Optional category because it is going to be nil until a category has been selected from the previous categories page
    var selectedCategory : Category? {
        didSet {
            // happens as soon as selectedCategory gets set with a value
            loadItems()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sortByButton.backgroundColor = UIColor.white
        sortByButton.setTitle("Name", forSegmentAt: 0)
        sortByButton.setTitle("Date Added", forSegmentAt: 1)
        
        // Code for dismissing keyboard when tapped outside while searching ********************
        // Looks for single or multiple taps
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        
        // Uncomment the line below if you want the tap to not interfere and cancel other interactions
         tap.cancelsTouchesInView = false
        
        view.addGestureRecognizer(tap)
        // Code end ********************
        
//        navigationItem.rightBarButtonItems?[1] = editButtonItem
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        
        if let colourHex = selectedCategory?.colour {
            
            title = selectedCategory!.name
            
            
            // Below does not work for iOS 14
            guard let navBar = navigationController?.navigationBar else {fatalError("Navigation controller does not exist.")}
//            navBar.barTintColor = UIColor(hexString: colourHex)
            
            
            if let navBarColour = UIColor(hexString: colourHex) {
                
                // To fix the bug where the bar tint of the navigation bar is ignoring the tint colour set in the Main.storyboard
                let navBarAppearance = UINavigationBarAppearance()
                navBarAppearance.configureWithOpaqueBackground()
                navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
                navBarAppearance.largeTitleTextAttributes = [.foregroundColor: ContrastColorOf(navBarColour, returnFlat: true)]
                navBarAppearance.backgroundColor = navBarColour
                navigationController?.navigationBar.standardAppearance = navBarAppearance
                navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
                
                navBar.tintColor = ContrastColorOf(navBarColour, returnFlat: true)
                
                searchBar.barTintColor = navBarColour
                
                // Changing the colour of the Cancel button on the search bar
                let cancelButtonAttributes = [NSAttributedString.Key.foregroundColor: ContrastColorOf(navBarColour, returnFlat: true)]
                UIBarButtonItem.appearance().setTitleTextAttributes(cancelButtonAttributes, for: .normal)
                
            }
            
            
        }
    }
    
    
    // MARK: - Tableview Datasource Methods
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return todoItems?.count ?? 1
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        
        if let item = todoItems?[indexPath.row] {
            
            cell.textLabel?.text = item.title
            cell.detailTextLabel?.text = item.detail
            
            if let colour = UIColor(hexString: selectedCategory!.colour)?.darken(byPercentage: CGFloat(indexPath.row) / CGFloat(todoItems!.count)) {
                
                cell.backgroundColor = colour
                cell.textLabel?.textColor = ContrastColorOf(colour, returnFlat: true)
                cell.detailTextLabel?.textColor = ContrastColorOf(colour, returnFlat: true)
                
            }
            
            
            // Ternary operator ==>
            //  value = condition ? valueIfTrue : valuIfFalse
            
            cell.accessoryType = item.done ? .checkmark : .none
        } else {
            cell.textLabel?.text = "No Items Added"
        }
        
        return cell
    }
    
    
    // MARK: - TableView Delegate Methods
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let item = todoItems?[indexPath.row] {
            do {
                try realm.write {
                    item.done = !item.done
                }
            } catch {
                print("Error saving done status, \(error)")
            }
        }
        
        tableView.reloadData()
        
        tableView.deselectRow(at: indexPath, animated: true)
        
    }
    
    
    
    // MARK: - Add New Items
    
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        // Reference to the alertTextField
        var titleField = UITextField()
        
        var detailField = UITextField()
        
        
        // Alert window that pops up when add button is pressed
        let alert = UIAlertController(title: "Add New Todoey Item", message: "", preferredStyle: .alert)
        
        // The button that you press once you're done writing the new item
        let action = UIAlertAction(title: "Add Item", style: .default) { (action) in
            // What will happen once the user clicks the Add Item button on the UIAlert
            
            if titleField.text != "" {
                
                if let currentCategory = self.selectedCategory {
                    do {
                        try self.realm.write {
                            let newItem = Item()
                            newItem.title = titleField.text!
                            newItem.detail = detailField.text!
                            newItem.dateCreated = Date()
                            
                            currentCategory.items.append(newItem)
                        }
                    } catch {
                        print("Error saving new items, \(error)")
                    }
                }
                
                self.tableView.reloadData()
                
            }
        }
        
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        cancelAction.setValue(UIColor.red, forKey: "titleTextColor")
        
        
        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = "Create new item"
            // Store the reference to alertTextField to a local variable textField
            titleField = alertTextField
            titleField.returnKeyType = .next
        }
        
        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = "Add Description..."
            detailField = alertTextField
            detailField.returnKeyType = .done
        }
        
        
        // Add action to the alert
        alert.addAction(action)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
        
    }
    
    
    
//    // MARK: - Edit existing items
//
//    override func setEditing(_ editing: Bool, animated: Bool) {
//        super.setEditing(editing, animated: true)
//
//        tableView.setEditing(editing, animated: true)
//    }
    
    
    
    
    // MARK: - Model Manipulation Methods
    
//    func saveItems() {
//
//        // this encoder will encode our data (the [Item]) into a property list
////        let encoder = PropertyListEncoder()
//
////        do {
////            // encode our data with the above encoder
////            let data = try encoder.encode(itemArray)
////            // then, write the data to the data file path
////            try data.write(to: dataFilePath!)
////        } catch {
////            print("Error encoding item array, \(error)")
////        }
//
//        do {
//            try context.save()
//        } catch {
//            print("Error saving context \(error)")
//        }
//
//        // reload the tableview
//        self.tableView.reloadData()
//    }
    
    
    
//    func loadItems(with request: NSFetchRequest<Item> = Item.fetchRequest(), predicate: NSPredicate? = nil) {
    func loadItems() {

        todoItems = selectedCategory?.items.sorted(byKeyPath: "title", ascending: true)

        tableView.reloadData()

    }
    
    
    // MARK: - Sorting items
    
    @IBAction func sortOptionChanged(_ sender: Any) {
        
//        if sortByButton.selectedSegmentIndex == 0 {
//            if searchBar.text != "" {
//                todoItems = todoItems?.filter("title CONTAINS[cd] %@", searchBar.text!).sorted(byKeyPath: "title", ascending: true)
//            } else {
//                todoItems = selectedCategory?.items.sorted(byKeyPath: "title", ascending: true)
//            }
//
//            tableView.reloadData()
//        } else {
//
//            if searchBar.text != "" {
//                todoItems = todoItems?.filter("title CONTAINS[cd] %@", searchBar.text!).sorted(byKeyPath: "dateCreated", ascending: true)
//            } else {
//                todoItems = selectedCategory?.items.sorted(byKeyPath: "dateCreated", ascending: true)
//            }
//
//            tableView.reloadData()
//        }
        
        updateTable()
    }
    
    
    
    // MARK: - Delete Data From Swipe
    
    override func updateModel(at indexPath: IndexPath) {
        
        if let itemForDeletion = todoItems?[indexPath.row] {

            do {
                try realm.write {
                    realm.delete(itemForDeletion)
                }
            } catch {
                print("Error deleting item, \(error)")
            }

        }
        
    }
    

}



// MARK: - Search Bar Methods

extension TodoListViewController: UISearchBarDelegate {

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
//        todoItems = todoItems?.filter("title CONTAINS[cd] %@", searchBar.text!).sorted(byKeyPath: "title", ascending: true)
//        todoItems = todoItems?.filter("title CONTAINS[cd] %@", searchBar.text!).sorted(byKeyPath: "dateCreated", ascending: true)
        
        updateTable()
        
//        tableView.reloadData()
    }
    
    
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        dismissKeyboard()
    }

    

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
//        if searchBar.text?.count == 0 {
////            loadItems()
//            updateTable()
//
////            DispatchQueue.main.async {
////                searchBar.resignFirstResponder()
////            }
//        }
        
        updateTable()

    }
    
    
    // Calls this function when the tap is recognized
    @objc func dismissKeyboard() {
        // Causes the view (or one of its embedded text fields) to resign the first responder status
        view.endEditing(true)
    }
    
    
    // Function similar to loadItems, but loads items in sorted order
    func updateTable() {
        if sortByButton.selectedSegmentIndex == 0 {
            if searchBar.text != "" {
                todoItems = todoItems?.filter("title CONTAINS[cd] %@ OR detail CONTAINS[cd] %@", searchBar.text!, searchBar.text!).sorted(byKeyPath: "title", ascending: true)
            } else {
                todoItems = selectedCategory?.items.sorted(byKeyPath: "title", ascending: true)
            }
            
            tableView.reloadData()
        } else {
            
            if searchBar.text != "" {
                todoItems = todoItems?.filter("title CONTAINS[cd] %@ OR detail CONTAINS[cd] %@", searchBar.text!, searchBar.text!).sorted(byKeyPath: "dateCreated", ascending: true)
            } else {
                todoItems = selectedCategory?.items.sorted(byKeyPath: "dateCreated", ascending: true)
            }
            
            tableView.reloadData()
        }
    }

}

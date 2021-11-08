import UIKit

class TableView: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var meals = [Meal]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadSampleMeals()
    }
    
    //MARK: Private Methods
    
    private func loadSampleMeals() {
        
        let photo1 = UIImage(named: "meal1")
        let photo2 = UIImage(named: "meal2")
        let photo3 = UIImage(named: "meal3")
        
        guard let meal1 = Meal(name: "Caprese Salad", photo: photo1) else {
            fatalError("Unable to instantiate meal1")
        }
        
        guard let meal2 = Meal(name: "Chicken and Potatoes", photo: photo2) else {
            fatalError("Unable to instantiate meal2")
        }
        
        guard let meal3 = Meal(name: "Pasta with Meatballs", photo: photo3) else {
            fatalError("Unable to instantiate meal2")
        }
        
        guard let meal4 = Meal(name: "Caprese Salad 4", photo: photo1) else {
            fatalError("Unable to instantiate meal1")
        }
        
        guard let meal5 = Meal(name: "Chicken and Potatoes 5", photo: photo2) else {
            fatalError("Unable to instantiate meal2")
        }
        
        guard let meal6 = Meal(name: "Pasta with Meatballs 6", photo: photo3) else {
            fatalError("Unable to instantiate meal2")
        }
        
        guard let meal7 = Meal(name: "Caprese Salad 7", photo: photo1) else {
            fatalError("Unable to instantiate meal1")
        }
        
        guard let meal8 = Meal(name: "Chicken and Potatoes 8", photo: photo2) else {
            fatalError("Unable to instantiate meal2")
        }
        
        guard let meal9 = Meal(name: "Pasta with Meatballs 9", photo: photo3) else {
            fatalError("Unable to instantiate meal2")
        }
        
        guard let meal10 = Meal(name: "Caprese Salad 10", photo: photo1) else {
            fatalError("Unable to instantiate meal1")
        }
        
        guard let meal11 = Meal(name: "Chicken and Potatoes 11", photo: photo2) else {
            fatalError("Unable to instantiate meal2")
        }
        
        guard let meal12 = Meal(name: "Pasta with Meatballs 12", photo: photo3) else {
            fatalError("Unable to instantiate meal2")
        }
        
        meals += [meal1, meal2, meal3]
        meals += [meal4, meal5, meal6]
        meals += [meal7, meal8, meal9]
        meals += [meal10, meal11, meal12]
    }
    
    //MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return meals.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Table view cells are reused and should be dequeued using a cell identifier.
        let cellIdentifier = "TableViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? TableViewCell  else {
            fatalError("The dequeued cell is not an instance of TableViewCell.")
        }
        
        // Fetches the appropriate meal for the data source layout.
        let meal = meals[indexPath.row]
        
        cell.nameLabel.text = meal.name
        cell.photoImageView.image = meal.photo
        return cell
    }
    
    
}

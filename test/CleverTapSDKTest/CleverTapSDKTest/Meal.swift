import UIKit

class Meal {
    
    //MARK: Properties
    
    var name: String
    var photo: UIImage?
    
    //MARK: Initialization
    
    init?(name: String, photo: UIImage?) {
        
        // The name must not be empty
        guard !name.isEmpty else {
            return nil
        }
        
        // Initialize stored properties.
        self.name = name
        self.photo = photo
    }
}

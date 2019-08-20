import UIKit

class ImageDetailVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewDidLayoutSubviews () {
        super.viewDidLayoutSubviews()
    }
    
    @IBAction func dissmissController() {
        self.dismiss(animated: true, completion: nil)
    }
}

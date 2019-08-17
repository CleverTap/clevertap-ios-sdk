import UIKit

class ViewsVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func dissmissController() {
        self.dismiss(animated: true, completion: nil)
    }
}

import UIKit

class ViewsVC: UIViewController, UIScrollViewDelegate {
    
    @IBOutlet var scrollview: UIScrollView? = UIScrollView()
    
    @IBAction func dissmissController() {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    //    override func viewWillAppear(_ animated: Bool) {
    //        AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.landscapeRight, andRotateTo: UIInterfaceOrientation.landscapeRight)
    //    }
    //
    //    override func viewWillDisappear(_ animated : Bool) {
    //        super.viewWillDisappear(animated)
    //        AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.portrait, andRotateTo: UIInterfaceOrientation.portrait)
    //    }
}

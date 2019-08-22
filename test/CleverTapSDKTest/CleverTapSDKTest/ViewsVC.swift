import UIKit

class ViewsVC: UIViewController, UIScrollViewDelegate {

    @IBOutlet var scrollview: UIScrollView? = UIScrollView()
    
    @IBAction func dissmissController() {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        print("x offset: %@", scrollView.contentOffset.x)
        print("y offset: %@", scrollView.contentOffset.y)
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

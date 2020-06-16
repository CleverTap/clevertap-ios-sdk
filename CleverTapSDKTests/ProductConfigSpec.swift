
import Quick
import Nimble

class ProductConfigSpec: QuickSpec {

    override func spec() {
        
        describe("a CleverTap instance") {
            
            context("when Product Config is") {
                
                it("fetched should fire queue event") {
                    
                    CleverTap.setCredentialsWithAccountID("AccountID", andToken: "Token")
                    
                    let mock = OCSwiftMock<CleverTap>(partialObject: CleverTap.sharedInstance()!)
                    mock.expect().queueEvent(["evtData": ["t": 0], "evtName": "wzrk_fetch"], with: .fetch)
                    
                    mock.object.productConfig.fetch()
                    
                    mock.verify()
                }
            }
        }
    }
}

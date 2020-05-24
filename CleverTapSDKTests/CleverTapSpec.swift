
import Quick
import Nimble
import OCMock
import CleverTapSDK

class CleverTapSpec: QuickSpec {

    override func spec() {
        
        describe("a CleverTap instance") {
            
            context("is initialized") {
                    
                it("with shared instance singleton") {
                    
                    CleverTap.setCredentialsWithAccountID("AccountID", andToken: "Token")
                    
                    let instance = CleverTap.sharedInstance()
                    
                    expect(instance).toNot(beNil())
                }
            }
        }
    }
}

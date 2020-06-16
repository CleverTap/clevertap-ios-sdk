
import Quick
import Nimble

class FeatureFlagSpec: QuickSpec {

    override func spec() {
        
        describe("a CleverTap instance") {
            
            context("when Feature Flags is") {
                
                it("tried to get before correct setup") {
                    
                    CleverTap.setCredentialsWithAccountID("AccountID", andToken: "Token")
                                   
                    let mock = OCSwiftMock<CleverTap>(partialObject: CleverTap.sharedInstance()!)

                    let mockController = OCSwiftMock<CTFeatureFlagsController>(with: CTFeatureFlagsController.self)
                    mockController.reject().get("key", withDefaultValue: true) //expect()

                    mock.object.featureFlags.get("key", withDefaultValue: true)

                    mock.verify()
                    mockController.verify()
                }
            }
        }
    }
}

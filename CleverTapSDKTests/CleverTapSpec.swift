
import Quick
import Nimble
import OCMock
import CleverTapSDK

class CleverTapSpec: QuickSpec {

    override func spec() {
        
        describe("a CleverTap instance") {
            
            context("is initialized with shared instance singleton") {
                  
                it("when AccountID and Token are set") {
                    
                    CleverTap.setCredentialsWithAccountID("AccountID", andToken: "Token")
                    
                    let instance = CleverTap.sharedInstance()
                    
                    expect(instance).toNot(beNil())
                }
                
                it("when Config object is set") {
                    
                    let config = CleverTapInstanceConfig(accountId: "AccountID", accountToken: "Token", accountRegion: "Region")
                    
                    let instance = CleverTap.instance(with: config)
                    
                    expect(instance).toNot(beNil())
                }
            }
            
//            fit("records app launched event when notified") {
//
//                CleverTap.setCredentialsWithAccountID("AccountID", andToken: "Token")
//
//                let mock = OCSwiftMock<CleverTap>(partialObject: CleverTap.sharedInstance()!)
//
//                mock.expect().recordAppLaunched("appEnteredForeground")
//
//                mock.object.notifyApplicationLaunched(withOptions: [:])
//
//                mock.verify()
//            }
        }
        
        describe("a CleverTap class object") {
            
            it("sets Account and Token in Plist Info") {
                CleverTap.setCredentialsWithAccountID("AccountID", andToken: "Token")
                
                let plistInfoInstance = CTPlistInfo.sharedInstance()
                
                expect(plistInfoInstance?.accountId).to(equal("AccountID"))
                expect(plistInfoInstance?.accountToken).to(equal("Token"))
            }
            
            it("enables personalization") {
                CleverTap.enablePersonalization()
                
                let value = CTPreferences.getIntForKey("boolPersonalisationEnabled", withResetValue: 0)
                
                expect(value).to(beTruthy())
            }
            
            it("disbles personalization") {
                CleverTap.disablePersonalization()
                
                let value = CTPreferences.getIntForKey("boolPersonalisationEnabled", withResetValue: 1)
                
                expect(value).toNot(beTruthy())
            }
        }
    }
}

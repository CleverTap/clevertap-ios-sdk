
import Quick
import Nimble

class CleverTapSpec: QuickSpec {

    override func spec() {
        
        describe("a CleverTap instance") {
            
            context("is initialized with shared instance singleton") {
                  
                it("when AccountID and Token are set") {
                    
                    CleverTap.setCredentialsWithAccountID("AccountID", andToken: "Token")
                    
                    let instance = CleverTap.sharedInstance()
                    
                    expect(instance).toNot(beNil())
                }
                
                it("when a Config object is set") {
                    
                    let config = CleverTapInstanceConfig(accountId: "AccountID", accountToken: "Token")
                    
                    let instance = CleverTap.instance(with: config)
                    
                    expect(instance).toNot(beNil())
                }
                
                it("when a Config object with Region is set") {
                    
                    let config = CleverTapInstanceConfig(accountId: "AccountID", accountToken: "Token", accountRegion: "Region")
                    
                    let instance = CleverTap.instance(with: config)
                    
                    expect(instance).toNot(beNil())
                }
            }
            
            it("rejects app launched event when notified from non-app targets") {

                CleverTap.setCredentialsWithAccountID("AccountID", andToken: "Token")

                let mock = OCSwiftMock<CleverTap>(partialObject: CleverTap.sharedInstance()!)

                mock.reject().recordAppLaunched("appEnteredForeground") // expect

                mock.object.notifyApplicationLaunched(withOptions: [:])

                mock.verify()
            }
            
            it("rejects user login event before correct setup") {

                CleverTap.setCredentialsWithAccountID("AccountID", andToken: "Token")

                let mock = OCSwiftMock<CleverTap>(partialObject: CleverTap.sharedInstance()!)

                mock.reject()._asyncSwitchUser([:], withCachedGuid: "", andCleverTapID: "", forAction: "") // expect

                let profile = [
                    "Name": "Jack Montana",
                    "Identity": 61026032,
                    "Email": "jack@gmail.com",
                    "Phone": "+14155551234",
                    "Gender": "M",
                    "MSG-email": false,
                    "MSG-push": true,
                    "MSG-sms": false,
                    "MSG-whatsapp": true,
                    ] as [String : Any]

                mock.object.onUserLogin(profile)

                mock.verify()
            }
            
            it("verifies user location is updated") {
                
                CleverTap.setCredentialsWithAccountID("AccountID", andToken: "Token")

                let mock = OCSwiftMock<CleverTap>(partialObject: CleverTap.sharedInstance()!)
                mock.object.setIsAppForeground(true)
                mock.expect().queueEvent([:], with: .ping)
                
                
                mock.object.setLocation(CLLocationCoordinate2DMake(19.1, 72.9))
                
                mock.verify()
            }
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

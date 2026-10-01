// CTUriHelperTests.swift
// CleverTapSDKTests
//
// Swift Testing suite for CTUriHelper — mirrors CTUriHelperTest.m.
// Uses the modern Swift Testing framework (@Test / @Suite / #expect).
//
// CTUriHelper exposes two stateless class methods (URL/urchin parsing), so a fresh call per
// @Test is sufficient. The header has no nullability annotations, so the NSDictionary returns
// import as IUO ([AnyHashable: Any]!); results are cast to the expected concrete types.

import Testing
import Foundation
@testable import CleverTapSDK

@Suite("CTUriHelper")
struct CTUriHelperTests {

    // MARK: - getUrchinFromUri

    @Test("getUrchinFromUri parses referrer + utm + wzrk medium")
    func getUrchinFromUri() {
        let uri = "https://example.com/?utm_source=google&utm_medium=cpc&utm_campaign=test_campaign&wzrk_medium=email"
        let result = CTUriHelper.getUrchinFromUri(uri, withSourceApp: "clevertap")
        #expect(result["referrer"] as? String == "clevertap")
        #expect(result["us"] as? String == "google")
        #expect(result["um"] as? String == "cpc")
        #expect(result["uc"] as? String == "test_campaign")
        #expect(result["wm"] as? String == "email")
    }

    @Test("getUrchinFromUri with empty sourceApp has no referrer")
    func getUrchinFromUriInvalidSource() {
        let uri = "https://example.com/?utm_source=google&utm_medium=cpc&utm_campaign=test_campaign&wzrk_medium=email"
        let result = CTUriHelper.getUrchinFromUri(uri, withSourceApp: "")
        #expect(result["referrer"] == nil)
    }

    @Test("getUrchinFromUri with invalid wzrk medium has no wm")
    func getUrchinFromUriInvalidMedium() {
        let uri = "https://example.com/?wzrk_medium=invalid"
        let result = CTUriHelper.getUrchinFromUri(uri, withSourceApp: "")
        #expect(result["wm"] == nil)
    }

    @Test("getUrchinFromUri missing utm_source has no us")
    func getUrchinFromUriInvalidUtmOrWzrkValue() {
        let uri = "https://example.com/?utm_medium=cpc&utm_campaign=test_campaign&wzrk_medium=email"
        let result = CTUriHelper.getUrchinFromUri(uri, withSourceApp: "clevertap")
        #expect(result["us"] == nil)
    }

    @Test("getUrchinFromUri empty utm_campaign has no uc")
    func getUrchinFromUriInvalidCampaignValue() {
        let uri = "https://example.com/?utm_medium=cpc&utm_campaign=&wzrk_medium=email"
        let result = CTUriHelper.getUrchinFromUri(uri, withSourceApp: "clevertap")
        #expect(result["uc"] == nil)
    }

    // MARK: - getQueryParameters

    @Test("getQueryParameters with decode")
    func getQueryParametersWithDecode() {
        let url = URL(string: "https://example.com?utm=utmExample&source=exampleSource")
        let params = CTUriHelper.getQueryParameters(url, andDecode: true)
        #expect(params as? [String: String] == ["utm": "utmExample", "source": "exampleSource"])
    }

    @Test("getQueryParameters without decode")
    func getQueryParametersWithoutDecode() {
        let url = URL(string: "https://example.com?utm=utmExample&source=exampleSource")
        let params = CTUriHelper.getQueryParameters(url, andDecode: false)
        #expect(params as? [String: String] == ["utm": "utmExample", "source": "exampleSource"])
    }

    @Test("getQueryParameters with nil URL returns empty")
    func getQueryParametersInvalidURL() {
        let params = CTUriHelper.getQueryParameters(nil, andDecode: false)
        #expect(params.isEmpty == true)
    }

    @Test("getQueryParameters with decode decodes percent-encoding")
    func getQueryParametersWithDecodeDecodesPercentEncoding() {
        let url = URL(string: "https://example.com?name=hello%20world")
        let params = CTUriHelper.getQueryParameters(url, andDecode: true)
        #expect(params["name"] as? String == "hello world")
    }

    @Test("getQueryParameters without decode keeps percent-encoding")
    func getQueryParametersWithoutDecodeKeepsPercentEncoding() {
        let url = URL(string: "https://example.com?name=hello%20world")
        let params = CTUriHelper.getQueryParameters(url, andDecode: false)
        #expect(params["name"] as? String == "hello%20world")
    }

    // MARK: - coverage gaps added in Step 1

    @Test("getUrchinFromUri facebook sourceApp has no referrer")
    func getUrchinFromUriFacebookSourceApp() {
        let uri = "https://example.com/?utm_source=google"
        let result = CTUriHelper.getUrchinFromUri(uri, withSourceApp: "fb123456")
        #expect(result["referrer"] == nil)
    }

    @Test("getUrchinFromUri falls back to wzrk_source")
    func getUrchinFromUriWzrkSourceFallback() {
        let uri = "https://example.com/?wzrk_source=push"
        let result = CTUriHelper.getUrchinFromUri(uri, withSourceApp: "")
        #expect(result["us"] as? String == "push")
    }

    @Test("getUrchinFromUri wzrk medium social is accepted")
    func getUrchinFromUriWzrkMediumSocial() {
        let uri = "https://example.com/?wzrk_medium=social"
        let result = CTUriHelper.getUrchinFromUri(uri, withSourceApp: "")
        #expect(result["wm"] as? String == "social")
    }

    @Test("getQueryParameters skips a segment without =")
    func getQueryParametersParamWithoutEquals() {
        let url = URL(string: "https://example.com?flag&key=value")
        let params = CTUriHelper.getQueryParameters(url, andDecode: false)
        #expect(params["flag"] == nil)
        #expect(params["key"] as? String == "value")
    }
}

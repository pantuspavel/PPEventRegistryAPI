//
//  PPTransportSpec.swift
//  PPEventRegistryAPI
//
//  Created by Pavel Pantus on 7/16/16.
//  Copyright © 2016 Pavel Pantus. All rights reserved.
//

import Quick
import Nimble
import OHHTTPStubs
@testable import PPEventRegistryAPI

class PPTransportSpec: QuickSpec {
    override func spec() {

        describe("HttpMethod") {

            it ("Get case is in place") {
                expect(PPHttpMethod(rawValue: "Get")).to(equal(PPHttpMethod.Get))
            }

            it ("Post case is in place") {
                expect(PPHttpMethod(rawValue: "Post")).to(equal(PPHttpMethod.Post))
            }

        }

        describe("Controller") {

            it("Login controller is in place") {
                expect(PPController(rawValue: "Login")).to(equal(PPController.Login))
            }

            it("Overview controller is in place") {
                expect(PPController(rawValue: "Overview")).to(equal(PPController.Overview))
            }

            it("Event controller is in place") {
                expect(PPController(rawValue: "Event")).to(equal(PPController.Event))
            }

        }

        describe("postRequest") {

            let transport = PPTransport()

            beforeEach() {
                PPTransport.stubEmptyResponse()
            }

            afterEach() {
                OHHTTPStubs.removeAllStubs()
            }

            it("is safe to use from multiple threads") {
                waitUntil(timeout: 5) { done in
                    DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
                        for _ in 1...100 {
                            transport.postRequest(controller: .Event, method: .Get, parameters: [:]) { _ in }
                        }
                    }
                    DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async {
                        for _ in 1...100 {
                            transport.postRequest(controller: .Overview, method: .Post, parameters: [:]) { _ in }
                        }
                    }
                    DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async {
                        for _ in 1...130 {
                            transport.postRequest(controller: .Overview, method: .Post, parameters: [:]) { _ in }
                        }
                        done()
                    }
                    DispatchQueue.global(qos: DispatchQoS.QoSClass.utility).async {
                        for _ in 1...100 {
                            transport.postRequest(controller: .Overview, method: .Post, parameters: [:]) { _ in }
                        }
                    }
                    DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive).async {
                        for _ in 1...100 {
                            transport.postRequest(controller: .Login, method: .Get, parameters: [:]) { _ in }
                        }
                    }
                }
            }

            it("calls back with 'Response Data is Corrupt' error in case of invalid network response") {
                PPTransport.stubInvalidResponse()
                waitUntil { done in
                    transport.postRequest(controller: .Login, method: .Post, parameters: [:], completionHandler: { result in
                        expect(result.error!.debugDescription).to(equal("CorruptedResponse"))
                        done()
                    })
                }
            }

            it("calls back with 'Network Error' in case of network error") {
                PPTransport.stubErrorResponse()
                waitUntil { done in
                    transport.postRequest(controller: .Login, method: .Post, parameters: [:], completionHandler: { result in
                        expect(result.error!).to(equal(PPError.NetworkError("The operation couldn’t be completed. (NSURLErrorDomain error -1009.)")))
                        done()
                    })
                }
            }
        }

        describe("request(with: method: parameters:)") {

            let transport = PPTransport()

            it("returns correct request for .Overview and .Get") {
                let urlRequest = transport.request(with: .Overview, method: .Get, parameters: ["key1":"value1"])
                expect(urlRequest.url).to(equal(URL(string: "http://eventregistry.org/json/overview?key1=value1")!))
                expect(urlRequest.httpMethod).to(equal("GET"))
                expect(urlRequest.value(forHTTPHeaderField: "Content-Type")).to(equal("application/json"))
                expect(urlRequest.value(forHTTPHeaderField: "Accept")).to(equal("application/json"))
            }

            it("returns correct request for .Login and .Post") {
                let urlRequest = transport.request(with: .Login, method: .Post, parameters: ["key1@":"value1"])
                expect(urlRequest.url).to(equal(URL(string: "http://eventregistry.org/login")!))
                expect(urlRequest.httpBody).to(equal(["key1@":"value1"].pp_join().addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)?.data(using: .utf8)))
                expect(urlRequest.httpMethod).to(equal("POST"))
                expect(urlRequest.value(forHTTPHeaderField: "Content-Type")).to(equal("application/x-www-form-urlencoded"))
                expect(urlRequest.value(forHTTPHeaderField: "Accept")).to(equal("application/json"))
            }

        }

        describe("baseURI") {

            var transport = PPTransport()

            beforeEach {
                transport = PPTransport()
            }

            it("has http scheme by default") {
                expect(transport.baseURI).to(equal("http://eventregistry.org"))
            }

            it("can be changed to https scheme") {
                transport.transferProtocol = .https
                expect(transport.baseURI).to(equal("https://eventregistry.org"))
            }

            it("can be changed to http scheme") {
                transport.transferProtocol = .http
                expect(transport.baseURI).to(equal("http://eventregistry.org"))
            }
        }

    }
}

//
//  QIskitParserTerminalTests.swift
//  qiskit
//
//  Created by Joe Ligman on 5/26/17.
//  Copyright © 2017 IBM. All rights reserved.
//

import XCTest
import qiskit

class QIskitParserTerminalTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testParserREAL() {
        
        let asyncExpectation = self.expectation(description: "parser")
        
        let buf: YY_BUFFER_STATE = yy_scan_string("5.0")
        
        ParseSuccessBlock = { (node: Node?) -> Void in
            XCTAssertNotNil(node)
            guard let nr = node as? NodeReal else {
                XCTFail("Real Node Type Expected!")
                asyncExpectation.fulfill()
                return
            }
            XCTAssertEqual(5.0, nr.real)
            asyncExpectation.fulfill()
        }
        
        ParseFailBlock = { (message: String?) -> Void in
            if let msg = message {
                XCTFail(msg)
            } else {
                XCTFail("Unknown Error")
            }
            asyncExpectation.fulfill()
        }
        
        yyparse()
        yy_delete_buffer(buf)
        
        self.waitForExpectations(timeout: 180, handler: { (error) in
            XCTAssertNil(error, "Failure in parser")
        })
    }
    
    func testParserNNINTEGER() {
        
        let asyncExpectation = self.expectation(description: "parser")
        
        let buf: YY_BUFFER_STATE = yy_scan_string("5")
        
        ParseSuccessBlock = { (node: Node?) -> Void in
            XCTAssertNotNil(node)
            guard let nni = node as? NodeNNInt else {
                XCTFail("Real Node Type Expected!")
                asyncExpectation.fulfill()
                return
            }
            XCTAssertEqual(5, nni.value)
            asyncExpectation.fulfill()
        }
        
        ParseFailBlock = { (message: String?) -> Void in
            if let msg = message {
                XCTFail(msg)
            } else {
                XCTFail("Unknown Error")
            }
            asyncExpectation.fulfill()
        }
        
        yyparse()
        yy_delete_buffer(buf)
        
        self.waitForExpectations(timeout: 180, handler: { (error) in
            XCTAssertNil(error, "Failure in parser")
        })
    }


    func testParserId() {
        
        let asyncExpectation = self.expectation(description: "parser")
        
        let buf: YY_BUFFER_STATE = yy_scan_string("theidtofind")
        
        ParseSuccessBlock = { (node: Node?) -> Void in
            XCTAssertNotNil(node)
            guard let idn = node as? NodeId else {
                XCTFail("Id Node Type Expected!")
                asyncExpectation.fulfill()
                return
            }
            XCTAssertEqual("theidtofind", idn.name)
            asyncExpectation.fulfill()
        }
        
        ParseFailBlock = { (message: String?) -> Void in
            if let msg = message {
                XCTFail(msg)
            } else {
                XCTFail("Unknown Error")
            }
            asyncExpectation.fulfill()
        }
        
        yyparse()
        yy_delete_buffer(buf)
        
        self.waitForExpectations(timeout: 180, handler: { (error) in
            XCTAssertNil(error, "Failure in parser")
        })
    }


}

// Copyright 2017 IBM RESEARCH. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// =============================================================================


import Foundation

/*
 Node for an OPENQASM creg statement.
children[0] is an indexedid node.
*/
@objc public final class NodeCreg: Node {

    public let indexedid: Node?
    public var _name: String = ""
    public var line: Int = 0
    public var file: String = ""
    public var index: Int = 0
    
    public init(indexedid: Node?, line: Int, file: String) {
        
        self.indexedid = indexedid
        if let _id = self.indexedid as? NodeIndexedId {
            // Name of the qreg
            self._name = _id.name
            // Source line number
            self.line = _id.line
            // Source file name
            self.file = _id.file
            // Size of the register
            self.index = _id.index
        }
    }

    public override var type: NodeType {
        return .N_CREG
    }
    
    public override var name: String {
        return _name
    }
    
    public override var children: [Node] {
        var _children: [Node] = []
        if let a = indexedid {
            _children.append(a)
        }
        return _children
    }
    
    public override func qasm() -> String {
        guard let iid = indexedid else {
            assertionFailure("Invalid NodeQreg Operation")
            return ""
        }
        return "creg " + iid.qasm() + ";"
    }
    

}
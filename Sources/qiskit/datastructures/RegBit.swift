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

public typealias TupleRegBit = HashableTuple<RegBit,RegBit>

public struct RegBit: Hashable, CustomStringConvertible {

    private let tuple: HashableTuple<String,Int>

    public var name: String {
        return self.tuple.one
    }
    public var index: Int {
        return self.tuple.two
    }
    public var qasm: String {
        return RegBit.qasm(self.name,self.index)
    }
    public var description: String {
        return self.qasm
    }

    public init(_ name: String, _ index: Int) {
        self.tuple = HashableTuple<String,Int>(name,index)
    }

    public init(_ value: (String,Int)) {
        self.tuple = HashableTuple<String,Int>(value.0,value.1)
    }

    public static func qasm(_ name: String, _ index: Int) -> String {
        return "\(name)[\(index)]"
    }

    public var hashValue : Int {
        get {
            return self.tuple.hashValue
        }
    }
    public static func ==(lhs: RegBit, rhs:RegBit) -> Bool {
        return lhs.tuple == rhs.tuple
    }
}

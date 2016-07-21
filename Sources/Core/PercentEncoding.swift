/**
    These are global functions because I can't extend array, and
    it's considerably easier than dealing with sequence or collection

    It is also helpful when parsing to percent encode without converting to string

    Wrappers around String can be built
*/

/**
    Percent decodes an array slice.
 
    - see: percentDecoded(_: Bytes, nonEncodedTransform: (Byte) -> (Byte)) -> [Byte]
*/
public func percentDecoded(_ input: ArraySlice<Byte>, nonEncodedTransform: (Byte) -> (Byte) = { $0 }) -> Bytes? {
    return percentDecoded(Array(input), nonEncodedTransform: nonEncodedTransform)
}

/**
    Percent decodes an array of bytes.
 
    - param input: The percent encoded array of bytes.
    - param nonEncodedTransform: Converts non percent-encoded
        bytes by passing through the clsoure.
        This is useful for cases like converting `+`
        to spaces in percent-encoded URL strings.
 
    - return: Returns the decoded array of bytes
        or returns `nil` if the bytes could not
        be decoded.
*/
public func percentDecoded(_ input: Bytes, nonEncodedTransform: (Byte) -> (Byte) = { $0 }) -> [Byte]? {
    var idx = 0
    var group: [Byte] = []
    while idx < input.count {
        let next = input[idx]
        if next == .percent {
            // %  2  A
            // i +1 +2
            let firstHex = idx + 1
            let secondHex = idx + 2
            idx = secondHex + 1

            guard secondHex < input.count else { return nil }
            let bytes = input[firstHex...secondHex].array

            let str = bytes.string
            guard
                !str.isEmpty,
                let encodedByte = Byte(str, radix: 16)
            else {
                return nil
            }

            group.append(encodedByte)
        } else {
            let transformed = nonEncodedTransform(next)
            group.append(transformed)
            idx += 1 // don't put outside of else
        }
    }
    return group
}

public func percentEncoded(_ input: [Byte], shouldEncode: (Byte) throws -> Bool = { _ in true }) throws -> [Byte] {
    var group: [Byte] = []
    try input.forEach { byte in
        if try shouldEncode(byte) {
            let hex = String(byte, radix: 16).utf8
            group.append(.percent)
            if hex.count == 1 {
                group.append(.zero)
            }
            group.append(contentsOf: hex)
        } else {
            group.append(byte)
        }
    }
    return group
}

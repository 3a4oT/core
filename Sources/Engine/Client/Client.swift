public enum ClientError: ErrorProtocol {
    case missingHost
}

public protocol Client: Responder {
    var host: String { get }
    var port: Int { get }
    var scheme: String { get }
    var stream: Stream { get }
    init(scheme: String, host: String, port: Int) throws
}

extension Client {
    public static func make(scheme: String? = nil, host: String, port: Int? = nil) throws -> Self {
        let scheme = scheme ?? "https" // default to secure https connection
        let port = port ?? URI.defaultPorts[scheme] ?? 80
        return try Self(scheme: scheme, host: host, port: port)
    }
}

extension Client {
    public func request(_ method: Method, path: String, headers: Headers = [:], query: [String: StructuredDataRepresentable] = [:], body: HTTPBody = []) throws -> Response {
        // TODO: Move finish("/") to initializer
        var uri = URI(scheme: scheme, userInfo: nil, host: host, port: port, path: path.finished(with: "/"), query: nil, fragment: nil)
        uri.append(query: StructuredData(query))
        let request = Request(method: method, uri: uri, version: Version(major: 1, minor: 1), headers: headers, body: body)
        return try respond(to: request)
    }

    public func get(path: String, headers: Headers = [:], query: [String: StructuredDataRepresentable] = [:], body: HTTPBody = []) throws -> Response {
        return try request(.get, path: path, headers: headers, query: query, body: body)
    }

    public func post(path: String, headers: Headers = [:], query: [String: StructuredDataRepresentable] = [:], body: HTTPBody = []) throws -> Response {
        return try request(.post, path: path, headers: headers, query: query, body: body)
    }

    public func put(path: String, headers: Headers = [:], query: [String: StructuredDataRepresentable] = [:], body: HTTPBody = []) throws -> Response {
        return try request(.put, path: path, headers: headers, query: query, body: body)
    }

    public func patch(path: String, headers: Headers = [:], query: [String: StructuredDataRepresentable] = [:], body: HTTPBody = []) throws -> Response {
        return try request(.patch, path: path, headers: headers, query: query, body: body)
    }

    public func delete(_ path: String, headers: Headers = [:], query: [String: StructuredDataRepresentable] = [:], body: HTTPBody = []) throws -> Response {
        return try request(.delete, path: path, headers: headers, query: query, body: body)
    }
}

extension Client {
    public static func respond(to request: Request) throws -> Response {
        guard let host = request.uri.host else { throw ClientError.missingHost }
        let instance = try Self.make(scheme: request.uri.scheme, host: host, port: request.uri.port)
        return try instance.respond(to: request)
    }

    public static func request(_ method: Method, _ uri: String, headers: Headers = [:], query: [String: StructuredDataRepresentable], body: HTTPBody = []) throws -> Response {
        var uri = try URI(uri)
        let structure = StructuredData(query)
        // Always append query incase URI also contains query
        uri.append(query: structure)
        let request = Request(method: method, uri: uri, headers: headers, body: body)
        return try respond(to: request)
    }

    public static func get(_ uri: String, headers: Headers = [:], query: [String: StructuredDataRepresentable] = [:], body: HTTPBody = []) throws -> Response {
        return try request(.get, uri, headers: headers, query: query, body: body)
    }

    public static func post(_ uri: String, headers: Headers = [:], query: [String: StructuredDataRepresentable] = [:], body: HTTPBody = []) throws -> Response {
        return try request(.post, uri, headers: headers, query: query, body: body)
    }

    public static func put(_ uri: String, headers: Headers = [:], query: [String: StructuredDataRepresentable] = [:], body: HTTPBody = []) throws -> Response {
        return try request(.put, uri, headers: headers, query: query, body: body)
    }

    public static func patch(_ uri: String, headers: Headers = [:], query: [String: StructuredDataRepresentable] = [:], body: HTTPBody = []) throws -> Response {
        return try request(.patch, uri, headers: headers, query: query, body: body)
    }

    public static func delete(_ uri: String, headers: Headers = [:], query: [String: StructuredDataRepresentable] = [:], body: HTTPBody = []) throws -> Response {
        return try request(.delete, uri, headers: headers, query: query, body: body)
    }
}

// TODO: From Vapor, bring in file

extension HTTPBody {
    public var bytes: Bytes? {
        guard case let .data(bytes) = self else { return nil }
        return bytes
    }
}

extension HTTPBody {
    public init(_ str: String) {
        self.init(str.bytes)
    }

    public init<S: Sequence where S.Iterator.Element == Byte>(_ s: S) {
        self = .data(s.array)
    }
}

extension HTTPBody: ArrayLiteralConvertible {
    /// Creates an instance initialized with the given elements.
    public init(arrayLiteral elements: Byte...) {
        self.init(elements)
    }
}

// MARK: StructuredData + Initializers

extension StructuredData {
    public init(_ representableObject: [String: StructuredDataRepresentable]) {
        var object: [String: StructuredData] = [:]
        representableObject.forEach { key, val in
            object[key] = val.structuredData
        }
        self = .dictionary(object)
    }
}

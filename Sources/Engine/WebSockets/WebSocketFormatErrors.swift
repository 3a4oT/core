extension WebSocket {
    public enum FormatError: ErrorProtocol {
        case missingSecKeyHeader
        case missingSecAcceptHeader
        case invalidSecAcceptHeader
        case missingUpgradeHeader
        case missingConnectionHeader
        case invalidURI
        case invalidOrUnsupportedVersion
        case invalidOrUnsupportedStatus
    }
}

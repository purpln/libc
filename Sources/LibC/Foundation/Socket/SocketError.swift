public enum SocketError: String, Error {
    case ipv4SocketCreateIvalidArgument = "error create sockaddr_in: ivalid argument"
    case ipv6SocketCreateIvalidArgument = "error create sockaddr_in6: ivalid argument"
    case unixSocketCreateIvalidArgument = "error create sockaddr_un: ivalid argument"
    
    case invalidPort
    case invalidAddress
}

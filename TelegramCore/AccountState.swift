import Foundation
#if os(macOS)
    import PostboxMac
#else
    import Postbox
#endif


private enum SentAuthorizationCodeTypeValue: Int32 {
    case otherSession = 0
    case sms = 1
    case call = 2
    case flashCall = 3
}

public enum SentAuthorizationCodeType: Coding, Equatable {
    case otherSession(length: Int32)
    case sms(length: Int32)
    case call(length: Int32)
    case flashCall(pattern: String)
    
    public init(decoder: Decoder) {
        switch decoder.decodeInt32ForKey("v") as Int32 {
            case SentAuthorizationCodeTypeValue.otherSession.rawValue:
                self = .otherSession(length: decoder.decodeInt32ForKey("l"))
            case SentAuthorizationCodeTypeValue.sms.rawValue:
                self = .sms(length: decoder.decodeInt32ForKey("l"))
            case SentAuthorizationCodeTypeValue.call.rawValue:
                self = .call(length: decoder.decodeInt32ForKey("l"))
            case SentAuthorizationCodeTypeValue.flashCall.rawValue:
                self = .flashCall(pattern: decoder.decodeStringForKey("p"))
            default:
                preconditionFailure()
        }
    }
    
    public func encode(_ encoder: Encoder) {
        switch self {
            case let .otherSession(length):
                encoder.encodeInt32(SentAuthorizationCodeTypeValue.otherSession.rawValue, forKey: "v")
                encoder.encodeInt32(length, forKey: "l")
            case let .sms(length):
                encoder.encodeInt32(SentAuthorizationCodeTypeValue.sms.rawValue, forKey: "v")
                encoder.encodeInt32(length, forKey: "l")
            case let .call(length):
                encoder.encodeInt32(SentAuthorizationCodeTypeValue.call.rawValue, forKey: "v")
                encoder.encodeInt32(length, forKey: "l")
            case let .flashCall(pattern):
                encoder.encodeInt32(SentAuthorizationCodeTypeValue.flashCall.rawValue, forKey: "v")
                encoder.encodeString(pattern, forKey: "p")
        }
    }
    
    public static func ==(lhs: SentAuthorizationCodeType, rhs: SentAuthorizationCodeType) -> Bool {
        switch lhs {
            case let .otherSession(length):
                if case .otherSession(length) = rhs {
                    return true
                } else {
                    return false
                }
            case let .sms(length):
                if case .sms(length) = rhs {
                    return true
                } else {
                    return false
                }
            case let .call(length):
                if case .call(length) = rhs {
                    return true
                } else {
                    return false
                }
            case let .flashCall(pattern):
                if case .flashCall(pattern) = rhs {
                    return true
                } else {
                    return false
                }
        }
    }
}

public enum AuthorizationCodeNextType: Int32 {
    case sms = 0
    case call = 1
    case flashCall = 2
}

private enum UnauthorizedAccountStateContentsValue: Int32 {
    case empty = 0
    case phoneEntry = 1
    case confirmationCodeEntry = 2
    case passwordEntry = 3
}

public enum UnauthorizedAccountStateContents: Coding {
    case empty
    case phoneEntry(countryCode: Int32, number: String)
    case confirmationCodeEntry(number: String, type: SentAuthorizationCodeType, hash: String, timeout: Int32?, nextType: AuthorizationCodeNextType?)
    case passwordEntry(hint: String)
    
    public init(decoder: Decoder) {
        switch decoder.decodeInt32ForKey("v") as Int32 {
            case UnauthorizedAccountStateContentsValue.empty.rawValue:
                self = .empty
            case UnauthorizedAccountStateContentsValue.phoneEntry.rawValue:
                self = .phoneEntry(countryCode: decoder.decodeInt32ForKey("cc"), number: decoder.decodeStringForKey("n"))
            case UnauthorizedAccountStateContentsValue.confirmationCodeEntry.rawValue:
                var nextType: AuthorizationCodeNextType?
                if let value = decoder.decodeInt32ForKey("nt") as Int32? {
                    nextType = AuthorizationCodeNextType(rawValue: value)
                }
                self = .confirmationCodeEntry(number: decoder.decodeStringForKey("num"), type: decoder.decodeObjectForKey("t", decoder: { SentAuthorizationCodeType(decoder: $0) }) as! SentAuthorizationCodeType, hash: decoder.decodeStringForKey("h"), timeout: decoder.decodeInt32ForKey("tm"), nextType: nextType)
            case UnauthorizedAccountStateContentsValue.passwordEntry.rawValue:
                self = .passwordEntry(hint: decoder.decodeStringForKey("h"))
            default:
                assertionFailure()
                self = .empty
        }
    }
    
    public func encode(_ encoder: Encoder) {
        switch self {
            case .empty:
                encoder.encodeInt32(UnauthorizedAccountStateContentsValue.empty.rawValue, forKey: "v")
            case let .phoneEntry(countryCode, number):
                encoder.encodeInt32(UnauthorizedAccountStateContentsValue.phoneEntry.rawValue, forKey: "v")
                encoder.encodeInt32(countryCode, forKey: "cc")
                encoder.encodeString(number, forKey: "n")
            case let .confirmationCodeEntry(number, type, hash, timeout, nextType):
                encoder.encodeInt32(UnauthorizedAccountStateContentsValue.confirmationCodeEntry.rawValue, forKey: "v")
                encoder.encodeString(number, forKey: "num")
                encoder.encodeObject(type, forKey: "t")
                encoder.encodeString(hash, forKey: "h")
                if let timeout = timeout {
                    encoder.encodeInt32(timeout, forKey: "tm")
                } else {
                    encoder.encodeNil(forKey: "tm")
                }
                if let nextType = nextType {
                    encoder.encodeInt32(nextType.rawValue, forKey: "nt")
                } else {
                    encoder.encodeNil(forKey: "nt")
                }
            case let .passwordEntry(hint):
                encoder.encodeInt32(UnauthorizedAccountStateContentsValue.passwordEntry.rawValue, forKey: "v")
                encoder.encodeString(hint, forKey: "h")
        }
    }
}

public final class UnauthorizedAccountState: Coding {
    public let masterDatacenterId: Int32
    public let contents: UnauthorizedAccountStateContents
    
    public init(masterDatacenterId: Int32, contents: UnauthorizedAccountStateContents) {
        self.masterDatacenterId = masterDatacenterId
        self.contents = contents
    }
    
    public init(decoder: Decoder) {
        self.masterDatacenterId = decoder.decodeInt32ForKey("dc")
        self.contents = decoder.decodeObjectForKey("c", decoder: { UnauthorizedAccountStateContents(decoder: $0) }) as! UnauthorizedAccountStateContents
    }
    
    public func encode(_ encoder: Encoder) {
        encoder.encodeInt32(self.masterDatacenterId, forKey: "dc")
        encoder.encodeObject(self.contents, forKey: "c")
    }
}

public extension SentAuthorizationCodeType {
    init(apiType: Api.auth.SentCodeType) {
        switch apiType {
            case let .sentCodeTypeApp(length):
                self = .otherSession(length: length)
            case let .sentCodeTypeSms(length):
                self = .sms(length: length)
            case let .sentCodeTypeCall(length):
                self = .call(length: length)
            case let .sentCodeTypeFlashCall(pattern):
                self = .flashCall(pattern: pattern)
        }
    }
}

public extension AuthorizationCodeNextType {
    init(apiType: Api.auth.CodeType) {
        switch apiType {
            case .codeTypeSms:
                self = .sms
            case .codeTypeCall:
                self = .call
            case .codeTypeFlashCall:
                self = .flashCall
        }
    }
}
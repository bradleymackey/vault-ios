import Foundation

func anyData() -> Data {
    Data(hex: "FF")
}

func emptyData() -> Data {
    Data()
}

enum OTPRFCSecret {
    static var `default`: Data {
        Data(byteString: "12345678901234567890")
    }

    static var sha1: Data {
        Data(byteString: "12345678901234567890")
    }

    static var sha256: Data {
        Data(byteString: "12345678901234567890123456789012")
    }

    static var sha512: Data {
        Data(byteString: "1234567890123456789012345678901234567890123456789012345678901234")
    }
}

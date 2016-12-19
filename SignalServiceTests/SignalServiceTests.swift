import XCTest
@testable import SignalService

class Tests: XCTestCase {
    func testKeyGeneration() {
        let aliceAddress = SignalAddress(name: "alice", deviceId: 1)
        let bobAddress = SignalAddress(name: "bob", deviceId: 1)

        // Generate alice receiver data
        let aliceInMemorySignalStore = SignalStoreInMemoryStorage()
        let aliceStorage = SignalStorage(signalStore: aliceInMemorySignalStore)
        let aliceContext = SignalContext(storage: aliceStorage)
        let aliceKeyHelper = SignalKeyHelper(context: aliceContext)

        let aliceIdentityKeyPair = aliceKeyHelper.generateIdentityKeyPair()
        let aliceRegistrationId = aliceKeyHelper.generateRegistrationId()

        let alicePrekeys = aliceKeyHelper.generatePreKeys(withStartingPreKeyId: 0, count: 100)
        // let aliceLastResortPreKey = aliceKeyHelper.generateLastResortPreKey()
        let aliceSignedPreKey = aliceKeyHelper.generateSignedPreKey(withIdentity: aliceIdentityKeyPair, signedPreKeyId: 0)
        let aliceFirstPreKey = alicePrekeys.first!

        aliceInMemorySignalStore.identityKeyPair = aliceIdentityKeyPair
        aliceInMemorySignalStore.localRegistrationId = aliceRegistrationId
        aliceInMemorySignalStore.storePreKey(aliceFirstPreKey.serializedData(), preKeyId: 0)
        aliceInMemorySignalStore.storeSignedPreKey(aliceSignedPreKey.serializedData(), signedPreKeyId: 0)

        let alicePreKeyPublicData = Data(base64Encoded: aliceFirstPreKey.keyPair().publicKey.base64EncodedStringWithoutPadding().paddedForBase64)!
        let aliceSignedPreKeyPublicData = Data(base64Encoded: aliceSignedPreKey.keyPair().publicKey.base64EncodedStringWithoutPadding().paddedForBase64)!
        let aliceSignatureData = Data(base64Encoded: aliceSignedPreKey.signature().base64EncodedStringWithoutPadding().paddedForBase64)!
        let aliceIdentityKeyPublicData = Data(base64Encoded: aliceIdentityKeyPair.publicKey.base64EncodedStringWithoutPadding().paddedForBase64)!

        let alicePreKeyBundle = SignalPreKeyBundle(registrationId: aliceRegistrationId, deviceId: 1, preKeyId: 0, preKeyPublic: alicePreKeyPublicData, signedPreKeyId: 0, signedPreKeyPublic: aliceSignedPreKeyPublicData, signature: aliceSignatureData, identityKey: aliceIdentityKeyPublicData)

        // Generate bob sender data
        let bobInMemorySignalStore = SignalStoreInMemoryStorage()
        let bobStorage = SignalStorage(signalStore: bobInMemorySignalStore)
        let bobContext = SignalContext(storage: bobStorage)
        let bobKeyHelper = SignalKeyHelper(context: bobContext)

        let bobIdentityKeyPair = bobKeyHelper.generateIdentityKeyPair()
        let bobRegistrationId = bobKeyHelper.generateRegistrationId()

        bobInMemorySignalStore.identityKeyPair = bobIdentityKeyPair
        bobInMemorySignalStore.localRegistrationId = bobRegistrationId

        let bobSessionBuilder = SignalSessionBuilder(address: aliceAddress, context: bobContext)
        bobSessionBuilder.processPreKeyBundle(alicePreKeyBundle)
        let bobSessionCipher = SignalSessionCipher(address: aliceAddress, context: bobContext)

        // Create encrypted message to be sent
        let sentMessage = "Hey it's Bob 🚀!"
        let messageData = sentMessage.data(using: .utf8)!
        let bobMessageCiphertext = try! bobSessionCipher.encryptData(messageData)

        // Create receiver session to decrypt message
        let aliceSessionCipher = SignalSessionCipher(address: bobAddress, context: aliceContext)
        let decryptedData = try! aliceSessionCipher.decryptCiphertext(bobMessageCiphertext)
        let decryptedMessage = String(data: decryptedData, encoding: .utf8)!

        XCTAssertEqual(sentMessage, decryptedMessage)
    }
}

extension Data {
    public func base64EncodedStringWithoutPadding() -> String {
        let base64 = self.base64EncodedString()
        if base64.hasSuffix("==") {
            return base64.substring(to: base64.index(base64.endIndex, offsetBy: -2))
        } else if base64.hasSuffix("=") {
            return base64.substring(to: base64.index(base64.endIndex, offsetBy: -1))
        }

        return base64
    }
}

public extension String {
    public var paddedForBase64: String {
        let length = self.decomposedStringWithCanonicalMapping.characters.count
        let paddingString = "="
        let paddingLength = length % 4

        if paddingLength > 0 {
            let paddingCharCount = 4 - paddingLength

            return self.padding(toLength: length + paddingCharCount, withPad: paddingString, startingAt: 0)
        } else {
            return self
        }
    }
}

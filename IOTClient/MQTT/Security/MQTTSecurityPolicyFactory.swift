import MQTTClient

protocol MQTTSecurityPolicyCreating {
    func createSecurityPolicy() -> MQTTSSLSecurityPolicy
}

final class MQTTSecurityPolicyFactory: MQTTSecurityPolicyCreating {
    func createSecurityPolicy() -> MQTTSSLSecurityPolicy {
        let policy = MQTTSSLSecurityPolicy(pinningMode: .certificate)
        policy?.allowInvalidCertificates = true
        policy?.validatesDomainName = false
        policy?.validatesCertificateChain = false

        if let certPath = Bundle.main.path(forResource: "certificate", ofType: "der"),
            let certData = try? Data(contentsOf: URL(fileURLWithPath: certPath))
        {
            policy?.pinnedCertificates = [certData]
        }

        return policy!
    }
}

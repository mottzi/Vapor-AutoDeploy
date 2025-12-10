import Vapor

extension Application.Deployer
{
    func useWebhook(config: Configuration, on app: Application)
    {
        let accepted = Response(status: .ok, body: .init(stringLiteral: "Push event accepted."))
        let denied = Response(status: .forbidden, body: .init(stringLiteral: "Push event denied."))
        
        app.post(config.pusheventPath)
        { request async -> Response in
            
            guard Webhook.validateSignature(of: request) else { return denied }
            
            guard let payload = request.payload else { return accepted }
            
            for config in Webhook.affectedProductConfigs(config: config, payload: payload)
            {
                Task.detached
                {
                    let pipeline = Pipeline(config: config)
                    await pipeline.deploy(message: payload.headCommit.message, on: app)
                }
            }
            
            return accepted
        }
    }
}

extension Application.Deployer
{
    struct Webhook
    {
        static func validateSignature(of request: Request) -> Bool
        {
            let secret = Environment.Variables.GITHUB_WEBHOOK_SECRET.value
            guard let secretData = secret.data(using: .utf8) else { return false }

            guard let signatureHeader = request.headers.first(name: "X-Hub-Signature-256") else { return false }
            guard signatureHeader.hasPrefix("sha256=") else { return false }
            let signatureHex = String(signatureHeader.dropFirst("sha256=".count))

            guard let payload = request.body.string else { return false }
            guard let payloadData = payload.data(using: .utf8) else { return false }

            let secretDataKey = SymmetricKey(data: secretData)
            let signature = HMAC<SHA256>.authenticationCode(for: payloadData, using: secretDataKey)
            let expectedSignatureHex = signature.map { String(format: "%02x", $0) }.joined()
            guard expectedSignatureHex.count == signatureHex.count else { return false }

            return HMAC<SHA256>.isValidAuthenticationCode(
                signatureHex.hexadecimal ?? Data(),
                authenticating: payloadData,
                using: secretDataKey
            )
        }
        
        static func affectedProductConfigs(config: Configuration, payload: Webhook.Payload) -> [Pipeline.Configuration]
        {
            let allChangedFiles = payload.commits.flatMap { $0.added + $0.modified + $0.removed }
            
            let configs: [Pipeline.Configuration] = [
                .init(productName: config.serverProduct, workingDirectory: config.workingDirectory, buildConfiguration: config.buildConfiguration),
                .init(productName: config.deployerProduct, workingDirectory: config.workingDirectory, buildConfiguration: config.buildConfiguration)
            ]
            
            guard !allChangedFiles.contains(where: { $0 == "Package.swift" || $0 == "Package.resolved" }) else { return configs }
            
            return configs.filter
            { config in
                allChangedFiles.contains
                { file in
                    file.hasPrefix("Sources/\(config.productName)/")
                }
            }
        }
    }
}

extension Application.Deployer.Webhook
{
    struct Payload: Codable
    {
        let headCommit: Commit
        let commits: [Commit]
        
        struct Commit: Codable
        {
            let message: String
            let added: [String]
            let modified: [String]
            let removed: [String]
        }
    }
}

extension Request
{
    typealias Payload = Application.Deployer.Webhook.Payload

    var payload: Payload?
    {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        guard let bodyString = self.body.string else { return nil }
        guard let jsonData = bodyString.data(using: .utf8) else { return nil }
        
        return try? decoder.decode(Payload.self, from: jsonData)
    }
}

extension String
{
    var hexadecimal: Data?
    {
        var data = Data(capacity: count / 2)
        let regex = try! NSRegularExpression(pattern: "[0-9a-f]{1,2}", options: .caseInsensitive)

        regex.enumerateMatches(in: self, range: NSRange(startIndex..., in: self))
        { match, _, _ in
            let byteString = (self as NSString).substring(with: match!.range)
            let num = UInt8(byteString, radix: 16)!
            data.append(num)
        }

        return data
    }
}

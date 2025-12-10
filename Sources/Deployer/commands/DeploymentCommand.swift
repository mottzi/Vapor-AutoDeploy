import Vapor

extension Application.Deployer
{
    struct Command: AsyncCommand
    {
        struct Signature: CommandSignature {}

        let help: String
        let config: Application.Deployer.Configuration
        
        init(config: Application.Deployer.Configuration)
        {
            self.config = config
            self.help = "Pulls, builds, moves and restarts \(config.deployerConfig.productName)."
        }

        func run(using context: CommandContext, signature: Signature) async throws
        {
            let uri = URI(string: "http://localhost:\(config.port)/\(config.panelRoute)/deploy")

            let response = try await context.application.client.post(uri)
            {
                $0.headers.add(
                    name: "X-Deploy-Secret",
                    value: Environment.Variables.DEPLOY_SECRET.value
                )
            }

            context.console.print("Deployer Response: \(response.status).")
        }
    }
}

import Vapor

struct DeployCommand: AsyncCommand {
    struct Signature: CommandSignature {}

    let help: String = "Pulls, builds, moves and restarts Deployer."

    func run(using context: CommandContext, signature: Signature) async throws {
        let uri = URI(string: "http://localhost:8081/Deployer/deploy")

        let response = try await context.application.client.post(uri) { request in
            request.headers.add(name: "X-Deploy-Secret", value: "4132Muttenz")
        }

        context.console.print("Deployer Response: \(response.status).")
    }
}

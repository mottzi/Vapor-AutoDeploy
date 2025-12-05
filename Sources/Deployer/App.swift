import Fluent
import FluentSQLiteDriver
import Mist
import Vapor

@main
struct DeployerApp 
{
    static func main() async throws 
    {
        let env = try Environment.detect()
        let app = try await Application.make(env)
        app.http.server.configuration.port = 8081

        app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

        app.databases.use(.sqlite(.file("deploy/Deployer.db")), as: .sqlite)
        app.migrations.add(Deployment.Table())
        try await app.autoMigrate()

        app.mist.socketPath = ["deployment", "ws"]
        await app.mist.use(DeploymentRow(), DeploymentStatus())

        app.views.use(.leaf)

        app.environment.useVariables()
        app.useWebhook()
        app.useDeployPanel()
        
        app.asyncCommands.use(DeployCommand(), as: "deploy")

        try await app.execute()
        try await app.asyncShutdown()
    }
}

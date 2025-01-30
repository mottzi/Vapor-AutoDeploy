import Vapor
import Fluent
import FluentSQLiteDriver
import Leaf

@main
struct mottzi
{
    static func main() async throws
    {
        var env = try Environment.detect()
        try LoggingSystem.bootstrap(from: &env)

        let app = try await Application.make(env)
        app.databases.use(.sqlite(.file("deploy/github/deployments.db")), as: .sqlite)
        app.migrations.add(Deployment.Table2())
        try await app.autoMigrate()
        
        app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
        app.views.use(.leaf)
        app.useRoutes()
        app.usePushEvents()
        app.useAdminPanel()
        
        try await app.execute()
        try await app.asyncShutdown()
    }
}

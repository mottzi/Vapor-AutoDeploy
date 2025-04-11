import Vapor
import Leaf
import Fluent
import FluentSQLiteDriver

@main
struct App
{
    static func main() async throws
    {
        var env = try Environment.detect()
        let app = try await Application.make(env)
        
        app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

        app.environment.useVariables()
        
        app.databases.use(.sqlite(.file("deploy/github/deployments.db")), as: .sqlite)
        app.databases.middleware.use(Deployment.Listener(), on: .sqlite)

        app.migrations.add(
            Deployment.Table(),
            DummyModel1.Table3(),
            DummyModel2.Table())
        
        try await app.autoMigrate()
                
        app.views.use(.leaf)
        app.useRoutes()
        app.usePushDeploy()
        app.useDeployPanel()
         
        let config = Mist.Configuration(
            for: app,
            components: [
                DummyComponent.self,
            ]
        )
        
        await Mist.configure(using: config)
        
        let dummyModel1 = DummyModel1(text: "Hello")
        let dummyModel2 = DummyModel2(text: "World")
       
        let componentID = UUID()
        dummyModel1.id = componentID
        dummyModel2.id = componentID
        
        try await dummyModel1.save(on: app.db)
        try await dummyModel2.save(on: app.db)
                
        app.useDummy()
                
        try await app.execute()
        try await app.asyncShutdown()
    }
}

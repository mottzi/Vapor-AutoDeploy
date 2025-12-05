import Vapor
import Fluent
import Mist

extension Application
{
    public struct Deployer
    {
        public let app: Application
        
//        public var socketPath: [PathComponent]
//        {
//            get { _socketPath }
//            nonmutating set { _socketPath = newValue }
//        }
        
        public func use(config: Configuration, on app: Application) async throws
        {
            app.http.server.configuration.port = config.port
            app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
            
            app.databases.use(.sqlite(.file(config.dbFile)), as: .sqlite)
            app.migrations.add(Deployment.Table())
            try await app.autoMigrate()
            
            app.mist.socketPath = config.mistSocketPath
            await app.mist.use(config.deploymentRow, config.deploymentStatus)
            
            app.views.use(.leaf)
            
            app.environment.useVariables()
            app.useWebhook()
            app.useDeployPanel()
            
            app.asyncCommands.use(DeployCommand(), as: "deploy")
        }
    }
    
    public var deployer: Deployer { Deployer(app: self) }
}

extension Application.Deployer
{
    public struct Configuration: Sendable
    {
        var port: Int
        var dbFile: String
        var mistSocketPath: [PathComponent]
        var deploymentRow: any Mist.Component
        var deploymentStatus: any Mist.Component
        
        static let standard = Configuration(
            port: 8081,
            dbFile: "deploy/Deployer.db",
            mistSocketPath: ["deployment", "ws"],
            deploymentRow: DeploymentRow(),
            deploymentStatus: DeploymentStatus()
        )
    }
}

extension Application.Mist
{
    final class Storage: @unchecked Sendable
    {
        init() {}
//        var socketPath: [PathComponent]?
    }
    
    private struct Key: StorageKey { typealias Value = Storage }
    
    var _storage: Storage
    {
        if let existing = app.storage[Key.self] { return existing }
        let new = Storage()
        app.storage[Key.self] = new
        return new
    }
}

//extension Application.Mist
//{
//    private struct SocketPathKey: LockKey {}
//
//    var _socketPath: [PathComponent]
//    {
//        get
//        {
//            return app.locks.lock(for: SocketPathKey.self).withLock
//            {
//                return _storage.socketPath ?? ["mist", "ws"]
//            }
//        }
//        nonmutating set
//        {
//            app.locks.lock(for: SocketPathKey.self).withLock
//            {
//                _storage.socketPath = newValue
//            }
//        }
//    }
//}

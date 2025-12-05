import Fluent
import Mist
import Vapor

struct DeploymentStatus: QueryComponent {
    let models: [any Mist.Model.Type] = [Deployment.self]
    let template: Template = .file(path: "Deployer/DeploymentStatus")

    func queryModel(on db: Database) async -> (any Mist.Model)? {
        return try? await Deployment.getCurrent(named: "Mottzi", on: db)
    }
}

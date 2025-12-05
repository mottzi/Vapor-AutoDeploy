import Mist
import Vapor

typealias MistModelContainer = Mist.ModelContainer

extension Application
{
    func useDeployPanel() 
    {
        self.get("Deployer")
        { request async throws -> View in
            
            let componentsContext = await DeploymentRow().makeContext(ofAll: request.db)
            let currentDeployment = try? await Deployment.getCurrent(named: "Mottzi", on: request.db)

            let statusComponent = currentDeployment.map 
            { 
                var container = MistModelContainer()
                container.add($0, for: "deployment")
                return container
             }

            struct DeploymentPanelContext: Encodable 
            {
                let components: [MistModelContainer]
                let component: MistModelContainer?
            }

            let context = DeploymentPanelContext(
                components: componentsContext.components,
                component: statusComponent
            )

            return try await request.view.render("Deployer/DeploymentPanel", context)
        }

        self.post("Deployer", "deploy") 
        { request async throws -> String in

            guard let providedSecret = request.headers.first(name: "X-Deploy-Secret"),
                  let expectedSecret = Environment.get(Environment.Variables.DEPLOY_SECRET.rawValue)
            else { throw Abort(.unauthorized, reason: "Could not obtain secrets to compare.") }

            guard providedSecret == expectedSecret 
            else { throw Abort(.unauthorized, reason: "Secrets didn't match.") }
            
            Task.detached
            {
                let pipeline = Deployment.Pipeline(
                    productName: "Deployer",
                    supervisorJob: "deployer",
                    workingDirectory: "/var/www/mottzi",
                    buildConfiguration: "debug"
                )
                
                await pipeline.deploy(message: "[CLI] Deployer", on: self)
            }

            return "Started deployment pipeline ;D"
        }
    }
}

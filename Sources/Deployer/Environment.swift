import Vapor

extension Environment
{
    enum Variables: String, CaseIterable
    {
        case GITHUB_WEBHOOK_SECRET
        case DEPLOY_SECRET

        var value: String { Environment.get(self.rawValue)! }
    }

    func useVariables()
    {
        for variable in Variables.allCases
        {
            guard Environment.get(variable.rawValue) == nil else { continue }
            fatalError("\(variable.rawValue): Environment variable not found.")
        }
    }
}

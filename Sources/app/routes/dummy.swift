import Vapor
import Mist

extension Application
{
    func useDummy()
    {
        self.get("DummyComponents")
        { request async throws -> View in
            // create template context with all available component data
            let context = await DummyComponent.makeContext(ofAll: request.db)
            // render initial page template with full data set
            return try await request.view.render("InitialDummies", context)
        }
        
        self.get("DummyModel1", "update", ":id", ":text")
        { req async throws -> HTTPStatus in
            
            guard let idString = req.parameters.get("id"),
                  let id = UUID(uuidString: idString)
            else { throw Abort(.badRequest, reason: "Valid UUID required") }
            
            guard let text = req.parameters.get("text")
            else { throw Abort(.badRequest, reason: "Valid text required") }
            
            guard let dummyModel1 = try await DummyModel1.find(id, on: req.db)
            else { throw Abort(.notFound, reason: "DummyModel1 not found") }
            
            dummyModel1.text = text
            try await dummyModel1.save(on: req.db)
            
            return .ok
        }
        
        self.get("DummyModel2", "update", ":id", ":text")
        { req async throws -> HTTPStatus in
            
            guard let idString = req.parameters.get("id"),
                  let id = UUID(uuidString: idString)
            else { throw Abort(.badRequest, reason: "Valid UUID required") }
            
            guard let text = req.parameters.get("text")
            else { throw Abort(.badRequest, reason: "Valid text required") }
            
            guard let dummyModel2 = try await DummyModel2.find(id, on: req.db)
            else { throw Abort(.notFound, reason: "DummyModel2 not found") }
            
            dummyModel2.text2 = text
            try await dummyModel2.save(on: req.db)
            
            return .ok
        }
        
        self.get("dummies", "delete", ":id")
        { req async throws -> HTTPStatus in
            
            guard let idString = req.parameters.get("id"),
                  let id = UUID(uuidString: idString)
            else
            {
                throw Abort(.badRequest, reason: "Valid UUID parameter is required")
            }
            
            guard let dummy = try await DummyModel1.find(id, on: req.db)
            else
            {
                throw Abort(.notFound, reason: "DummyModel with specified ID not found")
            }
            
            guard let dummy2 = try await DummyModel2.find(id, on: req.db)
            else
            {
                throw Abort(.notFound, reason: "DummyModel2 with specified ID not found")
            }
            
            try await dummy.delete(on: req.db)
            try await dummy2.delete(on: req.db)
            
            return .ok
        }
        
        self.get("dummies", "deleteAll")
        { req async throws -> HTTPStatus in
            try await DummyModel1.query(on: req.db).delete()
            try await DummyModel2.query(on: req.db).delete()
            return .ok
        }
        
        self.get("dummies", "create")
        { req async throws -> DummyModel1 in
            
            let words =
            [
                "swift", "vapor", "fluent", "leaf", "websocket", "async",
                "database", "server", "client", "model", "view", "controller",
                "route", "middleware", "protocol", "actor", "request", "response"
            ]
            
            // create and save new dummy db entry with provided text
            let dummy = DummyModel1(text: words.randomElement()!)
            try await dummy.save(on: req.db)
            
            let dummy2 = DummyModel2(text: words.randomElement()!)
            dummy2.id = dummy.id
            try await dummy2.save(on: req.db)
            
            // retrun json encoded http response of created db entry
            return dummy
        }
    }
}


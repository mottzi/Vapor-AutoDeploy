import Vapor

extension Application
{
    // the web server will respond to the following http routes
    public func useRoutes()
    {
        // mottzi.de/text
        self.get("text")
        { request in
            """
            Auto Deploy: 1
            """
        }
        
        // mottzi.de/dynamic/world
        self.get("dynamic", ":property")
        { request async in
            request.logger.info("RequestInfo 1")
            request.logger.error("RequestError 2")
            request.logger.error("RequestError 2", file: #fileID, line: #line)
        
            return "Hello, \(request.parameters.get("property")!)!\nLogger level: \(request.logger.logLevel)"
        }
        
        self.get("dynamic2", ":property")
        { request async throws in
            throw Abort(.badRequest, reason: "Test error")
            
            return "hi"
        }
        
        // mottzi.de/infile
        self.get("infile")
        { request async throws in
            try await request.view.render("demo")
        }
        
        // mottzi.de/inline
        self.get("inline")
        { _ in
            let response = Response(status: .ok)
            response.headers.contentType = .html
            response.body = .init(stringLiteral:
            """
            <!DOCTYPE html>
            <html lang="en">
            <head>
                <title>Index Page</title>
            </head>
            <body>
                <h1>inline</h1>
                <p>This html page is defined in the route definition.</p>
            </body>
            </html>
            """)
            
            return response
        }
    }
}

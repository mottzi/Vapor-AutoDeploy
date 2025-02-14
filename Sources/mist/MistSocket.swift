import Vapor
import Fluent
import Leaf
import LeafKit

// server websocket endpoint
extension Application
{
    func useMist()
    {
        // mottzi.de/template
        self.get("test")
        { request async throws in
            "test"
        }
        
        self.webSocket("mist", "ws")
        { request, ws async in
            
            // create new connection on upgrade
            let id = UUID()
            // add new connection to actor
            await Mist.Clients.shared.add(connection: id, socket: ws, request: request)
            
            // respond to client message
            ws.onText()
            { ws, text async in
                // abort if message is not of type Mist.Message
                guard let data = text.data(using: .utf8) else { return }
                guard let message = try? JSONDecoder().decode(Mist.Message.self, from: data) else { return }
                
                switch message
                {
                    case .subscribe(let model): await Mist.Clients.shared.addSubscription(model, for: id)
                    case .unsubscribe(let model): await Mist.Clients.shared.removeSubscription(model, for: id)
                        
                    // server does not handle other message types
                    default: break
                }
            }
            
            // remove connection from actor on close
            ws.onClose.whenComplete() { _ in Task { await Mist.Clients.shared.remove(connection: id) } }
        }
    }
}

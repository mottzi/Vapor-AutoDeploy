import Vapor
import Fluent

// mist component example
struct DummyRow: Mist.Component
{
    static let models: [any Model.Type] = [DummyModel.self, DummyModel2.self]
    
    struct EntryData: Encodable
    {
        let dummy1: DummyModel
        let dummy2: DummyModel2
    }
    
    struct SingleContext: Encodable
    {
        let entry: EntryData
    }
    
    struct MultipleContext: Encodable
    {
        let entries: [EntryData]
    }
    
    static func makeContext(id: UUID, on db: Database) async -> SingleContext?
    {
        guard let dummy1 = try? await DummyModel.find(id, on: db) else { return nil }
        guard let dummy2 = try? await DummyModel2.find(id, on: db) else { return nil }
        
        return SingleContext(entry: EntryData(dummy1: dummy1, dummy2: dummy2))
    }
    
    static func makeContext(on db: any Database) async -> MultipleContext?
    {
        // Fetch all DummyModel instances
        guard let primaryModels = try? await DummyModel.all(on: db) else { return nil }
        
        // Array to hold combined model data
        var joinedModels: [EntryData] = []
        
        // For each DummyModel, find the corresponding DummyModel2
        for primaryModel in primaryModels
        {
            guard let id = primaryModel.id else { continue }
            
            // Find matching DummyModel2 with the same ID
            guard let secodaryModel = try? await DummyModel2.find(id, on: db) else { continue }
            
            // Add combined data
            joinedModels.append(EntryData(dummy1: primaryModel, dummy2: secodaryModel))
        }
        
        return MultipleContext(entries: joinedModels)
    }
}

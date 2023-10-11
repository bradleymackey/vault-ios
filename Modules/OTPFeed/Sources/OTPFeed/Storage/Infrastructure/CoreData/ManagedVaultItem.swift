import CoreData
import OTPCore

@objc(ManagedVaultItem)
final class ManagedVaultItem: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var secretFormat: String
    @NSManaged var secretData: Data
    @NSManaged var authType: String
    @NSManaged var period: NSNumber?
    @NSManaged var counter: NSNumber?
    @NSManaged var algorithm: String
    @NSManaged var digits: NSNumber
    @NSManaged var accountName: String
    @NSManaged var issuer: String?
    @NSManaged var createdDate: Date
    @NSManaged var updatedDate: Date
    @NSManaged var userDescription: String?
}

extension ManagedVaultItem {
    static func fetchAll(in context: NSManagedObjectContext) throws -> [ManagedVaultItem] {
        let request = NSFetchRequest<ManagedVaultItem>(entityName: entity().name!)
        request.returnsObjectsAsFaults = false
        return try context.fetch(request)
    }

    static func first(withID id: UUID, in context: NSManagedObjectContext) throws -> ManagedVaultItem? {
        let request = NSFetchRequest<ManagedVaultItem>(entityName: entity().name!)
        request.predicate = NSPredicate(format: "%K = %@", argumentArray: [#keyPath(ManagedVaultItem.id), id as NSUUID])
        request.fetchLimit = 1
        request.returnsObjectsAsFaults = false
        return try context.fetch(request).first
    }
}

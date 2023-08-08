import CoreData
import OTPCore

@objc(ManagedOTPCode)
final class ManagedOTPCode: NSManagedObject {
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

extension ManagedOTPCode {
    static func fetchAll(in context: NSManagedObjectContext) throws -> [ManagedOTPCode] {
        let request = NSFetchRequest<ManagedOTPCode>(entityName: entity().name!)
        request.returnsObjectsAsFaults = false
        return try context.fetch(request)
    }

    static func first(withID id: UUID, in context: NSManagedObjectContext) throws -> ManagedOTPCode? {
        let request = NSFetchRequest<ManagedOTPCode>(entityName: entity().name!)
        request.predicate = NSPredicate(format: "%K = %@", argumentArray: [#keyPath(ManagedOTPCode.id), id as NSUUID])
        request.fetchLimit = 1
        request.returnsObjectsAsFaults = false
        return try context.fetch(request).first
    }
}

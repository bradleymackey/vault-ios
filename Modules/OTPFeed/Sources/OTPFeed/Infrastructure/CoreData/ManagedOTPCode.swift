import CoreData
import OTPCore

@objc(ManagedOTPCode)
class ManagedOTPCode: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var authType: String
    @NSManaged var period: NSNumber?
    @NSManaged var counter: NSNumber?
    @NSManaged var algorithm: String
    @NSManaged var digits: NSNumber
    @NSManaged var accountName: String
    @NSManaged var issuer: String?
}

extension ManagedOTPCode {
    static func fetchAll(in context: NSManagedObjectContext) throws -> [ManagedOTPCode] {
        let request = NSFetchRequest<ManagedOTPCode>(entityName: entity().name!)
        request.returnsObjectsAsFaults = false
        return try context.fetch(request)
    }
}

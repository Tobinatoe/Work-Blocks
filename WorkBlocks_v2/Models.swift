import CoreData

enum BlockStatus: String {
    case completed, aborted
}

struct BlockDTO {
    let startedAt: Date
    let endedAt: Date
    let durationSec: Int
    let status: BlockStatus
    let tag: String?
}

// Entity names/attributes
private enum Entities {
    static let block = "Block"
    static let session = "Session"
}

final class ModelBuilder {
    static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // Block entity
        let blockEntity = NSEntityDescription()
        blockEntity.name = Entities.block
        blockEntity.managedObjectClassName = NSManagedObject.className()

        let bId = NSAttributeDescription()
        bId.name = "id"; bId.attributeType = .integer64AttributeType; bId.isOptional = false
        let bStarted = NSAttributeDescription()
        bStarted.name = "started_at"; bStarted.attributeType = .dateAttributeType; bStarted.isOptional = false
        let bEnded = NSAttributeDescription()
        bEnded.name = "ended_at"; bEnded.attributeType = .dateAttributeType; bEnded.isOptional = false
        let bDur = NSAttributeDescription()
        bDur.name = "duration_sec"; bDur.attributeType = .integer64AttributeType; bDur.isOptional = false
        let bStatus = NSAttributeDescription()
        bStatus.name = "status"; bStatus.attributeType = .stringAttributeType; bStatus.isOptional = false
        let bTag = NSAttributeDescription()
        bTag.name = "tag"; bTag.attributeType = .stringAttributeType; bTag.isOptional = true

        blockEntity.properties = [bId, bStarted, bEnded, bDur, bStatus, bTag]

        // Session entity (singleton row)
        let sessionEntity = NSEntityDescription()
        sessionEntity.name = Entities.session
        sessionEntity.managedObjectClassName = NSManagedObject.className()

        let sId = NSAttributeDescription()
        sId.name = "id"; sId.attributeType = .integer64AttributeType; sId.isOptional = false
        let sStarted = NSAttributeDescription()
        sStarted.name = "started_at"; sStarted.attributeType = .dateAttributeType; sStarted.isOptional = true
        let sPausedAccum = NSAttributeDescription()
        sPausedAccum.name = "paused_accum_sec"; sPausedAccum.attributeType = .integer64AttributeType; sPausedAccum.isOptional = false
        let sLastPaused = NSAttributeDescription()
        sLastPaused.name = "last_paused_at"; sLastPaused.attributeType = .dateAttributeType; sLastPaused.isOptional = true

        sessionEntity.properties = [sId, sStarted, sPausedAccum, sLastPaused]

        model.entities = [blockEntity, sessionEntity]
        return model
    }
}

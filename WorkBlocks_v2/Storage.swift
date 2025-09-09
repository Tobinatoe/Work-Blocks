import Foundation
import CoreData

final class Storage: ObservableObject {
    private let container: NSPersistentContainer
    private let ctx: NSManagedObjectContext

    init() {
        let model = ModelBuilder.makeModel()
        container = NSPersistentContainer(name: "WorkBlocks", managedObjectModel: model)

        // SQLite store with WAL
        let description = NSPersistentStoreDescription(url: URL(fileURLWithPath: Config.dbPath))
        description.type = NSSQLiteStoreType
        description.setOption(["journal_mode": "WAL"] as NSDictionary, forKey: NSSQLitePragmasOption)
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)

        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { _, error in
            if let error = error { fatalError("Persistent store error: \(error)") }
        }

        ctx = container.viewContext
        ctx.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        // Ensure singleton Session row exists
        ensureSessionRow()
    }

    private func ensureSessionRow() {
        if fetchSession() == nil {
            let s = NSEntityDescription.insertNewObject(forEntityName: "Session", into: ctx)
            s.setValue(1 as Int64, forKey: "id")
            s.setValue(0 as Int64, forKey: "paused_accum_sec")
            save()
        }
    }

    // MARK: - Session
    func fetchSession() -> NSManagedObject? {
        let req = NSFetchRequest<NSManagedObject>(entityName: "Session")
        req.fetchLimit = 1
        return try? ctx.fetch(req).first
    }

    func setSession(startedAt: Date?) {
        guard let s = fetchSession() else { return }
        s.setValue(startedAt, forKey: "started_at")
        if startedAt == nil {
            s.setValue(0 as Int64, forKey: "paused_accum_sec")
            s.setValue(nil, forKey: "last_paused_at")
        }
        save()
    }

    func setSessionPaused(at: Date?) {
        guard let s = fetchSession() else { return }
        s.setValue(at, forKey: "last_paused_at")
        save()
    }

    func addPausedAccum(_ seconds: Int) {
        guard let s = fetchSession() else { return }
        let current = (s.value(forKey: "paused_accum_sec") as? Int64) ?? 0
        s.setValue(current + Int64(seconds), forKey: "paused_accum_sec")
        save()
    }

    func readSessionState() -> (startedAt: Date?, pausedAccum: Int, lastPausedAt: Date?) {
        guard let s = fetchSession() else { return (nil, 0, nil) }
        let started = s.value(forKey: "started_at") as? Date
        let pausedAccum = Int((s.value(forKey: "paused_accum_sec") as? Int64) ?? 0)
        let lastPaused = s.value(forKey: "last_paused_at") as? Date
        return (started, pausedAccum, lastPaused)
    }

    // MARK: - Blocks
    func insertBlock(_ dto: BlockDTO) {
        let obj = NSEntityDescription.insertNewObject(forEntityName: "Block", into: ctx)
        let nextId = (try? ctx.count(for: NSFetchRequest<NSManagedObject>(entityName: "Block"))) ?? 0
        obj.setValue(Int64(nextId + 1), forKey: "id")
        obj.setValue(dto.startedAt, forKey: "started_at")
        obj.setValue(dto.endedAt, forKey: "ended_at")
        obj.setValue(Int64(dto.durationSec), forKey: "duration_sec")
        obj.setValue(dto.status.rawValue, forKey: "status")
        obj.setValue(dto.tag, forKey: "tag")
        save()
    }

    func todayStats() -> (blocks: Int, minutes: Int) {
        let (start, end) = dayBounds(for: Date())
        let req = NSFetchRequest<NSManagedObject>(entityName: "Block")
        req.predicate = NSPredicate(format: "ended_at >= %@ AND ended_at < %@ AND status == %@", start as NSDate, end as NSDate, BlockStatus.completed.rawValue)
        do {
            let rows = try ctx.fetch(req)
            let count = rows.count
            let minutes = rows.reduce(0) { $0 + Int(($1.value(forKey: "duration_sec") as? Int64) ?? 0) } / 60
            return (count, minutes)
        } catch {
            return (0, 0)
        }
    }

    func weekBlocks() -> Int {
        let cal = Calendar(identifier: .gregorian)
        var calCfg = cal
        calCfg.firstWeekday = Config.weekStartsMonday ? 2 : 1
        let today = Date()
        let startOfWeek = calCfg.date(from: calCfg.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
        let end = calCfg.date(byAdding: .day, value: 7, to: startOfWeek)!
        let req = NSFetchRequest<NSManagedObject>(entityName: "Block")
        req.predicate = NSPredicate(format: "ended_at >= %@ AND ended_at < %@ AND status == %@", startOfWeek as NSDate, end as NSDate, BlockStatus.completed.rawValue)
        do { return try ctx.count(for: req) } catch { return 0 }
    }

    // Helpers
    /// Removes the most recent completed block for today, if any.
    func removeLatestBlockToday() {
        let (start, end) = dayBounds(for: Date())
        let req = NSFetchRequest<NSManagedObject>(entityName: "Block")
        req.predicate = NSPredicate(format: "ended_at >= %@ AND ended_at < %@ AND status == %@", start as NSDate, end as NSDate, BlockStatus.completed.rawValue)
        let sort = NSSortDescriptor(key: "ended_at", ascending: false)
        req.sortDescriptors = [sort]
        req.fetchLimit = 1
        do {
            if let latest = try ctx.fetch(req).first {
                ctx.delete(latest)
                save()
            }
        } catch {
            print("Error removing latest block:", error)
        }
    }
    func dayBounds(for date: Date) -> (Date, Date) {
        let cal = Calendar.current
        let start = cal.startOfDay(for: date)
        let end = cal.date(byAdding: .day, value: 1, to: start)!
        return (start, end)
    }

    // MARK: - History helpers

    func weekStart(for date: Date) -> Date {
        let cal = Calendar(identifier: .gregorian)
        var calCfg = cal
        calCfg.firstWeekday = Config.weekStartsMonday ? 2 : 1
        return calCfg.date(from: calCfg.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))!
    }

    func weekBounds(starting start: Date) -> (Date, Date) {
        let cal = Calendar(identifier: .gregorian)
        let end = cal.date(byAdding: .day, value: 7, to: start)!
        return (start, end)
    }

    func stats(forDay date: Date) -> (blocks: Int, minutes: Int) {
        let (start, end) = dayBounds(for: date)
        let req = NSFetchRequest<NSManagedObject>(entityName: "Block")
        req.predicate = NSPredicate(format: "ended_at >= %@ AND ended_at < %@ AND status == %@", start as NSDate, end as NSDate, BlockStatus.completed.rawValue)
        do {
            let rows = try ctx.fetch(req)
            let count = rows.count
            let minutes = rows.reduce(0) { $0 + Int(($1.value(forKey: "duration_sec") as? Int64) ?? 0) } / 60
            return (count, minutes)
        } catch { return (0, 0) }
    }

    func weeklyStats(forWeekStarting start: Date) -> (blocks: Int, minutes: Int) {
        let (s, e) = weekBounds(starting: start)
        let req = NSFetchRequest<NSManagedObject>(entityName: "Block")
        req.predicate = NSPredicate(format: "ended_at >= %@ AND ended_at < %@ AND status == %@", s as NSDate, e as NSDate, BlockStatus.completed.rawValue)
        do {
            let rows = try ctx.fetch(req)
            let count = rows.count
            let minutes = rows.reduce(0) { $0 + Int(($1.value(forKey: "duration_sec") as? Int64) ?? 0) } / 60
            return (count, minutes)
        } catch { return (0, 0) }
    }

    func earliestCompletedBlockDate() -> Date? {
        let req = NSFetchRequest<NSManagedObject>(entityName: "Block")
        req.predicate = NSPredicate(format: "status == %@", BlockStatus.completed.rawValue)
        let sort = NSSortDescriptor(key: "ended_at", ascending: true)
        req.sortDescriptors = [sort]
        req.fetchLimit = 1
        do { return try ctx.fetch(req).first?.value(forKey: "ended_at") as? Date } catch { return nil }
    }

    func listRecentWeekStarts(limit: Int = 12) -> [Date] {
        let now = Date()
        var current = weekStart(for: now)
        let earliest = earliestCompletedBlockDate()
        var result: [Date] = []
        let cal = Calendar(identifier: .gregorian)
        while result.count < limit {
            if let earliest, current < weekStart(for: earliest) { break }
            result.append(current)
            if let prev = cal.date(byAdding: .day, value: -7, to: current) {
                current = prev
            } else { break }
        }
        return result
    }

    func save() {
        if ctx.hasChanges {
            do { try ctx.save() } catch { print("Save error:", error) }
        }
    }
}

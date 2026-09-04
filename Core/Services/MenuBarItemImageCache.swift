import AppKit

final class MenuBarItemImageCache: @unchecked Sendable {
    private let lock = NSLock()
    private var images: [String: NSImage] = [:]

    func store(_ image: NSImage, for uniqueId: String) {
        lock.lock()
        images[uniqueId] = image
        lock.unlock()
    }

    func image(for uniqueId: String) -> NSImage? {
        lock.lock()
        defer { lock.unlock() }
        return images[uniqueId]
    }

    func prune(keeping uniqueIds: Set<String>) {
        lock.lock()
        images = images.filter { uniqueIds.contains($0.key) }
        lock.unlock()
    }
}

import Foundation

/// A single listening history entry.
public struct HistoryEntry: Codable, Hashable, Identifiable, Sendable {
    public var id: String { track.id + "_" + (lastListeningDttm ?? "") }
    public let track: SimpleTrack
    public let lastListeningDttm: String?

    public init(track: SimpleTrack, lastListeningDttm: String? = nil) {
        self.track = track
        self.lastListeningDttm = lastListeningDttm
    }
}

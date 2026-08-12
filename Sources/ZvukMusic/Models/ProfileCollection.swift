import Foundation

/// Snapshot of a user's collection as shown on the profile screen.
public struct ProfileCollection: Codable, Hashable, Sendable {
    /// Liked artists.
    public let artists: [Artist]
    /// Liked tracks.
    public let tracks: [Track]
    /// The user's playlists.
    public let playlists: [Playlist]

    public init(artists: [Artist] = [], tracks: [Track] = [], playlists: [Playlist] = []) {
        self.artists = artists
        self.tracks = tracks
        self.playlists = playlists
    }
}

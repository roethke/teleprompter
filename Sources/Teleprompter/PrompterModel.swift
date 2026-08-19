import SwiftUI

/// Holds all teleprompter state. Persists the script + preferences to UserDefaults
/// so the app opens right where you left off.
final class PrompterModel: ObservableObject {

    // MARK: Persisted settings
    @Published var script: String {
        didSet { defaults.set(script, forKey: "script") }
    }
    @Published var fontSize: Double {
        didSet { defaults.set(fontSize, forKey: "fontSize") }
    }
    /// Auto-scroll speed in points per second.
    @Published var speed: Double {
        didSet { defaults.set(speed, forKey: "speed") }
    }
    /// Whole-window opacity (1 = solid).
    @Published var opacity: Double {
        didSet { defaults.set(opacity, forKey: "opacity") }
    }
    // MARK: Live state (not persisted)
    @Published var isPlaying = false
    @Published var isEditing = false
    /// How far we've scrolled, in points.
    @Published var offset: CGFloat = 0

    // Layout metrics reported back from the view.
    var contentHeight: CGFloat = 0
    var viewportHeight: CGFloat = 0

    private let defaults = UserDefaults.standard

    // Tunable bounds so quick tweaks stay usable.
    let minFont: Double = 9
    let maxFont: Double = 90
    let minSpeed: Double = 8
    let maxSpeed: Double = 260
    // Floor keeps the window from vanishing entirely so you never lose it.
    let minOpacity: Double = 0.25
    let maxOpacity: Double = 1.0

    init() {
        script = defaults.string(forKey: "script") ?? PrompterModel.sample
        let f = defaults.double(forKey: "fontSize")
        fontSize = f == 0 ? 36 : f
        let s = defaults.double(forKey: "speed")
        speed = s == 0 ? 45 : s
        let o = defaults.double(forKey: "opacity")
        opacity = o == 0 ? 1.0 : o
    }

    /// Furthest we can scroll before the last line has passed through.
    var maxOffset: CGFloat { max(0, contentHeight - viewportHeight) }

    // MARK: Actions
    func togglePlay() {
        if offset >= maxOffset { offset = 0 } // restart if we're at the end
        isPlaying.toggle()
    }

    func restart() {
        offset = 0
        isPlaying = false
    }

    /// Called ~60x/sec by the view's timer.
    func tick() {
        guard isPlaying, !isEditing else { return }
        offset = min(maxOffset, offset + speed / 60.0)
        if offset >= maxOffset { isPlaying = false } // stop cleanly at the end
    }

    /// Manual scrubbing (scroll wheel / arrow keys).
    func scrollBy(_ delta: CGFloat) {
        offset = min(maxOffset, max(0, offset + delta))
    }

    func bumpSpeed(_ delta: Double) {
        speed = min(maxSpeed, max(minSpeed, speed + delta))
    }

    func bumpFont(_ delta: Double) {
        fontSize = min(maxFont, max(minFont, fontSize + delta))
    }

    func bumpOpacity(_ delta: Double) {
        opacity = min(maxOpacity, max(minOpacity, opacity + delta))
    }

    static let sample = """
    Welcome to your teleprompter.

    Tap Edit (or press E) to paste your own script, then press Space to start scrolling.

    Use + and - to change speed, and the A buttons to resize text. Drag this window right under your camera and look straight ahead.
    """
}

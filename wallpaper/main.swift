// nekozame-wallpaper: the animated catshark behind the desktop, on every screen.
// the loop is tiny pixel art (480x270), so it's scaled up by a whole number with
// nearest-neighbour, and cropped to fill the screen.
//   nekozame-wallpaper LOOP.mov
import AppKit
import AVFoundation

let url = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1]
    : NSString(string: "~/.local/share/nekozame/wallpaper.mov").expandingTildeInPath)

final class Wall {
    let window: NSWindow
    let looper: AVPlayerLooper
    let player = AVQueuePlayer()

    init(screen: NSScreen) {
        window = NSWindow(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)))
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        window.ignoresMouseEvents = true
        window.backgroundColor = .black
        let item = AVPlayerItem(url: url)
        looper = AVPlayerLooper(player: player, templateItem: item)
        player.isMuted = true
        player.preventsDisplaySleepDuringVideoPlayback = false

        let view = NSView(frame: NSRect(origin: .zero, size: screen.frame.size))
        view.wantsLayer = true
        let layer = AVPlayerLayer(player: player)
        layer.magnificationFilter = .nearest
        layer.videoGravity = .resize
        // whole-number scale in real pixels, big enough to cover, centred
        let px = screen.backingScaleFactor
        let size = item.asset.tracks(withMediaType: .video).first?.naturalSize ?? CGSize(width: 480, height: 270)
        let k = ceil(max(screen.frame.width * px / size.width, screen.frame.height * px / size.height))
        let w = size.width * k / px, h = size.height * k / px
        layer.frame = CGRect(x: (screen.frame.width - w) / 2, y: (screen.frame.height - h) / 2, width: w, height: h)
        view.layer!.addSublayer(layer)
        window.contentView = view
        window.orderBack(nil)
        player.play()
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
var walls: [Wall] = []
func build() { walls = NSScreen.screens.map { Wall(screen: $0) } }
build()
NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification,
                                       object: nil, queue: .main) { _ in build() }
app.run()

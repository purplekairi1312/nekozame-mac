// nekozame-cava: cava on the bar, from what macOS is playing.
// it listens through a macOS audio tap: a read-only copy of the system's output.
// nothing about your audio changes (no virtual device, no routing, same output,
// same sample rate), and the tap's private device doesn't show up anywhere.
// the samples go to cava, and cava's bars go to SketchyBar's "cava" item.
import AudioToolbox
import CoreAudio
import Foundation

func fail(_ msg: String, _ err: OSStatus = 0) -> Never {
    FileHandle.standardError.write("nekozame-cava: \(msg) (\(err))\n".data(using: .utf8)!)
    exit(1)
}

// the tap: every process, mixed to stereo, left audible
let tapDesc = CATapDescription(stereoGlobalTapButExcludeProcesses: [])
tapDesc.uuid = UUID()
tapDesc.isPrivate = true
tapDesc.muteBehavior = .unmuted
var tapID = AudioObjectID(kAudioObjectUnknown)
var err = AudioHardwareCreateProcessTap(tapDesc, &tapID)
guard err == noErr else { fail("no audio tap: allow it in System Settings → Privacy & Security → Audio Recording", err) }

var addr = AudioObjectPropertyAddress(mSelector: kAudioTapPropertyFormat,
                                      mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
var asbd = AudioStreamBasicDescription()
var size = UInt32(MemoryLayout<AudioStreamBasicDescription>.size)
err = AudioObjectGetPropertyData(tapID, &addr, 0, nil, &size, &asbd)
guard err == noErr else { fail("can't read the tap's format", err) }
let rate = Int(asbd.mSampleRate)
let channels = Int(asbd.mChannelsPerFrame)
let interleaved = asbd.mFormatFlags & kAudioFormatFlagIsNonInterleaved == 0

// a private aggregate device holding just the tap: how the tap gets read
let aggDesc: [String: Any] = [
    kAudioAggregateDeviceNameKey: "nekozame-cava",
    kAudioAggregateDeviceUIDKey: UUID().uuidString,
    kAudioAggregateDeviceIsPrivateKey: true,
    kAudioAggregateDeviceTapAutoStartKey: true,
    kAudioAggregateDeviceTapListKey: [[kAudioSubTapUIDKey: tapDesc.uuid.uuidString]],
]
var aggID = AudioObjectID(kAudioObjectUnknown)
err = AudioHardwareCreateAggregateDevice(aggDesc as CFDictionary, &aggID)
guard err == noErr else { fail("can't open the tap", err) }

// cava, with the nekozame theme's settings: 16-bit stereo in, numbers 0-7 out
let conf = FileManager.default.temporaryDirectory.appendingPathComponent("nekozame-cava.conf")
try! """
[general]
bars = 14
framerate = 20
autosens = 1
[input]
method = fifo
source = /dev/stdin
sample_rate = \(rate)
sample_bits = 16
[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 7
bar_delimiter = 0
frame_delimiter = 10
""".write(to: conf, atomically: true, encoding: .utf8)

let cava = Process()
cava.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/cava")
cava.arguments = ["-p", conf.path]
let toCava = Pipe(), fromCava = Pipe()
cava.standardInput = toCava
cava.standardOutput = fromCava
cava.terminationHandler = { _ in exit(1) }  // launchd starts it all again
try! cava.run()
let cavaIn = toCava.fileHandleForWriting

// samples: float from the tap → 16-bit stereo for cava, off the audio thread
let feed = DispatchQueue(label: "feed")
var pending = 0
var procID: AudioDeviceIOProcID?
err = AudioDeviceCreateIOProcIDWithBlock(&procID, aggID, nil) { _, input, _, _, _ in
    let abl = UnsafeMutableAudioBufferListPointer(UnsafeMutablePointer(mutating: input))
    guard let first = abl.first, let p0 = first.mData else { return }
    var out: [Int16]
    if interleaved {
        let n = Int(first.mDataByteSize) / 4 / channels
        let f = p0.assumingMemoryBound(to: Float.self)
        out = [Int16](repeating: 0, count: n * 2)
        for i in 0..<n {
            out[2 * i] = Int16(max(-1, min(1, f[i * channels])) * 32767)
            out[2 * i + 1] = Int16(max(-1, min(1, f[i * channels + min(1, channels - 1)])) * 32767)
        }
    } else {
        let n = Int(first.mDataByteSize) / 4
        let l = p0.assumingMemoryBound(to: Float.self)
        let r = (abl.count > 1 ? abl[1].mData! : p0).assumingMemoryBound(to: Float.self)
        out = [Int16](repeating: 0, count: n * 2)
        for i in 0..<n {
            out[2 * i] = Int16(max(-1, min(1, l[i])) * 32767)
            out[2 * i + 1] = Int16(max(-1, min(1, r[i])) * 32767)
        }
    }
    let data = out.withUnsafeBufferPointer { Data(buffer: $0) }
    feed.async {
        if pending > 8 { return }  // cava is behind: skip a little, never block audio
        pending += 1
        cavaIn.write(data)
        pending -= 1
    }
}
guard err == noErr, let procID else { fail("can't read the tap", err) }
err = AudioDeviceStart(aggID, procID)
guard err == noErr else { fail("can't start the tap", err) }

// cava's bars → the bar, as ▁▂▃▄▅▆▇█; hidden after a second of silence
let blocks = Array("▁▂▃▄▅▆▇█")
var quietFrames = 0
var shown = true
func bar(_ args: [String]) {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/sketchybar")
    p.arguments = args
    try? p.run()
}
var buffered = Data()
fromCava.fileHandleForReading.readabilityHandler = { h in
    buffered.append(h.availableData)
    while let nl = buffered.firstIndex(of: 10) {
        let line = buffered[buffered.startIndex..<nl]
        buffered.removeSubrange(buffered.startIndex...nl)
        let levels = line.compactMap { $0 >= 48 && $0 <= 55 ? Int($0 - 48) : nil }
        if levels.allSatisfy({ $0 == 0 }) {
            quietFrames += 1
            if quietFrames == 20 && shown { shown = false; bar(["--set", "cava", "drawing=off"]) }
            continue
        }
        quietFrames = 0
        shown = true
        bar(["--set", "cava", "drawing=on", "label=" + String(levels.map { blocks[$0] })])
    }
}

signal(SIGTERM) { _ in exit(0) }
RunLoop.main.run()

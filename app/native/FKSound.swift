
// MARK: - Formkurve: Töne und Sprachansage nativ
// Web-Audio in der WebView wird von iOS im Stummmodus stummgeschaltet. Diese Töne laufen über die
// Audiositzung der App (.playback + .mixWithOthers): hörbar auch im Stummmodus, laufende Musik spielt weiter.
class FKBridgeViewController: CAPBridgeViewController {
    override open func capacitorDidLoad() {
        bridge?.registerPluginInstance(FKSoundPlugin())
    }
}

@objc(FKSoundPlugin)
public class FKSoundPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "FKSoundPlugin"
    public let jsName = "FKSound"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "play", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "speak", returnType: CAPPluginReturnPromise)
    ]
    private let engine = AVAudioEngine()
    private let node = AVAudioPlayerNode()
    private let sampleRate: Double = 44100
    private lazy var format: AVAudioFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
    private let synth = AVSpeechSynthesizer()
    private var attached = false

    private func activateSession() {
        let s = AVAudioSession.sharedInstance()
        if s.category != .playback || !s.categoryOptions.contains(.mixWithOthers) {
            try? s.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        }
        try? s.setActive(true)
    }

    private func engineRunning() -> Bool {
        if !attached {
            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: format)
            attached = true
        }
        if !engine.isRunning {
            do { engine.prepare(); try engine.start() } catch { return false }
        }
        return true
    }

    // tones: [{ f: Hz, t: Start (s), d: Dauer (s), v: Lautstärke, n: Rauschen (Klacken) }]
    @objc func play(_ call: CAPPluginCall) {
        let tones = call.getArray("tones", JSObject.self) ?? []
        DispatchQueue.main.async {
            self.activateSession()
            guard self.engineRunning(), let buffer = self.render(tones) else {
                call.reject("Ton konnte nicht abgespielt werden")
                return
            }
            self.node.scheduleBuffer(buffer, completionHandler: nil)
            if !self.node.isPlaying { self.node.play() }
            call.resolve()
        }
    }

    @objc func speak(_ call: CAPPluginCall) {
        let text = call.getString("text") ?? ""
        let lang = call.getString("lang") ?? "de-DE"
        let rate = Float(call.getDouble("rate") ?? 1.0)
        DispatchQueue.main.async {
            if text.isEmpty { call.resolve(); return }
            self.activateSession()
            if self.synth.isSpeaking { self.synth.stopSpeaking(at: .immediate) }
            let u = AVSpeechUtterance(string: text)
            u.voice = AVSpeechSynthesisVoice(language: lang)
            u.rate = min(AVSpeechUtteranceMaximumSpeechRate, AVSpeechUtteranceDefaultSpeechRate * rate)
            self.synth.speak(u)
            call.resolve()
        }
    }

    private func render(_ tones: [JSObject]) -> AVAudioPCMBuffer? {
        func num(_ o: JSObject, _ k: String, _ d: Double) -> Double { return (o[k] as? NSNumber)?.doubleValue ?? d }
        let sr = sampleRate
        var end = 0.05
        for t in tones { end = max(end, num(t, "t", 0) + num(t, "d", 0.1) + 0.05) }
        let frames = Int(min(end, 4.0) * sr)
        guard frames > 0,
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frames)),
              let out = buffer.floatChannelData?[0] else { return nil }
        buffer.frameLength = AVAudioFrameCount(frames)
        var mix = [Double](repeating: 0, count: frames)
        for t in tones {
            let f = num(t, "f", 880), v = max(0.0002, num(t, "v", 0.3)), d = max(0.02, num(t, "d", 0.1))
            let start = Int(num(t, "t", 0) * sr), len = Int(d * sr), att = 0.008 * sr
            let noise = (t["n"] as? NSNumber)?.boolValue ?? false
            // Bandpass (RBJ-Biquad) für das Klacken
            let w0 = 2 * Double.pi * f / sr, alpha = sin(w0) / (2 * 3.0)
            let b0 = alpha, b2 = -alpha, a0 = 1 + alpha, a1 = -2 * cos(w0), a2 = 1 - alpha
            var x1 = 0.0, x2 = 0.0, y1 = 0.0, y2 = 0.0
            for k in 0..<len {
                let i = start + k
                if i >= frames { break }
                let x = Double(k)
                if noise {
                    let raw = Double.random(in: -1...1) * pow(1 - x / Double(len), 6)
                    let y = (b0 * raw + b2 * x2 - a1 * y1 - a2 * y2) / a0
                    x2 = x1; x1 = raw; y2 = y1; y1 = y
                    mix[i] += y * v
                } else {
                    // wie im Browser: 8 ms Anstieg, dann exponentiell ausklingen
                    let env = x < att ? 0.0001 * pow(v / 0.0001, x / att) : v * pow(0.0001 / v, (x - att) / max(1, Double(len) - att))
                    mix[i] += env * sin(2 * Double.pi * f * x / sr)
                }
            }
        }
        let peak = mix.reduce(0) { max($0, abs($1)) }
        let gain = peak > 0.95 ? 0.95 / peak : 1.0
        for i in 0..<frames { out[i] = Float(mix[i] * gain) }
        return buffer
    }
}

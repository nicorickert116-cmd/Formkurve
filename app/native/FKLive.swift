
// MARK: - Formkurve: Live-Aktivität (Plugin „FKLive“)
// Zeigt Pause, Halte-Timer und den nächsten Satz auf dem Sperrbildschirm und in der Dynamic Island.
// Die Darstellung steckt in der Widget-Erweiterung „FKTimer“, die Daten (FKAttributes) sind in beiden gleich.
@objc(FKLivePlugin)
public class FKLivePlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "FKLivePlugin"
    public let jsName = "FKLive"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "update", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "end", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "status", returnType: CAPPluginReturnPromise)
    ]

    @objc func status(_ call: CAPPluginCall) {
        if #available(iOS 16.2, *) {
            call.resolve(["supported": true, "enabled": ActivityAuthorizationInfo().areActivitiesEnabled])
        } else {
            call.resolve(["supported": false, "enabled": false])
        }
    }

    @objc func update(_ call: CAPPluginCall) {
        guard #available(iOS 16.2, *) else { call.resolve(["ok": false, "error": "iOS 16.2 nötig"]); return }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { call.resolve(["ok": false, "error": "aus"]); return }
        let nowMs = Date().timeIntervalSince1970 * 1000
        let start = Date(timeIntervalSince1970: (call.getDouble("start") ?? nowMs) / 1000)
        var end = Date(timeIntervalSince1970: (call.getDouble("end") ?? nowMs) / 1000)
        if end < start { end = start }
        let mode = call.getString("mode") ?? "train"
        let state = FKAttributes.ContentState(
            mode: mode, title: call.getString("title") ?? "", label: call.getString("label") ?? "", next: call.getString("next") ?? "",
            start: start, end: end, done: call.getInt("done") ?? 0, total: call.getInt("total") ?? 0)
        let content = ActivityContent(state: state, staleDate: mode == "train" ? nil : end)
        let attrs = FKAttributes(sid: call.getString("sid") ?? "training", name: call.getString("name") ?? "Training", color: call.getString("color") ?? "#E5564A")
        Task { @MainActor in
            let all = Activity<FKAttributes>.activities
            if let a = all.first(where: { $0.attributes.sid == attrs.sid && $0.activityState == .active }) {
                await a.update(content)
                for o in all where o.id != a.id { await o.end(nil, dismissalPolicy: .immediate) }
                call.resolve(["ok": true])
                return
            }
            for o in all { await o.end(nil, dismissalPolicy: .immediate) }
            do {
                _ = try Activity.request(attributes: attrs, content: content, pushType: nil)
                call.resolve(["ok": true])
            } catch {
                call.resolve(["ok": false, "error": error.localizedDescription])
            }
        }
    }

    @objc func end(_ call: CAPPluginCall) {
        guard #available(iOS 16.2, *) else { call.resolve(); return }
        Task { @MainActor in
            for a in Activity<FKAttributes>.activities { await a.end(nil, dismissalPolicy: .immediate) }
            call.resolve()
        }
    }
}

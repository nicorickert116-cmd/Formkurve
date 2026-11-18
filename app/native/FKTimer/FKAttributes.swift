import ActivityKit
import Foundation

// MARK: - Formkurve: Daten der Live-Aktivität (identisch in App und Widget-Erweiterung)
@available(iOS 16.1, *)
struct FKAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var mode: String      // train | rest | switch | hold
        var title: String     // „Pause“, „Halten“, „Training läuft“
        var label: String     // „Als Nächstes: Bankdrücken“
        var next: String      // „Satz 3 von 4 · 80 kg × 8 Wdh.“
        var start: Date
        var end: Date
        var done: Int
        var total: Int
    }
    var sid: String
    var name: String
    var color: String
}

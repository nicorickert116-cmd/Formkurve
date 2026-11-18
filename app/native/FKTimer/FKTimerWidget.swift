import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Formkurve: Pausen-Timer auf dem Sperrbildschirm und in der Dynamic Island
// Die Zeit zählt iOS selbst herunter (Text(timerInterval:)), die App muss dafür nicht laufen.

@main
struct FKTimerBundle: WidgetBundle {
    var body: some Widget { FKTimerLive() }
}

private extension Color {
    init(fkHex: String) {
        var s = fkHex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)
        self.init(red: Double((v >> 16) & 0xFF) / 255, green: Double((v >> 8) & 0xFF) / 255, blue: Double(v & 0xFF) / 255)
    }
}

private func fkDisplay(_ size: CGFloat) -> Font { Font.custom("BarlowCondensed-ExtraBold", size: size) }
private let fkInk = Color.white
private let fkMuted = Color.white.opacity(0.62)

private struct FKModel {
    let st: FKAttributes.ContentState
    let name: String
    let accent: Color
    let stale: Bool
    var timed: Bool { st.mode != "train" }
    var over: Bool { timed && (stale || st.end <= Date()) }
    var range: ClosedRange<Date> { st.start...max(st.end, st.start.addingTimeInterval(1)) }
    var overWord: String { st.mode == "hold" ? "Geschafft" : "Weiter" }
    var overTitle: String { st.mode == "hold" ? "Zeit um" : (st.mode == "switch" ? "Wechselpause vorbei" : "Pause vorbei") }
    var icon: String { st.mode == "hold" ? "stopwatch" : (st.mode == "train" ? "dumbbell.fill" : "timer") }

    @ViewBuilder func clock(_ size: CGFloat) -> some View {
        if over {
            Text(overWord.uppercased()).font(fkDisplay(size)).foregroundColor(accent)
        } else if timed {
            Text(timerInterval: range, countsDown: true).font(fkDisplay(size)).monospacedDigit().foregroundColor(accent)
        } else {
            Text(timerInterval: st.start...st.start.addingTimeInterval(6 * 3600), countsDown: false).font(fkDisplay(size)).monospacedDigit().foregroundColor(fkInk)
        }
    }

    @ViewBuilder var bar: some View {
        if timed && !over {
            ProgressView(timerInterval: range, countsDown: true, label: { EmptyView() }, currentValueLabel: { EmptyView() })
                .progressViewStyle(.linear).tint(accent)
        } else if st.total > 0 {
            ProgressView(value: Double(min(st.done, st.total)), total: Double(st.total)).progressViewStyle(.linear).tint(accent)
        }
    }
}

private struct FKLockView: View {
    let m: FKModel
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 7) {
                Circle().fill(m.accent).frame(width: 9, height: 9)
                Text(m.name.uppercased()).font(.system(size: 12, weight: .bold)).tracking(1.2).foregroundColor(fkMuted).lineLimit(1)
                Spacer(minLength: 8)
                if m.st.total > 0 {
                    Text("\(m.st.done)/\(m.st.total) Sätze").font(.system(size: 12, weight: .semibold)).monospacedDigit().foregroundColor(fkMuted)
                }
            }
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                m.clock(50).lineLimit(1).minimumScaleFactor(0.7).frame(maxWidth: .infinity, alignment: .leading)
                Text(m.over ? m.overTitle : m.st.title).font(.system(size: 15, weight: .bold)).foregroundColor(fkInk).lineLimit(1).fixedSize()
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(m.st.label).font(.system(size: 14, weight: .semibold)).foregroundColor(fkInk).lineLimit(1)
                if !m.st.next.isEmpty { Text(m.st.next).font(.system(size: 13)).foregroundColor(fkMuted).lineLimit(1) }
            }
            m.bar.padding(.top, 3)
        }
        .padding(.horizontal, 18).padding(.vertical, 14)
    }
}

struct FKTimerLive: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FKAttributes.self) { ctx in
            FKLockView(m: FKModel(st: ctx.state, name: ctx.attributes.name, accent: Color(fkHex: ctx.attributes.color), stale: ctx.isStale))
                .activityBackgroundTint(Color(red: 0.05, green: 0.06, blue: 0.07).opacity(0.94))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { ctx in
            let m = FKModel(st: ctx.state, name: ctx.attributes.name, accent: Color(fkHex: ctx.attributes.color), stale: ctx.isStale)
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Image(systemName: m.icon).foregroundColor(m.accent)
                        Text(m.over ? m.overTitle : m.st.title).font(.system(size: 15, weight: .bold)).lineLimit(1)
                    }.padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    m.clock(30).lineLimit(1).minimumScaleFactor(0.6).frame(maxWidth: 110, alignment: .trailing).padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(m.st.label).font(.system(size: 14, weight: .semibold)).lineLimit(1)
                        if !m.st.next.isEmpty { Text(m.st.next).font(.system(size: 13)).foregroundColor(fkMuted).lineLimit(1) }
                        m.bar.padding(.top, 2)
                    }.padding(.horizontal, 4)
                }
            } compactLeading: {
                Image(systemName: m.icon).foregroundColor(m.accent)
            } compactTrailing: {
                Group {
                    if m.over { Text(m.st.mode == "hold" ? "✓" : "Los") }
                    else if m.timed { Text(timerInterval: m.range, countsDown: true) }
                    else { Text(timerInterval: m.st.start...m.st.start.addingTimeInterval(6 * 3600), countsDown: false) }
                }
                .font(.system(size: 15, weight: .semibold)).monospacedDigit().foregroundColor(m.timed ? m.accent : fkInk)
                .multilineTextAlignment(.trailing).frame(maxWidth: 52)
            } minimal: {
                Image(systemName: m.icon).foregroundColor(m.accent)
            }
            .keylineTint(m.accent)
        }
    }
}

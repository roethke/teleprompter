import SwiftUI

/// Measures the rendered height of the script text.
private struct HeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

struct ContentView: View {
    @EnvironmentObject var model: PrompterModel

    private let timer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            background

            if model.isEditing {
                editor
            } else {
                // Reserved side gutters so controls never overlap the text.
                HStack(spacing: 0) {
                    leftControls
                    reader
                    rightControls
                }
            }
        }
        .onReceive(timer) { _ in model.tick() }
        .frame(minWidth: 220, minHeight: 60)
    }

    // MARK: Background
    private var background: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Color.black.opacity(0.82))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
            )
    }

    // MARK: Reading area
    private var reader: some View {
        GeometryReader { geo in
            Text(model.script)
                .font(.system(size: model.fontSize, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .lineSpacing(model.fontSize * 0.28)
                .multilineTextAlignment(.center)
                .frame(width: max(1, geo.size.width - 12))
                // Take the text's true, full height instead of being squished by
                // the clipping frame below — otherwise the scroll range is zero.
                .fixedSize(horizontal: false, vertical: true)
                // Lead-in / tail-out so the first line starts below the top fade
                // and the last line can finish in the clear reading zone.
                .padding(.top, geo.size.height * 0.28)
                .padding(.bottom, geo.size.height * 0.6)
                .background(
                    GeometryReader { g in
                        Color.clear.preference(key: HeightKey.self, value: g.size.height)
                    }
                )
                .offset(y: -model.offset)
                .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
                .clipped()
                .mask(fadeMask)
                .onAppear { model.viewportHeight = geo.size.height }
                .onChange(of: geo.size.height) { model.viewportHeight = geo.size.height }
                .onPreferenceChange(HeightKey.self) { model.contentHeight = $0 }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Soft fade at top and bottom so lines glide in and out.
    private var fadeMask: some View {
        LinearGradient(
            stops: [
                .init(color: .clear, location: 0.0),
                .init(color: .black, location: 0.16),
                .init(color: .black, location: 0.84),
                .init(color: .clear, location: 1.0),
            ],
            startPoint: .top, endPoint: .bottom
        )
    }

    // MARK: Side control columns
    // Playback + speed on the left, size + edit/close on the right, so the full
    // window height stays available for text.
    private var leftControls: some View {
        controlColumn {
            iconButton(model.isPlaying ? "pause.fill" : "play.fill",
                       help: model.isPlaying ? "Pause (Space)" : "Play (Space)") {
                model.togglePlay()
            }
            iconButton("gobackward", help: "Restart (R)") { model.restart() }
            iconButton("hare.fill", help: "Faster (+)") { model.bumpSpeed(5) }
            iconButton("tortoise.fill", help: "Slower (-)") { model.bumpSpeed(-5) }
        }
    }

    private var rightControls: some View {
        controlColumn {
            textButton("A", size: 17, help: "Bigger text (])") { model.bumpFont(2) }
            textButton("A", size: 10, help: "Smaller text ([)") { model.bumpFont(-2) }
            iconButton("pencil", help: "Edit script (E)") { model.isEditing = true }
            iconButton("xmark", help: "Quit (Esc)") { NSApp.terminate(nil) }
        }
    }

    private func controlColumn<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(spacing: 2) {
            content()
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 2)
        .background(Capsule().fill(Color.black.opacity(0.55)))
        .padding(4)
    }

    private func iconButton(_ name: String, help: String, active: Bool = false,
                            action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: name)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(active ? Color.accentColor : .white.opacity(0.85))
                .frame(width: 24, height: 22)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(help)
    }

    private func textButton(_ label: String, size: CGFloat, help: String,
                            action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: size, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))
                .frame(width: 24, height: 22)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(help)
    }

    // MARK: Editor overlay
    private var editor: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Paste your script")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
                Button("Done") { model.isEditing = false }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .help("Done (Esc)")
            }
            TextEditor(text: $model.script)
                .font(.system(size: 15, design: .rounded))
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.08)))
        }
        .padding(12)
    }
}

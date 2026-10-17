import AppKit

struct Tone {
    let name: String
    let hex: String
    var dark = false
    var original = false
    var rgb: [Double] {
        let n = UInt32(hex, radix: 16)!
        return [Double((n >> 16) & 255), Double((n >> 8) & 255), Double(n & 255)]
    }
    var color: NSColor { NSColor(srgbRed: rgb[0]/255, green: rgb[1]/255, blue: rgb[2]/255, alpha: 1) }
}

let tones: [Tone] = [
    Tone(name: "Crema · recomendado", hex: "F4EEDC"),
    Tone(name: "Blanco suavizado", hex: "F7F7F2"),
    Tone(name: "Crema cálido", hex: "EFE2C6"),
    Tone(name: "Gris claro", hex: "EEEEEE"),
    Tone(name: "Gris cálido", hex: "E9E6DF"),
    Tone(name: "Gris neutro", hex: "DEDEDE"),
    Tone(name: "Papel marfil", hex: "FAF3E3"),
    Tone(name: "Pergamino suave", hex: "F2E8CF"),
    Tone(name: "Arena clara", hex: "EDE3D1"),
    Tone(name: "Avena", hex: "E7DFCF"),
    Tone(name: "Piedra", hex: "DDD9D0"),
    Tone(name: "Champiñón", hex: "DCD5C9"),
    Tone(name: "Salvia muy clara", hex: "E8EEDF"),
    Tone(name: "Verde niebla", hex: "E2EBE6"),
    Tone(name: "Azul bruma", hex: "E7EDF1"),
    Tone(name: "Azul grisáceo", hex: "DDE5EA"),
    Tone(name: "Lavanda grisácea", hex: "EAE6EE"),
    Tone(name: "Rosa empolvado", hex: "F0E5E1"),
    Tone(name: "Oscuro suave", hex: "303030", dark: true),
    Tone(name: "Oscuro más claro", hex: "404040", dark: true),
    Tone(name: "Blanco original", hex: "FFFFFF", original: true)
]

let domain = "net.sourceforge.skim-app.skim"
func plan(_ t: Tone) -> [[String]] {
    var commands = [["write", domain, "SKInvertColorsInDarkMode", "-bool", t.dark ? "true" : "false"],
                    ["write", domain, "SKSepiaTone", "-float", "0"]]
    if t.dark || t.original {
        commands.append(["delete", domain, "SKWhitePoint"])
    } else {
        commands.append(["write", domain, "SKWhitePoint", "-array"] + t.rgb.map { String(format: "%.8f", locale: Locale(identifier: "en_US_POSIX"), $0/255) } + ["1"])
    }
    if t.dark {
        commands.append(["write", domain, "SKInvertedColorsBackgroundWhite", "-float", String(format: "%.8f", locale: Locale(identifier: "en_US_POSIX"), t.rgb[0]/255)])
    } else {
        commands.append(["delete", domain, "SKInvertedColorsBackgroundWhite"])
    }
    return commands
}

class SwatchButton: NSButton {
    var tone: Tone!
    override func draw(_ dirtyRect: NSRect) {
        let r = bounds.insetBy(dx: 1, dy: 1)
        let path = NSBezierPath(roundedRect: r, xRadius: 9, yRadius: 9)
        tone.color.setFill(); path.fill()
        (isHighlighted ? NSColor.controlAccentColor : NSColor.black.withAlphaComponent(0.16)).setStroke()
        path.lineWidth = isHighlighted ? 3 : 1; path.stroke()
        let foreground: NSColor = tone.dark ? .white : NSColor(srgbRed: 0.13, green: 0.18, blue: 0.17, alpha: 1)
        let text = NSMutableAttributedString(string: tone.name + "\n", attributes: [.font: NSFont.systemFont(ofSize: 12, weight: .semibold), .foregroundColor: foreground])
        text.append(NSAttributedString(string: "#" + tone.hex, attributes: [.font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular), .foregroundColor: foreground.withAlphaComponent(0.8)]))
        text.draw(in: NSRect(x: 13, y: 11, width: bounds.width-22, height: 35))
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var window: NSWindow!
    var status: NSTextField!
    var buttons: [NSButton] = []
    var timer: Timer?
    var pending: Tone?
    var attempts = 0
    var appURL: URL?

    func label(_ text: String, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, size: CGFloat = 12, bold: Bool = false) -> NSTextField {
        let l = NSTextField(wrappingLabelWithString: text)
        l.frame = NSRect(x: x, y: y, width: w, height: h)
        l.font = .systemFont(ofSize: size, weight: bold ? .semibold : .regular)
        window.contentView!.addSubview(l)
        return l
    }
    func applicationDidFinishLaunching(_ notification: Notification) {
        window = NSWindow(contentRect: NSRect(x: 0,y: 0,width: 700,height: 740), styleMask: [.titled,.closable,.miniaturizable], backing: .buffered, defer: false)
        window.title = "Colores para Skim"
        window.delegate = self
        window.isReleasedWhenClosed = false
        _ = label("Elige el papel para tu próxima lectura", x: 24,y: 682,w: 650,h: 34,size: 22,bold: true)
        _ = label("Pulsa un color para aplicarlo. Skim se cerrará y se volverá a abrir; guarda tus cambios si lo solicita.",x: 24,y: 638,w: 650,h: 40)
        for (i,tone) in tones.enumerated() {
            let b = SwatchButton(frame: NSRect(x: 24+(i%3)*220,y: 568-(i/3)*66,width: 212,height: 58))
            b.tone = tone; b.title = tone.name; b.tag = i
            b.setAccessibilityLabel(tone.name + ", código " + tone.hex)
            b.target = self; b.action = #selector(selectTone(_:))
            window.contentView!.addSubview(b);buttons.append(b)
        }
        _ = label("Los tonos oscuros requieren la apariencia Oscuro de macOS y Skim 1.7.16 o posterior. Los demás requieren Skim 1.6.17 o posterior. Los colores de imágenes también pueden variar.",x: 24,y: 100,w: 650,h: 44,size: 11)
        status = label("Para empezar: crema suave. El ajuste cambia la vista de Skim, no tus PDF.",x: 24,y: 45,w: 650,h: 44,size: 12)
        window.center();window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
    func error(_ message: String) {
        status.stringValue = message
        let alert = NSAlert();alert.messageText = "No se ha podido aplicar el color";alert.informativeText = message
        alert.runModal()
    }
    func isSupported(_ version: String, minimum: String) -> Bool {
        version.compare(minimum, options: .numeric) != .orderedAscending
    }
    @objc func selectTone(_ sender: NSButton) {
        guard pending == nil else { return }
        let tone = tones[sender.tag]
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: domain), let bundle = Bundle(url: url) else {
            error("No encuentro Skim oficial. Instálalo y ábrelo una vez antes de usar este selector.");return
        }
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
        guard isSupported(version, minimum: tone.dark ? "1.7.16" : "1.6.17") else {
            error("Tu Skim es la versión \(version). Actualízalo para utilizar este tono.");return
        }
        if tone.dark && NSApp.effectiveAppearance.bestMatch(from: [.darkAqua,.aqua]) != .darkAqua {
            error("Activa primero la apariencia Oscuro en los ajustes de apariencia de macOS y vuelve a pulsar este tono.");return
        }
        appURL = url
        pending = tone;buttons.forEach { $0.isEnabled = false }
        let running = NSRunningApplication.runningApplications(withBundleIdentifier: domain)
        if running.isEmpty { applyPending();return }
        status.stringValue = "Cerrando Skim normalmente… Si pide guardar, responde en Skim. Puedes cancelar el cierre."
        for app in running { app.terminate() }
        attempts = 0
        timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] timer in
            guard let self = self else { timer.invalidate();return }
            self.attempts += 1
            if NSRunningApplication.runningApplications(withBundleIdentifier: domain).isEmpty {
                timer.invalidate();self.timer = nil;self.applyPending()
            } else if self.attempts >= 400 {
                timer.invalidate();self.timer = nil;self.pending = nil;self.buttons.forEach { $0.isEnabled = true }
                self.status.stringValue = "Skim sigue abierto. No se ha cambiado el color. Cierra Skim y vuelve a elegir."
            }
        }
    }
    func execute(_ arguments: [String]) throws {
        // An absent preference is already reset. Do not hide other command failures.
        if arguments.first == "delete" {
            let read = Process();read.executableURL=URL(fileURLWithPath:"/usr/bin/defaults")
            read.arguments=["read", domain, arguments[2]];read.standardOutput=FileHandle.nullDevice;read.standardError=FileHandle.nullDevice
            try read.run();read.waitUntilExit()
            if read.terminationStatus != 0 { return }
        }
        let p=Process();p.executableURL=URL(fileURLWithPath:"/usr/bin/defaults");p.arguments=arguments
        p.standardOutput=FileHandle.nullDevice;let pipe=Pipe();p.standardError=pipe
        try p.run();let data=pipe.fileHandleForReading.readDataToEndOfFile();p.waitUntilExit()
        if p.terminationStatus != 0 { throw NSError(domain:"ColoresSkim",code:Int(p.terminationStatus),userInfo:[NSLocalizedDescriptionKey:String(data:data,encoding:.utf8) ?? "Error de preferencias"]) }
    }
    func applyPending() {
        guard let tone = pending else { return }
        defer { pending = nil;buttons.forEach { $0.isEnabled = true } }
        do {
            for args in plan(tone) { try execute(args) }
            status.stringValue = "Aplicado: \(tone.name) · #\(tone.hex). Abriendo Skim…"
            if let url = appURL {
                NSWorkspace.shared.openApplication(at:url,configuration:NSWorkspace.OpenConfiguration()) { [weak self] _,err in
                    DispatchQueue.main.async {
                        if let err = err { self?.status.stringValue = "Color guardado. Abre Skim manualmente: \(err.localizedDescription)" }
                    }
                }
            }
        } catch { self.error("El cambio puede haberse aplicado parcialmente. \(error.localizedDescription)") }
    }
}

if CommandLine.arguments.contains("--check") {
    precondition(tones.count == 21)
    for t in tones {
        precondition(t.rgb.count == 3 && t.rgb.allSatisfy { $0 >= 0 && $0 <= 255 })
        for args in plan(t) { precondition(args[1] == domain) }
        if t.dark { precondition(t.rgb[0] == t.rgb[1] && t.rgb[1] == t.rgb[2]) }
    }
    precondition(plan(tones[0])[2].suffix(4) == ["0.95686275","0.93333333","0.86274510","1"])
    precondition(plan(tones.last!).contains(["delete",domain,"SKWhitePoint"]))
    print("OK: 21 tonos; RGB, plan de cambios y restauración verificados. No se han modificado preferencias.")
} else {
    let app=NSApplication.shared
    let delegate=AppDelegate()
    app.setActivationPolicy(.regular);app.delegate=delegate;app.run()
}

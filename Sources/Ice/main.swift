//
//  main.swift
//  Ice
//
//  Minimal core of Ice: hides the menu bar items that sit to the left of a
//  divider by widening the divider until those items are pushed off screen.
//  Uses no network code and needs no Screen Recording or Accessibility access.
//

import AppKit
import ServiceManagement

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    /// Divider length while hiding; wide enough to push everything to its left off screen.
    private static let expandedLength: CGFloat = 8000

    private let iceIcon: NSStatusItem
    private let divider: NSStatusItem
    private var isHiding = false

    private let hiddenImage = AppDelegate.templateImage(named: "IceCubeFill")
    private let shownImage = AppDelegate.templateImage(named: "IceCubeStroke")
    private let dividerImage = NSImage(systemSymbolName: "chevron.compact.left", accessibilityDescription: "Divider")

    override init() {
        // Seed the positions on first launch so the divider starts just left of
        // the Ice icon; after that, macOS remembers wherever the user
        // Command-drags them. macOS 27 ignores a position of 0.
        let defaults = UserDefaults.standard
        for (autosaveName, position) in [("IceIcon", 1), ("IceDivider", 2)] {
            let key = "NSStatusItem Preferred Position \(autosaveName)"
            if defaults.object(forKey: key) == nil {
                defaults.set(position, forKey: key)
            }
        }

        iceIcon = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        iceIcon.autosaveName = "IceIcon"
        divider = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        divider.autosaveName = "IceDivider"
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        for item in [iceIcon, divider] {
            item.button?.target = self
            item.button?.action = #selector(handleClick)
            item.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        setHiding(true)
    }

    /// Opening Ice again while it is running shows everything. This is the way
    /// back if the divider was dragged to the right of the Ice icon, since hiding
    /// then pushes the Ice icon off screen too. (macOS 27 hosts status items in
    /// another process, so their positions can't be checked from here.)
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        setHiding(false)
        return false
    }

    @objc private func handleClick() {
        guard let event = NSApp.currentEvent else {
            return
        }
        if event.type == .rightMouseUp || event.modifierFlags.contains(.control) {
            showMenu()
        } else {
            setHiding(!isHiding)
        }
    }

    private func setHiding(_ hide: Bool) {
        isHiding = hide
        divider.length = isHiding ? Self.expandedLength : NSStatusItem.variableLength
        divider.button?.image = isHiding ? nil : dividerImage
        // Keep the invisible, expanded divider from highlighting when clicked.
        divider.button?.cell?.isEnabled = !isHiding
        iceIcon.button?.image = isHiding ? hiddenImage : shownImage
    }

    private func showMenu() {
        let menu = NSMenu()
        let launchAtLogin = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        launchAtLogin.target = self
        launchAtLogin.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(launchAtLogin)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Ice", action: #selector(NSApplication.terminate), keyEquivalent: "q"))

        // Attaching the menu only for this click keeps left clicks toggling.
        iceIcon.menu = menu
        iceIcon.button?.performClick(nil)
        iceIcon.menu = nil
    }

    @objc private func toggleLaunchAtLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSAlert(error: error).runModal()
        }
    }

    private static func templateImage(named name: String) -> NSImage? {
        let image = NSImage(named: name)
        // The source images are 40×40 pixels, drawn for 2x displays.
        image?.size = NSSize(width: 20, height: 20)
        image?.isTemplate = true
        return image
    }
}

let delegate = AppDelegate()
NSApplication.shared.delegate = delegate
NSApplication.shared.run()

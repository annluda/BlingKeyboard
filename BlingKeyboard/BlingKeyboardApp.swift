//
//  BlingKeyboardApp.swift
//  BlingKeyboard
//
//  Created by ald on 2025/4/9.
//

import SwiftUI
import AppKit
import Carbon.HIToolbox

@main
struct BlingKeyboardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(width: 800, height: 300)
                .border(Color.clear, width: 0) // 添加这行确保无边框
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .windowResizability(.contentSize) // 固定窗口大小
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        if let window = NSApplication.shared.windows.first {
            window.level = .floating
            window.isOpaque = false
            window.backgroundColor = .clear
            window.ignoresMouseEvents = false
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            window.hasShadow = false // 移除阴影
            window.styleMask = .borderless // 设置为无边框窗口
        }
        KeyboardMonitor.shared.start()
    }
}

class KeyboardMonitor {
    static let shared = KeyboardMonitor()

    private var eventTap: CFMachPort?

    func start() {
        let eventMask = (1 << CGEventType.keyDown.rawValue)
        if let eventTap = CGEvent.tapCreate(tap: .cgSessionEventTap,
                                            place: .headInsertEventTap,
                                            options: .defaultTap,
                                            eventsOfInterest: CGEventMask(eventMask),
                                            callback: { _, type, event, _ in
            guard type == .keyDown else { return Unmanaged.passUnretained(event) }
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .keyPressed, object: keyCode)
            }
            return Unmanaged.passUnretained(event)
        }, userInfo: nil) {
            self.eventTap = eventTap
            let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            CGEvent.tapEnable(tap: eventTap, enable: true)
        } else {
            print("Failed to create event tap")
        }
    }
}

extension Notification.Name {
    static let keyPressed = Notification.Name("keyPressed")
}

struct ContentView: View {
    let keys: [[KeyModel]] = KeyboardLayout.defaultLayout
    @State private var highlightedKey: UInt16? = nil

    var body: some View {
        VStack(spacing: 8) {
            ForEach(keys, id: \ .self) { row in
                HStack(spacing: 6) {
                    ForEach(row) { key in
                        RoundedRectangle(cornerRadius: 6)
                            .fill(self.highlightedKey == key.keyCode ? Color.white : Color.gray.opacity(0.3))
                            .overlay(Text(key.label).foregroundColor(.black))
                            .frame(width: key.width, height: 40)
                    }
                }
            }
        }
        .padding()
        .background(VisualEffectView())
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .onReceive(NotificationCenter.default.publisher(for: .keyPressed)) { notification in
            if let keyCode = notification.object as? UInt16 {
                self.highlightedKey = keyCode
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.highlightedKey = nil
                }
            }
        }
    }
}

struct KeyModel: Identifiable, Hashable {
    let id = UUID()
    let label: String
    let keyCode: UInt16
    let width: CGFloat
}

struct KeyboardLayout {
    static let defaultLayout: [[KeyModel]] = [
        [
            KeyModel(label: "Q", keyCode: 12, width: 40),
            KeyModel(label: "W", keyCode: 13, width: 40),
            KeyModel(label: "E", keyCode: 14, width: 40),
            KeyModel(label: "R", keyCode: 15, width: 40),
            KeyModel(label: "T", keyCode: 17, width: 40),
            KeyModel(label: "Y", keyCode: 16, width: 40),
            KeyModel(label: "U", keyCode: 32, width: 40),
            KeyModel(label: "I", keyCode: 34, width: 40),
            KeyModel(label: "O", keyCode: 31, width: 40),
            KeyModel(label: "P", keyCode: 35, width: 40)
        ],
        [
            KeyModel(label: "A", keyCode: 0, width: 40),
            KeyModel(label: "S", keyCode: 1, width: 40),
            KeyModel(label: "D", keyCode: 2, width: 40),
            KeyModel(label: "F", keyCode: 3, width: 40),
            KeyModel(label: "G", keyCode: 5, width: 40),
            KeyModel(label: "H", keyCode: 4, width: 40),
            KeyModel(label: "J", keyCode: 38, width: 40),
            KeyModel(label: "K", keyCode: 40, width: 40),
            KeyModel(label: "L", keyCode: 37, width: 40)
        ],
        [
            KeyModel(label: "Z", keyCode: 6, width: 40),
            KeyModel(label: "X", keyCode: 7, width: 40),
            KeyModel(label: "C", keyCode: 8, width: 40),
            KeyModel(label: "V", keyCode: 9, width: 40),
            KeyModel(label: "B", keyCode: 11, width: 40),
            KeyModel(label: "N", keyCode: 45, width: 40),
            KeyModel(label: "M", keyCode: 46, width: 40)
        ]
    ]
}

struct VisualEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .behindWindow
        view.state = .active
        view.material = .hudWindow
        view.alphaValue = 0.1
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

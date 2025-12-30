//
//  RadialContextMenu.swift
//  VillagesTown
//
//  Radial context menu for mobile - actions appear around selection
//

import SwiftUI

struct RadialContextMenu: View {
    let items: [RadialMenuItem]
    let onDismiss: () -> Void

    @State private var isExpanded = false

    private let radius: CGFloat = 80

    var body: some View {
        ZStack {
            // Dimmed background tap to dismiss
            Color.black.opacity(isExpanded ? 0.3 : 0)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }
                .allowsHitTesting(isExpanded)

            // Menu items arranged radially
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                RadialMenuButton(
                    item: item,
                    isExpanded: isExpanded,
                    angle: angleFor(index: index, total: items.count),
                    radius: radius,
                    onTap: {
                        LayoutConstants.impactFeedback(style: .light)
                        item.action()
                        dismiss()
                    }
                )
            }

            // Center close button
            Button(action: dismiss) {
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.8))
                        .frame(width: 50, height: 50)

                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .scaleEffect(isExpanded ? 1 : 0.5)
            .opacity(isExpanded ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                isExpanded = true
            }
        }
    }

    private func angleFor(index: Int, total: Int) -> Double {
        // Start from top (-90°) and distribute evenly
        let startAngle = -90.0
        let spacing = 360.0 / Double(total)
        return startAngle + (Double(index) * spacing)
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.2)) {
            isExpanded = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss()
        }
    }
}

struct RadialMenuButton: View {
    let item: RadialMenuItem
    let isExpanded: Bool
    let angle: Double
    let radius: CGFloat
    let onTap: () -> Void

    private var offset: CGSize {
        guard isExpanded else { return .zero }
        let radians = angle * .pi / 180
        return CGSize(
            width: CGFloat(cos(radians)) * radius,
            height: CGFloat(sin(radians)) * radius
        )
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(item.color.opacity(0.9))
                        .frame(width: 56, height: 56)
                        .shadow(color: item.color.opacity(0.5), radius: 8, y: 4)

                    Image(systemName: item.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                }

                Text(item.label)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black, radius: 2)
            }
        }
        .buttonStyle(RadialButtonStyle())
        .offset(offset)
        .scaleEffect(isExpanded ? 1 : 0.3)
        .opacity(isExpanded ? 1 : 0)
        .animation(
            .spring(response: 0.35, dampingFraction: 0.7)
                .delay(isExpanded ? Double(item.index) * 0.03 : 0),
            value: isExpanded
        )
        .disabled(item.isDisabled)
        .opacity(item.isDisabled ? 0.4 : 1)
    }
}

struct RadialButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.85 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct RadialMenuItem: Identifiable {
    let id = UUID()
    let index: Int
    let icon: String
    let label: String
    let color: Color
    let isDisabled: Bool
    let action: () -> Void

    init(
        index: Int,
        icon: String,
        label: String,
        color: Color,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.index = index
        self.icon = icon
        self.label = label
        self.color = color
        self.isDisabled = isDisabled
        self.action = action
    }
}

// MARK: - Village Context Menu Builder

struct VillageRadialMenu: View {
    let village: Village
    let onBuild: () -> Void
    let onRecruit: () -> Void
    let onSendArmy: () -> Void
    let onInfo: () -> Void
    let onDismiss: () -> Void

    var isPlayerVillage: Bool { village.owner == "player" }
    var hasArmy: Bool {
        !GameManager.shared.getArmiesAt(villageID: village.id)
            .filter { $0.owner == "player" }.isEmpty
    }

    var body: some View {
        RadialContextMenu(
            items: buildMenuItems(),
            onDismiss: onDismiss
        )
    }

    private func buildMenuItems() -> [RadialMenuItem] {
        var items: [RadialMenuItem] = []

        if isPlayerVillage {
            items.append(RadialMenuItem(
                index: 0,
                icon: "hammer.fill",
                label: "Build",
                color: .orange,
                action: onBuild
            ))

            items.append(RadialMenuItem(
                index: 1,
                icon: "person.3.fill",
                label: "Recruit",
                color: .green,
                action: onRecruit
            ))

            items.append(RadialMenuItem(
                index: 2,
                icon: "paperplane.fill",
                label: "Send",
                color: .blue,
                isDisabled: !hasArmy,
                action: onSendArmy
            ))
        }

        items.append(RadialMenuItem(
            index: items.count,
            icon: "info.circle.fill",
            label: "Info",
            color: .purple,
            action: onInfo
        ))

        return items
    }
}

// MARK: - Army Context Menu Builder

struct ArmyRadialMenu: View {
    let army: Army
    let onMove: () -> Void
    let onInfo: () -> Void
    let onDismiss: () -> Void

    var isPlayerArmy: Bool { army.owner == "player" }

    var body: some View {
        RadialContextMenu(
            items: buildMenuItems(),
            onDismiss: onDismiss
        )
    }

    private func buildMenuItems() -> [RadialMenuItem] {
        var items: [RadialMenuItem] = []

        if isPlayerArmy && !army.isMarching {
            items.append(RadialMenuItem(
                index: 0,
                icon: "arrow.right.circle.fill",
                label: "Move",
                color: .blue,
                action: onMove
            ))
        }

        items.append(RadialMenuItem(
            index: items.count,
            icon: "info.circle.fill",
            label: "Info",
            color: .purple,
            action: onInfo
        ))

        return items
    }
}

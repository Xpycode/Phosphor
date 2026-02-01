//
//  TransformSection.swift
//  Phosphor
//
//  Created on 2026-01-31
//

import SwiftUI

struct TransformSection: View {
    @ObservedObject var appState: AppState
    @AppStorage("transformSectionExpanded") private var isExpanded: Bool = false

    /// The transform of the currently selected frame
    private var currentTransform: FrameTransform? {
        appState.selectedFrame?.transform
    }

    /// Whether a frame is selected
    private var hasSelection: Bool {
        appState.selectedFrameIndex != nil
    }

    /// Whether the transform has been modified from identity
    private var hasTransformChanges: Bool {
        !(currentTransform?.isIdentity ?? true)
    }

    var body: some View {
        if hasSelection {
            DisclosureGroup(isExpanded: $isExpanded) {
                VStack(alignment: .leading, spacing: 12) {
                    rotationControls
                    scaleControls
                    positionControls
                    actionButtons
                }
                .padding(.top, 8)
            } label: {
                HStack {
                    Text("Transform")
                        .font(.headline)
                    if hasTransformChanges {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 6, height: 6)
                    }
                }
            }
        }
    }

    // MARK: - Rotation Controls

    @ViewBuilder
    private var rotationControls: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Rotation")
                    .font(.subheadline)
                Spacer()
                Text("\(currentTransform?.rotation ?? 0)°")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }

            HStack(spacing: 8) {
                // Counter-clockwise 90°
                Button(action: { appState.rotateSelectedFrame(by: -90) }) {
                    Label("Rotate Left", systemImage: "rotate.left")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.bordered)
                .help("Rotate 90° counter-clockwise")

                // Clockwise 90°
                Button(action: { appState.rotateSelectedFrame(by: 90) }) {
                    Label("Rotate Right", systemImage: "rotate.right")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.bordered)
                .help("Rotate 90° clockwise")

                // 180°
                Button(action: { appState.rotateSelectedFrame(by: 180) }) {
                    Text("180°")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .help("Rotate 180°")

                Spacer()
            }
        }
    }

    // MARK: - Scale Controls

    @ViewBuilder
    private var scaleControls: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Scale")
                    .font(.subheadline)
                Spacer()
                Text("\(Int(currentTransform?.scale ?? 100))%")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }

            Slider(
                value: Binding(
                    get: { currentTransform?.scale ?? 100 },
                    set: { appState.updateSelectedFrameScale($0) }
                ),
                in: FrameTransform.scaleRange,
                step: 5
            )

            HStack {
                Text("50%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text("200%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Position Controls

    @ViewBuilder
    private var positionControls: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Position")
                .font(.subheadline)

            AnchorGridView(appState: appState)

            HStack(spacing: 12) {
                // Offset X
                HStack(spacing: 4) {
                    Text("X")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 12)

                    TextField(
                        "",
                        value: Binding(
                            get: { Int(currentTransform?.offsetX ?? 0) },
                            set: { appState.updateSelectedFrameOffset(x: CGFloat($0), y: nil) }
                        ),
                        format: .number
                    )
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
                    .multilineTextAlignment(.trailing)

                    Text("px")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Offset Y
                HStack(spacing: 4) {
                    Text("Y")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 12)

                    TextField(
                        "",
                        value: Binding(
                            get: { Int(currentTransform?.offsetY ?? 0) },
                            set: { appState.updateSelectedFrameOffset(x: nil, y: CGFloat($0)) }
                        ),
                        format: .number
                    )
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
                    .multilineTextAlignment(.trailing)

                    Text("px")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private var actionButtons: some View {
        HStack(spacing: 8) {
            // Reset button
            Button("Reset") {
                appState.resetSelectedFrameTransform()
            }
            .buttonStyle(.bordered)
            .disabled(currentTransform?.isIdentity ?? true)

            // Apply to All button
            Button("Apply to All") {
                appState.showApplyTransformToAllConfirmation = true
            }
            .buttonStyle(.bordered)
            .disabled(currentTransform?.isIdentity ?? true)
        }
    }
}

#Preview {
    TransformSection(appState: {
        let state = AppState()
        return state
    }())
    .frame(width: 280)
    .padding()
}

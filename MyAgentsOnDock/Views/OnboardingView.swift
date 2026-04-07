import SwiftUI

// Onboarding guide view
struct OnboardingView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .center, spacing: 8) {
                    Text("🤖")
                        .font(.system(size: 48))
                    Text("Welcome to My Agents on Dock")
                        .font(.title2.bold())
                    Text("Your Claude team, always visible on the Dock.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 8)

                Divider()

                // Step 1
                guideStep(
                    number: 1,
                    title: "Connect Your Project",
                    description: "Click the menu bar icon and select \"Connect Team Project\". Choose the folder that contains your team/agents.json file.",
                    icon: "folder.badge.plus"
                )

                // Step 2
                guideStep(
                    number: 2,
                    title: "Customize Characters",
                    description: "Open Settings to assign a unique robot character and name to each agent. Choose from 9 colorful characters.",
                    icon: "paintbrush"
                )

                // Step 3
                guideStep(
                    number: 3,
                    title: "Watch Your Team Work",
                    description: "When Claude agents are running, their characters animate 3x faster with a green glow. Click any character to see what they're up to!",
                    icon: "eye"
                )

                // Step 4
                guideStep(
                    number: 4,
                    title: "Choose Your Layout",
                    description: "In Settings, pick a layout that fits your screen: single row, single column, double rows, or double columns.",
                    icon: "rectangle.split.3x1"
                )

                // Step 5
                guideStep(
                    number: 5,
                    title: "Enable Voice",
                    description: "Turn on TTS in Settings to hear your agents speak when clicked. Choose from 9 different voices.",
                    icon: "speaker.wave.2"
                )

                Divider()

                // agents.json format
                VStack(alignment: .leading, spacing: 8) {
                    Label("agents.json Format", systemImage: "doc.text")
                        .font(.headline)

                    Text("Your team configuration file should look like this:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("""
                    {
                      "leader": {
                        "model": "opus",
                        "description": "Nova — Team lead, planning"
                      },
                      "frontend": {
                        "model": "sonnet",
                        "description": "Sprout — Frontend developer"
                      }
                    }
                    """)
                    .font(.system(size: 11, design: .monospaced))
                    .padding(12)
                    .background(Color.black.opacity(0.05))
                    .cornerRadius(8)
                }

                Divider()

                // Tips
                VStack(alignment: .leading, spacing: 8) {
                    Label("Tips", systemImage: "lightbulb")
                        .font(.headline)

                    tipRow("Drag characters to reorder them on the Dock")
                    tipRow("Click idle characters for random jokes")
                    tipRow("The app auto-detects Claude CLI processes")
                    tipRow("Character changes are saved and persist across restarts")
                    tipRow("Resize characters from 60pt to 300pt in Settings")
                }

                Spacer(minLength: 20)
            }
            .padding(24)
        }
        .frame(width: 460, height: 580)
    }

    private func guideStep(number: Int, title: String, description: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 32, height: 32)
                Text("\(number)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 13))
                        .foregroundColor(.accentColor)
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                }
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func tipRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.system(size: 12))
                .foregroundColor(.accentColor)
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
    }
}

# Momentum

**Your creative conscience on macOS.**

Momentum helps makers and developers stay accountable to their unfinished side projects by automatically detecting which projects you've been neglecting and gently nudging you back into flow.

![Momentum](https://img.shields.io/badge/macOS-13%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## ✨ Features

- **🔍 Automatic Project Discovery**: Scans your specified folders and detects Git repositories automatically
- **📊 Momentum Tracking**: Visual momentum score based on project activity with exponential decay
- **🔔 Smart Notifications**: Context-aware nudges when projects go inactive (>7 days)
- **🎭 Personality Styles**: Choose your motivation style (Friendly, Guilt Trip, Data Nerd, Coach)
- **📈 Activity Dashboard**: Beautiful SwiftUI interface showing all projects with status indicators
- **🎯 Goal Setting**: Set milestones and deadlines for individual projects
- **🤖 AI Insights** (Optional): Local AI-powered recommendations via Ollama
- **🍎 Menu Bar Widget**: Quick glance at project status from the menu bar
- **🔒 100% Private**: All data stored locally, no cloud sync, no telemetry

## 🚀 Getting Started

### Prerequisites

- macOS 13.0 (Ventura) or later
- Xcode 15.0 or later
- Swift 5.9 or later
- (Optional) [Ollama](https://ollama.ai) for AI features

### Building from Source

1. **Clone the repository**
   ```bash
   cd ~/Desktop/projects/momentum
   ```

2. **Install dependencies**
   ```bash
   swift package resolve
   ```

3. **Build the project**
   ```bash
   swift build
   ```

4. **Run the app**
   ```bash
   swift run
   ```

### Using Xcode

1. Open the project in Xcode:
   ```bash
   open Package.swift
   ```

2. Select your Mac as the run destination

3. Press `⌘R` to build and run

## 📱 Usage

### Initial Setup

1. **Choose Your Motivation Style**
   - Friendly: Warm and encouraging
   - Guilt Trip: Playfully persistent
   - Data Nerd: Pure stats and insights
   - Coach: Direct and action-oriented

2. **Select Project Folders**
   - Add folders where you keep your side projects
   - Momentum will scan for Git repositories automatically
   - Common locations: `~/Projects`, `~/Code`, `~/Developer`

3. **Configure AI** (Optional)
   - Enable AI insights if you have Ollama installed
   - Default endpoint: `http://localhost:11434`
   - Default model: `llama2`

### Main Features

#### Dashboard
- View all tracked projects sorted by last activity
- Filter by status: Active, Cooling, Inactive, Dormant
- See momentum scores and activity trends
- Search projects by name

#### Project Actions
- **Jump Back In**: Open project in VSCode or Finder
- **Set Goal**: Define milestones with optional deadlines
- **Pause Tracking**: Temporarily stop monitoring a project
- **Refresh**: Manually update project activity data

#### Menu Bar
- Quick overview of active vs inactive projects
- One-click access to main window
- View recent project activity

#### Notifications
- Smart nudges for projects inactive >7 days
- Configurable frequency (1-168 hours)
- Quiet hours support
- Actions: Open Project, Remind Later, Pause Tracking

## 🏗️ Architecture

```
Momentum/
├── Models/
│   ├── Project.swift          # Project data model with momentum scoring
│   └── Settings.swift          # App settings and motivation styles
├── Services/
│   ├── DatabaseService.swift  # SQLite persistence layer
│   ├── GitService.swift        # Git repository interaction
│   ├── ProjectDiscoveryService.swift  # Auto-discovery of projects
│   ├── ProjectMonitorService.swift    # Background activity monitoring
│   ├── NotificationManager.swift      # macOS notifications
│   └── AIService.swift         # Ollama API integration
├── Managers/
│   ├── SettingsManager.swift  # Settings state management
│   ├── ProjectStore.swift     # Project state management
│   └── MenuBarManager.swift   # Menu bar app logic
└── Views/
    ├── DashboardView.swift    # Main application UI
    ├── ProjectDetailView.swift # Individual project details
    ├── OnboardingView.swift   # First-run setup flow
    ├── SettingsView.swift     # Preferences window
    ├── AddProjectSheet.swift  # Manual project addition
    └── GoalSheet.swift        # Goal setting dialog
```

## 🧮 Momentum Scoring

The momentum score uses exponential decay:

```swift
momentumScore = 100 * exp(-daysSinceActivity / 10.0)
```

- **100%**: Activity today
- **~50%**: 7 days inactive
- **~10%**: 30 days inactive
- **0%**: Never active

### Status Levels
- 🟢 **Active**: ≤2 days
- 🟡 **Cooling**: 3-7 days
- 🟠 **Inactive**: 8-30 days
- 🔴 **Dormant**: >30 days

## 🤖 AI Features

Momentum can integrate with local AI models via Ollama for:

1. **Project Analysis**: Summarize your work patterns
2. **Next Actions**: Suggest concrete next steps
3. **Motivation**: Generate personalized encouragement
4. **Portfolio Insights**: Analyze your project portfolio

### Setting Up Ollama

1. Install Ollama:
   ```bash
   brew install ollama
   ```

2. Pull a model:
   ```bash
   ollama pull llama2
   ```

3. Start the server:
   ```bash
   ollama serve
   ```

4. Enable AI in Momentum settings

## ⚙️ Configuration

### Settings Location
- Preferences: `~/Library/Preferences/com.momentum.app.plist`
- Database: `~/Library/Application Support/Momentum/momentum.sqlite3`

### Customization
- **Nudge Frequency**: 1-168 hours (default: 24h)
- **Quiet Hours**: Customize do-not-disturb times
- **Watch Folders**: Add/remove project directories
- **Motivation Style**: Change at any time in settings

## 🔒 Privacy

- **100% Local**: All data stays on your Mac
- **No Cloud**: No server sync, no account required
- **Metadata Only**: Only reads timestamps and git stats, never code content
- **Opt-in**: AI features require explicit user consent
- **No Telemetry**: Zero tracking or analytics

## 🛣️ Roadmap

### v1.0 (Current)
- [x] Project auto-discovery
- [x] Momentum tracking with visual dashboard
- [x] Menu bar widget
- [x] Smart notifications
- [x] Multiple motivation styles
- [x] Optional AI insights via Ollama

### v1.1 (Planned)
- [ ] Activity charts and trends
- [ ] Weekly/monthly reports
- [ ] Project tags and categories
- [ ] GitHub/GitLab API integration
- [ ] Export project data

### v2.0 (Future)
- [ ] Social accountability (Discord/X integration)
- [ ] Gamification (XP, badges, streaks)
- [ ] iCloud sync between Macs
- [ ] Voice commands ("Hey Momentum...")
- [ ] Notion/Obsidian integration
- [ ] Custom notification sounds

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Built with [SwiftUI](https://developer.apple.com/xcode/swiftui/)
- Database powered by [SQLite.swift](https://github.com/stephencelis/SQLite.swift)
- AI features via [Ollama](https://ollama.ai)
- Inspired by the countless unfinished projects we all have

## 💬 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/momentum/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/momentum/discussions)

---

**Made with ❤️ for makers who start many projects and want to finish more.**


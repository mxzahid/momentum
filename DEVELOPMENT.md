# Development Guide

## Project Structure

This is a Swift Package Manager based macOS application using SwiftUI.

### Core Technologies

- **Swift 5.9+**: Modern Swift with async/await concurrency
- **SwiftUI**: Declarative UI framework for macOS
- **SQLite.swift**: Type-safe SQLite database wrapper
- **AppKit**: Menu bar and system integration
- **UserNotifications**: macOS notification system

## Building & Running

### Quick Start

```bash
# Build
swift build

# Run
swift run

# Run with release optimizations
swift run -c release
```

### Xcode Development

```bash
# Open in Xcode
open Package.swift

# Or generate Xcode project
swift package generate-xcodeproj
```

## Architecture Overview

### MVVM Pattern

The app follows the MVVM (Model-View-ViewModel) pattern with SwiftUI:

- **Models**: Pure data structures (`Project`, `AppSettings`)
- **Views**: SwiftUI views (`.swift` files in `Views/`)
- **ViewModels**: `@ObservableObject` classes (`ProjectStore`, `SettingsManager`)
- **Services**: Business logic and data access

### Data Flow

```
User Input
    ↓
SwiftUI View
    ↓
ObservableObject (ProjectStore/SettingsManager)
    ↓
Service Layer (DatabaseService, GitService, etc.)
    ↓
Database / File System / Git
```

### Key Components

#### 1. ProjectStore
- Main state container for projects
- Manages CRUD operations
- Publishes changes to UI via `@Published` properties

#### 2. SettingsManager
- Manages app-wide settings
- Persists to UserDefaults
- Controls motivation style and AI features

#### 3. DatabaseService
- SQLite database wrapper
- Stores project metadata
- Located in `~/Library/Application Support/Momentum/`

#### 4. GitService
- Interacts with Git CLI
- Extracts commit history and dates
- Runs async commands using `Process`

#### 5. ProjectMonitorService
- Background actor for monitoring
- Checks projects every hour
- Triggers notifications for inactive projects

#### 6. NotificationManager
- macOS notification handling
- Respects quiet hours
- Implements notification frequency limits

## Adding New Features

### Adding a New View

1. Create file in `Sources/Views/`:
```swift
import SwiftUI

struct MyNewView: View {
    @EnvironmentObject var projectStore: ProjectStore
    
    var body: some View {
        // Your view code
    }
}
```

2. Add to navigation in appropriate parent view

### Adding a New Service

1. Create file in `Sources/Services/`:
```swift
class MyService {
    static let shared = MyService()
    private init() {}
    
    func doSomething() async {
        // Implementation
    }
}
```

2. Call from ViewModels or other services

### Adding a New Setting

1. Add property to `AppSettings` in `Models/Settings.swift`:
```swift
struct AppSettings: Codable {
    // ... existing properties
    var myNewSetting: String
}
```

2. Update `.default` value

3. Add UI in `SettingsView.swift`

4. Add helper in `SettingsManager.swift`:
```swift
func updateMyNewSetting(_ value: String) {
    settings.myNewSetting = value
}
```

## Database Schema

### Projects Table

```sql
CREATE TABLE projects (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    path TEXT UNIQUE NOT NULL,
    last_commit_date DATETIME,
    last_file_edit_date DATETIME,
    created_date DATETIME NOT NULL,
    is_paused BOOLEAN DEFAULT FALSE,
    goal TEXT,
    goal_deadline DATETIME,
    is_git_repository BOOLEAN DEFAULT FALSE,
    commit_count INTEGER DEFAULT 0,
    file_change_count INTEGER DEFAULT 0
);
```

## Testing

### Manual Testing Checklist

- [ ] Onboarding flow completes
- [ ] Projects discovered from watch folders
- [ ] Git info extracted correctly
- [ ] Momentum scores calculate properly
- [ ] Notifications sent after 7 days inactivity
- [ ] Quiet hours respected
- [ ] Goal setting/editing works
- [ ] Menu bar updates correctly
- [ ] VSCode/Finder opening works
- [ ] AI insights generate (with Ollama)
- [ ] Settings persist across restarts

### Testing Notifications

```swift
// In NotificationSettingsView.swift
private func testNotification() {
    Task {
        let testProject = Project(
            name: "Test Project",
            path: "/tmp/test",
            lastCommitDate: Date().addingTimeInterval(-7 * 86400),
            isGitRepository: true
        )
        
        let message = settingsManager.settings.motivationStyle.generateMessage(for: testProject)
        
        await NotificationManager.shared.sendNotification(
            title: "Test Notification",
            body: message,
            project: testProject
        )
    }
}
```

## Performance Considerations

### File Scanning
- Limited to 1000 files per directory scan
- Uses `.skipsPackageDescendants` to avoid node_modules, etc.
- Async/await prevents UI blocking

### Git Operations
- All git commands run in background using `Process`
- Results cached in database
- Only refreshes when explicitly requested or on schedule

### Database
- SQLite with connection pooling
- Indexes on `path` (unique) for fast lookups
- Single shared instance prevents multiple connections

## Common Issues

### Issue: Notifications not appearing

**Solution**: Request permissions in Settings > Notifications > Momentum

### Issue: Git repos not detected

**Solution**: Ensure folders contain `.git` directory and are readable

### Issue: AI insights fail

**Solution**: 
1. Check Ollama is running: `ollama list`
2. Verify endpoint in Settings
3. Test connection with "Test Connection" button

### Issue: Menu bar icon not updating

**Solution**: Menu bar updates happen on main thread - check `MenuBarManager.updateStatusIcon()`

## Debugging

### Enable verbose logging

Add to top of `MomentumApp.swift`:
```swift
func applicationDidFinishLaunching(_ notification: Notification) {
    // Enable SQL logging
    #if DEBUG
    print("Debug mode enabled")
    #endif
    
    // ... rest of setup
}
```

### Inspect database

```bash
sqlite3 ~/Library/Application\ Support/Momentum/momentum.sqlite3
.tables
.schema projects
SELECT * FROM projects;
```

### Monitor notifications

```bash
# View system notification history
log show --predicate 'subsystem == "com.apple.UserNotifications"' --info --last 1h
```

## Code Style

- Use Swift's native naming conventions (camelCase)
- Prefer `async/await` over completion handlers
- Use `@MainActor` for UI updates
- Keep view files focused and small (<300 lines)
- Extract complex logic into services
- Comment non-obvious business logic

## Build Configurations

### Debug (default)
- Includes debug symbols
- No optimization
- Logging enabled

### Release
```bash
swift build -c release
```
- Optimized for speed
- Smaller binary
- No debug symbols

## Deployment

### Manual Installation

1. Build release binary:
```bash
swift build -c release
```

2. Binary location:
```bash
.build/release/Momentum
```

3. Copy to Applications:
```bash
cp .build/release/Momentum /Applications/
```

### Creating .app Bundle

For proper macOS app bundle, use Xcode:

1. Open `Package.swift` in Xcode
2. Archive: Product > Archive
3. Export: Distribute App > Copy App

## Future Improvements

### Performance
- [ ] Implement incremental file scanning
- [ ] Add caching layer for git operations
- [ ] Use FSEvents for real-time file monitoring

### Features
- [ ] Add unit tests
- [ ] Implement CI/CD
- [ ] Create installer package
- [ ] Add analytics (optional, privacy-first)
- [ ] Support for other version control (SVN, Mercurial)

### UI/UX
- [ ] Add animations for momentum changes
- [ ] Implement drag-and-drop for project addition
- [ ] Add keyboard shortcuts
- [ ] Dark mode customization


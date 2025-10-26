# Momentum - Quick Start Guide

## 🚀 Get Running in 5 Minutes

### Step 1: Build the App

```bash
cd ~/Desktop/projects/momentum
swift build
```

### Step 2: Run Momentum

```bash
swift run
```

The app will launch and show the onboarding screen.

### Step 3: Complete Onboarding

1. **Choose Motivation Style** (Pick one):
   - **Friendly**: "Hey! Want to pick up that project? ☕️"
   - **Guilt Trip**: "That project isn't going to finish itself..."
   - **Data Nerd**: "Project: X | Inactive: 10d | Momentum: 45%"
   - **Coach**: "Block 30 minutes today. Make the call."

2. **Select Project Folders**:
   - Click "Add Folder"
   - Navigate to where you keep projects (e.g., `~/Projects`, `~/Code`)
   - Select the folder
   - Repeat for multiple folders

3. **Click "Get Started"**
   - Momentum will scan your folders for Git repos
   - Projects will appear in the dashboard

### Step 4: Explore the Dashboard

The main window shows:

- **Sidebar**: List of all projects with status indicators
  - 🟢 Green: Active (worked on ≤2 days ago)
  - 🟡 Yellow: Cooling (3-7 days)
  - 🟠 Orange: Inactive (8-30 days)
  - 🔴 Red: Dormant (>30 days)

- **Detail View**: Click a project to see:
  - Momentum score (0-100%)
  - Last activity date
  - Commit count
  - Set goals and deadlines

- **Actions**:
  - "Open in VSCode" - Opens project in VSCode
  - "Open in Finder" - Shows project in Finder
  - "Pause Tracking" - Temporarily stop monitoring
  - "Refresh" - Update activity data

### Step 5: Menu Bar

Look for the Momentum icon in your menu bar (top-right):

- Click to see quick project overview
- Shows number of inactive projects
- One-click to open main window

### Step 6: Enable Notifications

1. Go to **System Settings** > **Notifications**
2. Find **Momentum**
3. Enable notifications
4. Choose alert style (Banner or Alert)

Now you'll receive nudges when projects go inactive!

## 🎯 Tips for Best Results

### Project Organization

Keep your projects in consistent locations:
```
~/Projects/
  ├── momentum/
  ├── my-website/
  ├── game-engine/
  └── blog/
```

### Set Goals

For each project you want to finish:
1. Select project in dashboard
2. Click "Set a Goal"
3. Write what you want to achieve
4. Optionally set a deadline

Example goals:
- "Complete user authentication by Dec 1"
- "Deploy MVP with basic features"
- "Fix top 5 GitHub issues"
- "Add dark mode support"

### Customize Notification Frequency

If daily nudges are too much:
1. Open Settings (⌘,)
2. Go to "Notifications" tab
3. Adjust "Nudge Frequency" (1-168 hours)
4. Set "Quiet Hours" to avoid late-night pings


## 🔄 Daily Workflow

### Morning Routine
1. Check menu bar for inactive projects
2. Pick one project to work on today
3. Click "Open in VSCode"
4. Make progress!

### When You Get Stuck
1. View project in dashboard
2. Review your goal
3. Break it into smaller tasks

### If You're Not Working on a Project
1. Select the project
2. Click "Pause Tracking"
3. Add a note in the goal field explaining why

## 🐛 Troubleshooting

### No projects showing up?

**Check**:
- Did you select folders with Git repos?
- Do folders contain `.git` directories?
- Try clicking "Refresh" button

**Solution**: Click "Add Project" and manually select a project folder

### Notifications not appearing?

**Check**:
- System Settings > Notifications > Momentum (enabled?)
- Are you in quiet hours?
- Has it been 24 hours since last nudge?

**Solution**: Test with Settings > Notifications > "Test Notification"

### VSCode not opening?

**Check**: Is VSCode installed with `code` command?

**Solution**: Install VSCode CLI:
1. Open VSCode
2. ⌘⇧P (Command Palette)
3. Type "Shell Command: Install 'code' command in PATH"


## 📱 Keyboard Shortcuts

- `⌘,` - Open Settings
- `⌘R` - Refresh all projects
- `⌘W` - Close window
- `⌘Q` - Quit (app stays in menu bar)

## 🎨 Customization Ideas

### Motivation Styles

Try different styles based on your mood:

- **Monday morning**: Coach (get pumped!)
- **Friday evening**: Friendly (be gentle)
- **Midweek slump**: Guilt Trip (need a push)
- **Pure focus**: Data Nerd (just facts)

Change anytime in Settings > General > Motivation Style

### Watch Folders Strategy

**Option 1**: Broad (scan everything)
```
~/Projects/
~/Work/
~/Code/
```

**Option 2**: Targeted (specific projects)
```
~/Projects/active/
~/side-projects/
```

**Option 3**: Hybrid
```
~/Projects/personal/
~/Work/side-hustles/
/Volumes/External/old-projects/
```

## 📊 Understanding Momentum

The momentum score uses exponential decay:

| Days Inactive | Momentum Score |
|--------------|----------------|
| 0 (today)    | 100%          |
| 3 days       | ~74%          |
| 7 days       | ~50%          |
| 14 days      | ~25%          |
| 30 days      | ~5%           |

**Philosophy**: Small consistent work beats sporadic marathons.

## 🎓 Next Steps

1. **Week 1**: Let Momentum discover your project situation
2. **Week 2**: Set goals for 2-3 projects you want to finish
3. **Week 3**: Respond to at least 1 nudge notification
4. **Week 4**: Review progress, adjust motivation style

## 💡 Pro Tips

1. **Don't track everything**: Pause projects you're definitely not working on
2. **Be honest with goals**: "Explore idea" is valid, not everything needs shipping
3. **Celebrate wins**: Mark projects as paused when you finish them!
4. **Weekly review**: Sunday evening, scan all projects, pick focus for the week

## 🆘 Need Help?

- **Documentation**: See `README.md` for full details
- **Development**: See `DEVELOPMENT.md` for technical info
- **Issues**: File on GitHub (if available)

---

**Remember**: Momentum is here to help, not judge. Some projects deserve to die, and that's okay. The goal is finishing what matters to you. 🚀


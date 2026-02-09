# Query Tracker Plugin

Monitor and track shell command execution results directly from Noctalia Shell. Configure commands to run periodically and view their output in a clean panel.

## Features

- **Multiple Commands**: Add unlimited shell commands to monitor
- **Auto Execution**: Commands run automatically at configurable intervals
- **Result Persistence**: Command results are saved and displayed when you open the panel
- **Status Indicators**: Visual green/red indicators for success/failure
- **Command Management**: Easy add/remove/edit commands through settings
- **Clean Interface**: Responsive panel with scrollable result list
- **Multilingual**: Full internationalization support (English/Chinese)

## Setup Instructions

### Step 1: Add Commands

1. Right-click the Query Tracker icon in your Noctalia bar
2. Select **"Settings"**
3. Click **"Add New Command"**
4. Enter:
   - **Name**: Display name for the command (e.g., "Disk Usage")
   - **Command**: Shell command to execute (e.g., `df -h / | tail -1`)
5. Click **"Add"**

### Step 2: Configure Options

- **Update Interval**: How often to execute commands (seconds, minimum 5)

### Example Commands

```bash
# Disk usage
df -h / | tail -1

# Memory usage
free -h | grep Mem

# CPU load
uptime

# Git status
git status --short

# System uptime
uptime -p

# Network connections
ss -tunp | head -5
```

## Usage

- **View Results**: Click the terminal icon to open the results panel
- **Refresh**: Click the refresh button to execute commands immediately
- **Settings**: Click the settings icon to manage commands

## Panel Layout

Each command result is displayed as a row with:
- **Status**: Green dot (success) or red dot (failure)
- **Command Name**: The name you gave the command
- **Output**: The command's stdout (or stderr if stdout is empty)
- **Timestamp**: When the command was last executed

## Configuration

| Setting | Description | Default |
|---------|-------------|---------|
| `commands` | Array of command objects {name, command} | [] |
| `updateInterval` | Execution interval in seconds | 30 |
| `results` | Array of saved command results | [] |

## Command Object Structure

```json
{
  "name": "Disk Usage",
  "command": "df -h / | tail -1"
}
```

## Result Object Structure

```json
{
  "name": "Disk Usage",
  "command": "df -h / | tail -1",
  "exitCode": 0,
  "stdout": "/dev/sda3 75% / 25%",
  "stderr": "",
  "timestamp": "2026-02-10T14:30:25.000Z",
  "success": true
}
```

## Troubleshooting

### Commands not executing

- **Check Interval**: Ensure update interval is set (minimum 5 seconds)
- **Commands Configured**: Verify commands are added in settings
- **Shell Syntax**: Ensure commands are valid shell commands

### No results displayed

- **First Run**: Results appear after first execution cycle
- **Refresh**: Click refresh button to execute commands immediately
- **Check Logs**: Look for execution logs in console

### Command failures

- **Exit Code**: Check the exit code (0 = success)
- **Stdout/Stderr**: Failed commands show stderr output
- **Command Validity**: Test command in terminal first

## Privacy

- All commands run locally on your system
- Results are stored in local plugin settings
- No data is sent to external servers

## Performance Tips

- Use reasonable update intervals (30-60 seconds recommended)
- Avoid very long-running commands
- Keep command output minimal for better display
- Remove unused commands to reduce load

## Contributing

Found a bug or have a feature request? Open an issue on the [Noctalia Plugins repository](https://github.com/fortystory/noctalia-plugins).

## Changelog

### Version 1.0.0 (2026-02-10)

**Initial Release**

Features:
- Multi-command support with configurable intervals
- Automatic periodic command execution
- Result persistence across sessions
- Success/failure status indicators
- Command management (add/remove/edit)
- Clean scrollable result panel
- Per-result timestamps
- Multilingual support (English/Chinese)
- Compatible with Noctalia Shell 3.6.0+

Technical:
- Built with Quickshell framework
- Process-based command execution
- Noctalia UI components integration
- Persistent settings storage
- Timer-based execution cycle

## License

MIT License - See repository for details

## Credits

- **Author**: forty
- **Repository**: https://github.com/fortystory/noctalia-plugins
- **Noctalia Shell**: https://noctalia.dev
- **Icons**: Nerd Fonts

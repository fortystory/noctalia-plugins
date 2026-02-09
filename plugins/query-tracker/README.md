# Query Tracker

Track and display output from shell commands in the status bar.

## Features

- Execute and display output from shell queries
- Multi-query support with individual results
- Configurable update interval
- Click to open detailed panel
- Copy output to clipboard

## Configuration

Queries are configured via the settings panel:

| Field | Description |
|-------|-------------|
| Name | Display name for the query result |
| Query | Shell command to execute |
| Update Interval | How often to refresh (in seconds) |

## Examples

Display DeepSeek balance:
```
Name: DeepSeek Balance
Query: curl -s https://api.deepseek.com/user/balance
```

Check system uptime:
```
Name: Uptime
Query: uptime
```

Check disk space:
```
Name: Disk Usage
Query: df -h /
```

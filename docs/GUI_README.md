# ServerAssistant GUI

A beautiful terminal-based GUI for managing Docker services, built with [Textual](https://textual.textualize.io/).

## Features

- 🎨 **Beautiful Interface**: Modern, responsive terminal UI with smooth animations
- 📊 **Dashboard**: Overview of all services with status indicators
- 🔧 **Service Management**: Start, stop, restart services with one click
- 📋 **Logs Viewer**: Real-time log viewing for any service
- ⚙️ **Settings**: Configuration overview and Docker environment status
- ⌨️ **Keyboard Shortcuts**: Quick navigation and actions
- 📱 **Responsive Design**: Adapts to different terminal sizes

## Installation

### Prerequisites

- Python 3.7+
- Docker and Docker Compose
- Terminal with good Unicode support

### Install Textual

```bash
pip install textual>=0.52.0
```

Or install all requirements:

```bash
pip install -r requirements.txt
```

## Usage

### Quick Start

#### Linux/macOS
```bash
# Make script executable
chmod +x scripts/startup/launch_gui.sh

# Launch GUI
./scripts/startup/launch_gui.sh
```

#### Windows
```cmd
# Launch GUI
scripts\startup\launch_gui.bat
```

#### Manual Launch
```bash
python gui_main.py
```

### Command Line Options

```bash
python gui_main.py [OPTIONS]

Options:
  --config PATH    Path to configuration file (default: config.json)
  --debug          Enable debug mode
  -h, --help       Show help message
```

## Interface Overview

### Dashboard Tab
- **Service Cards**: Visual representation of each service
- **Status Indicators**: Color-coded status (running, stopped, starting)
- **Quick Actions**: Start, stop, restart, and view logs buttons
- **Refresh Button**: Update all service statuses

### Services Tab
- **Data Table**: Detailed view of all services
- **Bulk Actions**: Start all, stop all services
- **Service Details**: Container IDs, ports, health status

### Logs Tab
- **Service Selector**: Choose which service logs to view
- **Log Viewer**: Real-time log display with syntax highlighting
- **Follow Mode**: Toggle real-time log following

### Settings Tab
- **Configuration Overview**: Server name, environment, log level
- **Docker Status**: Docker environment availability
- **Global Settings**: Backup settings, log retention

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `1` | Switch to Dashboard |
| `2` | Switch to Services |
| `3` | Switch to Logs |
| `4` | Switch to Settings |
| `r` | Refresh data |
| `q` | Quit application |
| `Tab` | Navigate between elements |
| `Enter` | Activate buttons/select items |
| `Esc` | Close dialogs/cancel actions |

## Navigation

### Mouse Support
- Click buttons to activate actions
- Click tabs to switch views
- Scroll in log viewers and tables

### Keyboard Navigation
- Use `Tab` to move between interactive elements
- Use arrow keys to navigate tables and lists
- Use `Enter` to activate buttons and select items

## Service Management

### Individual Services
1. Navigate to Dashboard or Services tab
2. Find the service you want to manage
3. Click the appropriate action button:
   - **Start**: Start the service
   - **Stop**: Stop the service
   - **Restart**: Restart the service
   - **Logs**: View service logs

### Bulk Operations
1. Go to Services tab
2. Use "Start All" or "Stop All" buttons
3. Monitor progress through notifications

## Logs Viewing

1. Go to Logs tab
2. Select a service from the dropdown
3. Click "Refresh" to load logs
4. Optionally enable "Follow" for real-time updates

## Testing

### Run GUI Tests
```bash
python tests/test_gui.py
```

This will test:
- Textual installation
- Configuration file validity
- Docker environment availability
- Module imports

## Troubleshooting

### Common Issues

#### Textual Not Found
```
Error: No module named 'textual'
```
**Solution**: Install textual
```bash
pip install textual>=0.52.0
```

#### Configuration File Not Found
```
Error: Configuration file 'config.json' not found
```
**Solution**: Ensure config.json exists in the project root

#### Docker Not Available
```
Docker: ❌ Not Available
```
**Solution**: 
- Ensure Docker is installed and running
- Check Docker daemon status
- Verify Docker Compose is available

#### Terminal Size Issues
If the interface looks cramped:
- Resize your terminal window
- The interface is responsive and will adapt
- Minimum recommended size: 80x24 characters

### Debug Mode

Run with debug mode for more detailed error information:

```bash
python gui_main.py --debug
```

## Customization

### Themes
The GUI uses Textual's built-in theming system. You can customize colors and styles by modifying `src/ui/simple_textual_app.tcss`.

### Configuration
The GUI reads from your existing `config.json` file. Any changes to the configuration will be reflected in the GUI after refreshing.

## Development

### File Structure
```
src/ui/
├── simple_textual_app.py      # Main GUI application
├── simple_textual_app.tcss    # Styles and themes
└── textual_app.py            # Full-featured version (advanced)
tests/
├── test_gui.py               # GUI testing script
└── ...                       # Other test files
```

### Adding New Features
1. Modify `simple_textual_app.py` for the main logic
2. Update `simple_textual_app.tcss` for styling
3. Test with different terminal sizes
4. Update this documentation

## Performance

The GUI is designed to be lightweight and responsive:
- Asynchronous operations for service management
- Efficient data refresh mechanisms
- Minimal memory footprint
- Fast startup time

## Contributing

When contributing to the GUI:
1. Test on different terminal emulators
2. Ensure responsive design works
3. Add appropriate keyboard shortcuts
4. Update documentation
5. Test with various screen sizes

## License

This GUI is part of the ServerAssistant project and follows the same license terms. 
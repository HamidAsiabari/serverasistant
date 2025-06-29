# ServerAssistant Documentation

Welcome to the ServerAssistant documentation! This directory contains all the documentation organized by category for easy navigation.

## 📚 Documentation Structure

### 🚀 Getting Started
- **[Main README](../README.md)** - Project overview and quick start guide

### 📖 User Guides (`guides/`)
- **[Usage Guide](guides/usage-guide.md)** - How to use ServerAssistant effectively
- **[Reorganization Guide](guides/reorganization-guide.md)** - Guide to the project reorganization
- **[Ubuntu 22 Test Guide](guides/ubuntu22-test-guide.md)** - Testing guide for Ubuntu 22.04

### ⚙️ Setup & Installation (`setup/`)
- **[Startup Guide](setup/startup-guide.md)** - Complete startup and initialization guide
- **[Persistent Storage Guide](setup/persistent-storage-guide.md)** - Setting up persistent storage
- **[Cloudflare Setup](setup/cloudflare-setup.md)** - Configuring Cloudflare integration

### 🛠️ Development (`development/`)
- **[Development Guide](development/development-guide.md)** - Development setup and guidelines
- **[Reorganization Summary](development/reorganization-summary.md)** - Technical details of project reorganization

### 🚀 Deployment (`deployment/`)
- **[Transfer to Ubuntu](deployment/transfer-to-ubuntu.md)** - Guide for deploying to Ubuntu servers

## 🎯 Quick Navigation

### For New Users
1. Start with the [Main README](../README.md)
2. Read the [Usage Guide](guides/usage-guide.md)
3. Follow the [Startup Guide](setup/startup-guide.md)

### For Developers
1. Review the [Development Guide](development/development-guide.md)
2. Check the [Reorganization Summary](development/reorganization-summary.md)
3. Explore the [Ubuntu Test Guide](guides/ubuntu22-test-guide.md)

### For Deployment
1. Read the [Transfer to Ubuntu Guide](deployment/transfer-to-ubuntu.md)
2. Configure [Persistent Storage](setup/persistent-storage-guide.md)
3. Set up [Cloudflare Integration](setup/cloudflare-setup.md)

## 📁 Directory Structure

```
serverasistant/
├── docs/                    # 📚 Organized documentation
│   ├── index.md            # This file - Documentation index
│   ├── guides/             # User guides and tutorials
│   ├── setup/              # Setup and installation guides
│   ├── development/        # Development documentation
│   └── deployment/         # Deployment and production guides
├── src/                    # 🐍 Source code
│   ├── core/              # Core application logic
│   ├── ui/                # User interface components
│   └── utils/             # Utility functions
├── scripts/               # 🔧 Utility scripts
│   ├── setup/            # Installation and setup scripts
│   ├── maintenance/      # Maintenance and cleanup scripts
│   └── testing/          # Testing and validation scripts
├── docker_services/       # 📦 Docker service definitions
│   ├── nginx/            # Nginx reverse proxy setup
│   ├── mysql/            # MySQL database service
│   ├── gitlab/           # GitLab development platform
│   └── mail-server/      # Complete email stack
├── tests/                # 🧪 Test suite
│   ├── unit/             # Unit tests
│   ├── integration/      # Integration tests
│   ├── e2e/              # End-to-end tests
│   └── scripts/          # Test scripts
└── config.json           # ⚙️ Main configuration file
```

## 🔄 Recent Changes

All documentation has been reorganized from the root directory into this structured format for better navigation and maintainability. Each file has been renamed to follow consistent naming conventions.

The `example_services` folder has been renamed to `docker_services` to better reflect its purpose as a collection of Docker service definitions.

## 📝 Contributing

When adding new documentation:
1. Place it in the appropriate category directory
2. Use kebab-case naming (e.g., `my-new-guide.md`)
3. Update this index file with a link to the new documentation
4. Follow the existing documentation style and format

## 🆘 Need Help?

If you can't find what you're looking for:
1. Check the [Main README](../README.md) for project overview
2. Review the [Usage Guide](guides/usage-guide.md) for common tasks
3. Consult the [Development Guide](development/development-guide.md) for technical details 
# Troubleshooting

Common issues and solutions for claudetainer.

## Quick Diagnostics
```bash
# Run comprehensive health check
claudetainer doctor

# Check prerequisites
claudetainer prereqs

# List running containers
claudetainer list
```

## Container Won't Start

**Symptoms:** `claudetainer up` fails or hangs

**Solutions:**
```bash
# Check if devcontainer CLI is installed
devcontainer --version

# Ensure Docker is running
docker ps

# Force clean start
claudetainer rm -f && claudetainer up
```

**Common causes:**
- Docker not running
- DevContainer CLI not installed (`npm install -g @devcontainers/cli`)
- Port conflicts (try `claudetainer rm -f` first)

## SSH Connection Failed

**Symptoms:** `claudetainer ssh` fails or times out

**Solutions:**
```bash
# Check if container is running
claudetainer up

# Verify port forwarding
nc -z localhost 2223

# Check container status
claudetainer list
```

**Common causes:**
- Container not running (`claudetainer up`)
- Port 2223 in use by another process
- SSH daemon not started in container

## Linting Issues

**Symptoms:** Claude Code hooks fail with linting errors

**Solutions:**
```bash
# Check what tools are available
which black flake8 autopep8

# Test quality control via sub-agents
# Use /check command in Claude Code to trigger quality agents
```

**Common causes:**
- Language tools not installed in container
- File permissions issues
- Malformed code that can't be auto-fixed

## Clean Reset

When all else fails:
```bash
# Remove everything and start fresh
claudetainer rm -f --config
claudetainer init
claudetainer up
```

This removes:
- All containers for the project
- `.devcontainer` directory
- Forces complete regeneration

## Performance Issues

**Symptoms:** Slow container startup or response

**Solutions:**
- Increase Docker memory allocation (Docker Desktop settings)
- Check available disk space
- Restart Docker Desktop
- Use local SSD storage for project files

## Network/Firewall Issues

**Symptoms:** Can't connect to container or download images

**Solutions:**
- Check corporate firewall settings
- Verify Docker can pull images: `docker pull mcr.microsoft.com/devcontainers/base:ubuntu`
- Configure proxy settings in Docker Desktop if needed

## Platform-Specific Issues

### macOS
- **M1/M2 compatibility:** Use `--platform linux/amd64` if container fails to start
- **File permissions:** Ensure project directory is accessible to Docker

### Windows/WSL
- **Path issues:** Use WSL2 file system for best performance
- **Docker Desktop integration:** Ensure WSL2 integration is enabled

### Linux
- **Docker permissions:** Add user to docker group: `sudo usermod -aG docker $USER`
- **systemd:** Ensure Docker service is running: `sudo systemctl start docker`

## Getting Help

1. **Run diagnostics:** `claudetainer doctor`
2. **Check logs:** `docker logs <container-id>` 
3. **Report issues:** [GitHub Issues](https://github.com/smithclay/claudetainer/issues)
4. **Include output of:** `claudetainer doctor` and `claudetainer list`
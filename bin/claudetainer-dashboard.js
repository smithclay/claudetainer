#!/usr/bin/env node

const http = require('http');
const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const os = require('os');

// Configuration
const CONFIG_DIR = path.join(os.homedir(), '.config', 'claudetainer');
const CONFIG_FILE = path.join(CONFIG_DIR, 'dashboard.json');
const PID_FILE = path.join(CONFIG_DIR, 'dashboard.pid');
const LOG_FILE = path.join(CONFIG_DIR, 'dashboard.log');

const DEFAULT_CONFIG = {
  port: 8888,
  host: '0.0.0.0',
  auto_refresh_interval: 30
};

// Utility functions
function ensureConfigDir() {
  if (!fs.existsSync(CONFIG_DIR)) {
    fs.mkdirSync(CONFIG_DIR, { recursive: true });
  }
}

function loadConfig() {
  ensureConfigDir();
  if (fs.existsSync(CONFIG_FILE)) {
    try {
      return { ...DEFAULT_CONFIG, ...JSON.parse(fs.readFileSync(CONFIG_FILE, 'utf8')) };
    } catch (e) {
      console.error('Error reading config, using defaults:', e.message);
    }
  }
  return DEFAULT_CONFIG;
}

function saveConfig(config) {
  ensureConfigDir();
  fs.writeFileSync(CONFIG_FILE, JSON.stringify(config, null, 2));
}

function log(message) {
  const timestamp = new Date().toISOString();
  const logEntry = `${timestamp} ${message}\n`;
  console.log(message);

  ensureConfigDir();
  fs.appendFileSync(LOG_FILE, logEntry);
}

function getTailscaleHostname() {
  // Determine which Tailscale command to use
  let tailscaleCmd = 'tailscale';

  try {
    // First try the system PATH version
    execSync('which tailscale', { encoding: 'utf8', timeout: 2000 });
  } catch (e) {
    // Try Mac App Store version
    try {
      const appStorePath = '/Applications/Tailscale.app/Contents/MacOS/Tailscale';
      if (fs.existsSync(appStorePath)) {
        tailscaleCmd = appStorePath;
        log('Using Tailscale from Mac App Store installation');
      } else {
        log('Tailscale CLI not found in PATH or Mac App Store location');
        return 'localhost';
      }
    } catch (fsError) {
      log('Tailscale CLI not available, using localhost');
      return 'localhost';
    }
  }

  try {
    // Get Tailscale status with MagicDNS hostname
    const statusOutput = execSync(`"${tailscaleCmd}" status --json`, { encoding: 'utf8', timeout: 5000 });
    const status = JSON.parse(statusOutput);

    // Extract MagicDNS hostname from Self.DNSName
    if (status.Self && status.Self.DNSName) {
      const magicDNSName = status.Self.DNSName.replace(/\.$/, ''); // Remove trailing dot
      log(`Found Tailscale MagicDNS hostname: ${magicDNSName}`);
      return magicDNSName;
    }

    // Fallback: try to get Tailscale IP
    const ip = execSync(`"${tailscaleCmd}" ip --4`, { encoding: 'utf8', timeout: 5000 }).trim();
    if (ip && ip !== '') {
      log(`Found Tailscale IP: ${ip}, but no MagicDNS name available`);
      return ip;
    }

    // Final fallback
    log('Tailscale available but no IP/hostname found, using localhost');
    return 'localhost';

  } catch (e) {
    log(`Warning: Could not detect Tailscale hostname: ${e.message}`);
    return 'localhost';
  }
}

function getTailscaleIP() {
  // Determine which Tailscale command to use
  let tailscaleCmd = 'tailscale';

  try {
    // First try the system PATH version
    execSync('which tailscale', { encoding: 'utf8', timeout: 2000 });
  } catch (e) {
    // Try Mac App Store version
    try {
      const appStorePath = '/Applications/Tailscale.app/Contents/MacOS/Tailscale';
      if (fs.existsSync(appStorePath)) {
        tailscaleCmd = appStorePath;
        log('Using Tailscale from Mac App Store installation');
      } else {
        log('Tailscale CLI not found in PATH or Mac App Store location');
        return 'localhost';
      }
    } catch (fsError) {
      log('Tailscale CLI not available, using localhost');
      return 'localhost';
    }
  }

  try {
    // Prioritize Tailscale IP address
    const ip = execSync(`"${tailscaleCmd}" ip --4`, { encoding: 'utf8', timeout: 5000 }).trim();
    if (ip && ip !== '') {
      log(`Found Tailscale IP: ${ip}`);
      return ip;
    }

    // Fallback: try to get MagicDNS hostname
    const statusOutput = execSync(`"${tailscaleCmd}" status --json`, { encoding: 'utf8', timeout: 5000 });
    const status = JSON.parse(statusOutput);

    if (status.Self && status.Self.DNSName) {
      const magicDNSName = status.Self.DNSName.replace(/\.$/, ''); // Remove trailing dot
      log(`Found Tailscale MagicDNS hostname: ${magicDNSName}, but using as fallback`);
      return magicDNSName;
    }

    // Final fallback
    log('Tailscale available but no IP/hostname found, using localhost');
    return 'localhost';

  } catch (e) {
    log(`Warning: Could not detect Tailscale IP: ${e.message}`);
    return 'localhost';
  }
}

function getClaudetainerContainers() {
  try {
    // Use the same logic as the CLI docker_list_containers function
    const containerIds = execSync('docker ps -q', { encoding: 'utf8', timeout: 10000 });

    if (!containerIds.trim()) {
      return [];
    }

    const containers = containerIds.trim().split('\n').map(cid => {
      try {
        // Get container details using docker inspect (same as CLI)
        const name = execSync(`docker inspect --format '{{.Name}}' "${cid}"`,
          { encoding: 'utf8', timeout: 5000 }).trim().replace(/^\//, '');

        const ports = execSync(`docker inspect --format '{{range $p, $conf := .NetworkSettings.Ports}}{{if $conf}}{{$p}}->{{(index $conf 0).HostPort}} {{end}}{{end}}' "${cid}"`,
          { encoding: 'utf8', timeout: 5000 }).trim();

        const status = execSync(`docker inspect --format '{{.State.Status}}' "${cid}"`,
          { encoding: 'utf8', timeout: 5000 }).trim();

        const localFolder = execSync(`docker inspect --format '{{index .Config.Labels "devcontainer.local_folder"}}' "${cid}"`,
          { encoding: 'utf8', timeout: 5000 }).trim();

        // Skip containers without devcontainer.local_folder label
        if (!localFolder || localFolder === '<no value>') {
          return null;
        }

        // Extract SSH-like port from ports string
        // Look for patterns like "22/tcp->2226", "2226/tcp->2226", or "0.0.0.0:2226->22/tcp"
        let sshPort = null;

        // Try different port patterns that could be SSH
        const portPatterns = [
          /(\d+)\/tcp->(\d+)/g,           // "22/tcp->2226" or "2226/tcp->2226"
          /0\.0\.0\.0:(\d+)->22\/tcp/g,   // "0.0.0.0:2226->22/tcp"
          /0\.0\.0\.0:(\d+)->(\d+)\/tcp/g // "0.0.0.0:2226->2226/tcp"
        ];

        for (const pattern of portPatterns) {
          let match;
          while ((match = pattern.exec(ports)) !== null) {
            const hostPort = parseInt(match[1]) || parseInt(match[2]);
            // Look for ports in the claudetainer range (2220-2299) or standard SSH (22)
            if ((hostPort >= 2220 && hostPort <= 2299) || hostPort === 22) {
              sshPort = hostPort;
              break;
            }
          }
          if (sshPort) break;
        }

        // Skip containers without detectable SSH ports
        if (!sshPort) {
          return null;
        }

        const projectName = path.basename(localFolder);

        // Calculate mosh UDP port range: 60000 + sshPort to 60000 + sshPort + 10
        const moshPortStart = 60000 + sshPort;

        return {
          name,
          projectName,
          sshPort,
          moshPortStart,
          status,
          localFolder,
          lastSeen: new Date().toISOString()
        };

      } catch (e) {
        log(`Warning: Could not inspect container ${cid}: ${e.message}`);
        return null;
      }
    }).filter(container => container !== null);

    return containers;
  } catch (e) {
    log(`Warning: Could not fetch Docker containers: ${e.message}`);
    return [];
  }
}

function generateDashboardHTML(containers, hostname) {
  const refreshInterval = loadConfig().auto_refresh_interval;
  const tailscaleIP = getTailscaleIP();

  return `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>📱 claudetainer dashboard</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: #1a1a1a;
            color: #ffffff;
            padding: 20px;
            line-height: 1.6;
        }
        .header {
            text-align: center;
            margin-bottom: 30px;
            padding-bottom: 20px;
            border-bottom: 1px solid #333;
        }
        .header h1 {
            font-size: 24px;
            margin-bottom: 10px;
        }
        .header .subtitle {
            color: #888;
            font-size: 14px;
        }
        .container-card {
            background: #2a2a2a;
            border-radius: 12px;
            padding: 20px;
            margin-bottom: 16px;
            border: 1px solid #333;
        }
        .container-header {
            display: flex;
            align-items: center;
            margin-bottom: 12px;
        }
        .status-dot {
            width: 12px;
            height: 12px;
            border-radius: 50%;
            margin-right: 12px;
            background: #00ff00;
        }
        .container-name {
            font-weight: 600;
            font-size: 18px;
            flex: 1;
        }
        .container-info {
            color: #aaa;
            font-size: 14px;
            margin-bottom: 16px;
        }
        .button-row {
            display: flex;
            gap: 12px;
            flex-wrap: wrap;
        }
        .btn {
            padding: 12px 20px;
            border: none;
            border-radius: 8px;
            font-size: 16px;
            font-weight: 500;
            text-decoration: none;
            text-align: center;
            display: inline-block;
            min-width: 140px;
            transition: background-color 0.2s;
        }
        .btn-primary {
            background: #007AFF;
            color: white;
        }
        .btn-primary:hover {
            background: #0056CC;
        }
        .btn-secondary {
            background: #333;
            color: white;
        }
        .btn-secondary:hover {
            background: #444;
        }
        .btn-tertiary {
            background: #222;
            color: #888;
            font-size: 14px;
            padding: 10px 16px;
            min-width: 120px;
        }
        .btn-tertiary:hover {
            background: #2a2a2a;
            color: #aaa;
        }
        .empty-state {
            text-align: center;
            padding: 60px 20px;
            color: #666;
        }
        .refresh-info {
            text-align: center;
            color: #666;
            font-size: 12px;
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #333;
        }
        @media (max-width: 768px) {
            .button-row {
                flex-direction: column;
            }
            .btn {
                min-width: 100%;
                font-size: 16px;
                padding: 14px 20px;
                margin-bottom: 8px;
            }
            .container-card {
                padding: 16px;
            }
            .header h1 {
                font-size: 20px;
            }
        }
        @media (max-width: 480px) {
            body {
                padding: 16px;
            }
            .btn {
                font-size: 14px;
                padding: 12px 16px;
            }
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>📱 Claudetainer Dashboard</h1>
        <div class="subtitle">SSH and Mosh into your development containers</div>
    </div>

    ${containers.length === 0 ? `
        <div class="empty-state">
            <h3>No running containers found</h3>
            <p>Start a claudetainer container to see it here</p>
        </div>
    ` : containers.map(container => {
        const encodedKey = encodeURIComponent(container.projectName);
        const moshCommand = `mosh -P ${container.sshPort} -p ${container.moshPortStart} vscode@${tailscaleIP}`;
        // Use proper URL encoding for Blink Shell
        const encodedCommand = encodeURIComponent(moshCommand);

        return `
        <div class="container-card">
            <div class="container-header">
                <div class="status-dot"></div>
                <div class="container-name">${container.projectName}</div>
            </div>
            <div class="container-info">
                SSH ${container.sshPort} • Mosh ${container.moshPortStart}-${container.moshPortStart + 10} • Running • ${container.localFolder}
            </div>
            <div class="button-row">
                <a href="blinkshell://run?cmd=${encodedCommand}" class="btn btn-primary">
                    🔗 Open in Blink Shell
                </a>
                <button class="btn btn-secondary" onclick="copyMoshCommand('${tailscaleIP}', ${container.sshPort}, ${container.moshPortStart})">
                    📋 Copy MOSH Command
                </button>
                <button class="btn btn-tertiary" onclick="copySSHCommand('${tailscaleIP}', ${container.sshPort})">
                    📋 Copy SSH Command
                </button>
            </div>
        </div>
        `;
    }).join('')}

    <div class="refresh-info">
        Auto-refreshes every ${refreshInterval} seconds • ${new Date().toLocaleTimeString()}
    </div>

    <script>
        function copyToClipboard(text, successMessage) {
            // Try modern clipboard API first
            if (navigator.clipboard && navigator.clipboard.writeText) {
                navigator.clipboard.writeText(text).then(() => {
                    showMessage(successMessage);
                }).catch(() => {
                    fallbackCopy(text);
                });
            } else {
                fallbackCopy(text);
            }
        }

        function fallbackCopy(text) {
            // iOS-compatible fallback: create a text area, select and copy
            const textArea = document.createElement('textarea');
            textArea.value = text;
            textArea.style.position = 'fixed';
            textArea.style.left = '-999999px';
            textArea.style.top = '-999999px';
            document.body.appendChild(textArea);
            textArea.focus();
            textArea.select();

            try {
                const successful = document.execCommand('copy');
                if (successful) {
                    showMessage('Command copied to clipboard!');
                } else {
                    promptForCopy(text);
                }
            } catch (err) {
                promptForCopy(text);
            } finally {
                document.body.removeChild(textArea);
            }
        }

        function promptForCopy(text) {
            // Final fallback: show the command in a prompt
            const userAgent = navigator.userAgent.toLowerCase();
            const isIOS = /iphone|ipad|ipod/.test(userAgent);

            if (isIOS) {
                // iOS: Use a more user-friendly approach
                alert('Tap and hold the command below to copy it:\\n\\n' + text);
            } else {
                prompt('Copy this command:', text);
            }
        }

        function showMessage(message) {
            // Create a temporary message element
            const messageEl = document.createElement('div');
            messageEl.textContent = message;
            messageEl.style.cssText = 'position: fixed; top: 20px; left: 50%; transform: translateX(-50%); background: #007AFF; color: white; padding: 12px 20px; border-radius: 8px; z-index: 1000; font-size: 14px; box-shadow: 0 2px 10px rgba(0,0,0,0.3);';

            document.body.appendChild(messageEl);

            setTimeout(() => {
                if (document.body.contains(messageEl)) {
                    document.body.removeChild(messageEl);
                }
            }, 2000);
        }

        function copySSHCommand(hostname, port) {
            const command = \`ssh vscode@\${hostname} -p \${port}\`;
            copyToClipboard(command, 'SSH command copied!');
        }

        function copyMoshCommand(hostname, sshPort, moshPort) {
            const command = \`mosh -P \${sshPort} -p \${moshPort} vscode@\${hostname}\`;
            copyToClipboard(command, 'MOSH command copied!');
        }

        // Auto-refresh page
        setTimeout(() => {
            window.location.reload();
        }, ${refreshInterval * 1000});
    </script>
</body>
</html>`;
}

function createServer() {
  const config = loadConfig();
  const hostname = getTailscaleHostname();

  const server = http.createServer((req, res) => {
    log(`${req.method} ${req.url} from ${req.socket.remoteAddress}`);

    if (req.url === '/' || req.url === '/containers') {
      try {
        const containers = getClaudetainerContainers();
        const html = generateDashboardHTML(containers, hostname);

        res.writeHead(200, { 'Content-Type': 'text/html' });
        res.end(html);
      } catch (e) {
        log(`Error generating dashboard: ${e.message}`);
        res.writeHead(500, { 'Content-Type': 'text/plain' });
        res.end('Internal Server Error');
      }
    } else if (req.url === '/api/containers') {
      try {
        const containers = getClaudetainerContainers();
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ containers, hostname }));
      } catch (e) {
        log(`Error fetching containers: ${e.message}`);
        res.writeHead(500, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: e.message }));
      }
    } else {
      res.writeHead(404, { 'Content-Type': 'text/plain' });
      res.end('Not Found');
    }
  });

  server.listen(config.port, config.host, () => {
    log(`Dashboard server started on http://${hostname}:${config.port}`);
    console.log(`\n🎉 Claudetainer Dashboard is running!`);
    console.log(`📱 Access from any device on your Tailscale network:`);
    console.log(`   http://${hostname}:${config.port}`);
    console.log(`\n📋 Management commands:`);
    console.log(`   claudetainer dashboard status  # Check status`);
    console.log(`   claudetainer dashboard stop    # Stop server`);
    console.log(`   claudetainer dashboard logs    # View logs\n`);
  });

  // Save PID for process management
  ensureConfigDir();
  fs.writeFileSync(PID_FILE, process.pid.toString());

  // Graceful shutdown
  process.on('SIGTERM', () => {
    log('Received SIGTERM, shutting down gracefully');
    server.close(() => {
      try {
        fs.unlinkSync(PID_FILE);
      } catch (e) {
        // PID file may not exist
      }
      process.exit(0);
    });
  });

  process.on('SIGINT', () => {
    log('Received SIGINT, shutting down gracefully');
    server.close(() => {
      try {
        fs.unlinkSync(PID_FILE);
      } catch (e) {
        // PID file may not exist
      }
      process.exit(0);
    });
  });

  return server;
}

// CLI interface
if (require.main === module) {
  const args = process.argv.slice(2);

  if (args.includes('--help') || args.includes('-h')) {
    console.log(`
Claudetainer Dashboard Server

Usage: claudetainer-dashboard.js [options]

Options:
  --port <port>    Server port (default: 8888)
  --host <host>    Bind host (default: 0.0.0.0)
  --help, -h       Show this help message

This server provides a mobile-friendly web interface for connecting to
claudetainer containers via SSH and Mosh, with deep links for Blink Shell.
`);
    process.exit(0);
  }

  // Parse command line arguments
  const config = loadConfig();
  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--port' && args[i + 1]) {
      config.port = parseInt(args[i + 1]);
      i++;
    } else if (args[i] === '--host' && args[i + 1]) {
      config.host = args[i + 1];
      i++;
    }
  }

  saveConfig(config);
  createServer();
}

module.exports = { createServer, loadConfig, saveConfig };

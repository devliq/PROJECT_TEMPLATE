# Port Troubleshooting Guide

This guide provides insights into port management within this project, based on investigations and best practices for debugging and managing development environments.

## Automatic Port Loading in VS Code

When opening this project in VS Code, programs and ports are automatically loaded through several mechanisms:

### Scripts and Package Configurations

- **Node.js Services**: The project uses Node.js (evidenced by `package.json` and `src/index.js`). Services may start automatically via npm scripts defined in `package.json`. For example, a development server could be launched on port 4121 (as observed in previous investigations) using commands like `npm run dev` or `npm start`.
- **Python Services**: Python-based components (e.g., `src/main.py`) may be initiated through scripts in `scripts/setup-dev-workspace.sh` or via VS Code's Python extension, potentially using ports for web servers or APIs.
- **Docker and Compose**: The presence of `docker-compose.yml` and `Dockerfile` indicates containerized services that can be auto-started via VS Code's Docker extension or integrated terminals, exposing ports as defined in the compose file.

### VS Code Launch Configurations and Extensions

- **Launch Configurations**: If `.vscode/launch.json` exists (not visible in current files), it may define debug sessions that start services on specific ports.
- **Extensions**: Extensions like "Live Server" or "Python" can automatically launch services. For instance, the Python extension might run a Flask/Django server on a default port.
- **Integrated Terminal**: Scripts like `scripts/setup-dev.sh` or `enter-project.bat` may be configured to run on project open, starting services in the background.

**Key Insight**: Previous investigations showed no active services on ports 3350 or 3408, but Node.js was running on 4121, suggesting selective auto-loading based on active development needs.

## Debugging Port-Related Issues

Use these best practices to troubleshoot port conflicts or failures:

### Tools and Commands

- **Windows**:
  - **netstat**: Run `netstat -ano` in Command Prompt or PowerShell to list active connections and ports. Identify processes using specific ports (e.g., `netstat -ano | findstr :4121`).
  - **Task Manager/Resource Monitor**: Check under "Listening Ports" in Resource Monitor to see which applications are bound to ports.
  - **Browser Dev Tools**: For web services, inspect network tabs in Chrome/Firefox DevTools to verify port accessibility and response times.
- **Linux**:
  - **netstat/lsof**: Use `netstat -tlnp` or `lsof -i :4121` to list processes on ports. Requires root for full details.
  - **ss**: Modern alternative: `ss -tlnp` for socket statistics.
  - **Browser Dev Tools**: Same as Windows; useful for testing API endpoints or web apps.

### Step-by-Step Debugging

1. **Check Port Availability**: Use the above tools to confirm if the expected port is open and listening.
2. **Identify Conflicts**: If a port is in use, note the PID and terminate the conflicting process (e.g., `taskkill /PID <pid>` on Windows or `kill <pid>` on Linux).
3. **Test Connectivity**: Use `telnet localhost <port>` or curl (e.g., `curl http://localhost:4121`) to verify service responsiveness.
4. **Logs and Errors**: Review VS Code's integrated terminal output, application logs (e.g., in `logs/` if present), or extension-specific logs for startup errors.
5. **Restart Services**: If issues persist, restart VS Code or manually run setup scripts like `scripts/setup-dev.sh`.

## Managing Multiple Services to Avoid Conflicts

To prevent port conflicts in multi-service environments:

### Best Practices

- **Port Assignment Strategy**: Assign unique, non-standard ports to each service (e.g., 3000 for frontend, 5000 for backend). Document these in `config/config.json` or environment files.
- **Environment Variables**: Use `.env` files (e.g., `config/.env.example`) to define ports dynamically, allowing easy overrides per environment.
- **Service Discovery**: For complex setups, use tools like Docker Compose to manage inter-service communication without exposing ports externally.
- **Process Managers**: On Windows, use tools like PM2 or NSSM to manage background services. On Linux, systemd or supervisor can handle restarts and port binding.
- **VS Code Workspaces**: Configure multi-root workspaces in VS Code to isolate services, reducing accidental port overlaps.

### Recommendations

- **Windows-Specific**: Use PowerShell scripts (e.g., `Enter-Project.ps1`) to automate service startup and port checks. Avoid running multiple instances of VS Code or terminals simultaneously.
- **Linux Notes**: Leverage `systemctl` for service management (e.g., `systemctl start my-service`). Use `ufw` or `firewalld` to control port access if needed.
- **General**: Regularly audit active ports with scheduled scripts. Implement health checks in services to auto-restart on failures.

For project-specific issues, refer to `docs/environment-setup.md` or run `scripts/setup-dev-workspace.sh` to ensure proper initialization.

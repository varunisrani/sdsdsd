# Proposed Git Integration for Claude Code Container

## Issue Summary

The `/git-sync` command implementation hangs when attempting to execute git operations from within the containerized Claude Code environment. This document outlines the investigation findings and proposes alternative solutions.

## Problem Analysis

### Current Behavior
- Command `/git-sync "message"` displays "🔄 Syncing changes to git..." then hangs indefinitely
- No errors appear in container logs
- Regular Claude Code operations work normally
- Git commands work when executed manually in container

### Root Causes Identified
1. **Claude Code SDK Query Hanging**: Using `query()` function to execute bash commands causes indefinite blocking
2. **WebSocket Context Issues**: Async execution within WebSocket message handlers may conflict with git process spawning
3. **Container Environment**: Docker containerization may affect process execution and stdin/stdout handling
4. **Permission/Working Directory**: Git operations may fail due to container user permissions or working directory context

## Attempted Solutions

### Approach 1: Claude Code SDK Execution
```typescript
const gitResponse = query({
  prompt: `Execute these git commands: ${gitCommands}`,
  options: { canUseTool: allowAll }
});
```
**Result**: Hangs at query execution, never returns

### Approach 2: Direct Node.js Child Process
```typescript
import { exec } from "child_process";
const execAsync = promisify(exec);
await execAsync('git add sync/', { cwd: '/app/project' });
```
**Result**: Hangs at first execAsync call

### Approach 3: GitHub CLI Integration
- Added `github-cli` package to Alpine container
- Attempted `gh` authentication with OAuth tokens
**Result**: Still hangs due to underlying execution issues

## Recommended Alternative Solutions

### Option 1: Manual Git Workflow (Recommended)
**Pros**: Simple, reliable, gives users full control
**Implementation**: Remove git-sync command, document workflow
```bash
# After Claude session, on host machine:
git add sync/
git commit -m "Claude session: analysis and scripts"
git push
```

### Option 2: GitHub API Integration
**Pros**: Bypasses local git entirely, works in cloud deployments
**Implementation**: Use Octokit to create commits via GitHub API
```typescript
const octokit = new Octokit({ auth: githubToken });
await octokit.rest.repos.createOrUpdateFileContents({
  owner, repo, path: 'sync/file.txt',
  message: commitMessage,
  content: Buffer.from(fileContent).toString('base64')
});
```

### Option 3: Host-Side File Watcher
**Pros**: Automatic, non-blocking, runs outside container
**Implementation**: Monitor `./sync/` folder on host, auto-commit changes
```bash
# Using fswatch or inotify
fswatch -o ./sync | xargs -n1 -I{} git add sync/ && git commit -m "Auto-sync"
```

### Option 4: Scheduled Commit Service
**Pros**: Reliable, doesn't block user interactions
**Implementation**: Background process commits sync folder periodically
```bash
# Cron job or systemd timer
*/5 * * * * cd /project && git add sync/ && git commit -m "Scheduled sync $(date)" || true
```

## Technical Implementation Details

### For GitHub API Approach (Option 2)
**Requirements**:
- GitHub App or Personal Access Token with `contents:write` permission
- File content encoding to base64 for API
- Handle file creation vs updates (get SHA for updates)
- Batch multiple file changes into single commit

**Advantages**:
- Works in any cloud environment
- No local git configuration needed
- Can create pull requests instead of direct commits
- Better for team workflows

### For Host Monitoring Approach (Option 3)
**Requirements**:
- File system watcher (`fswatch`, `inotifywait`, etc.)
- Host git configuration and authentication
- Debouncing to avoid excessive commits

**Advantages**:
- Immediate sync as files are created
- No container modifications needed
- Uses existing host git setup

## Implementation Priority

1. **Immediate**: Document manual workflow clearly in README
2. **Short-term**: Implement GitHub API approach for cloud deployments
3. **Optional**: Add host file watcher for development workflows

## Files Affected During Investigation

- `server.ts`: WebSocket handlers, git execution logic
- `Dockerfile`: Added github-cli package (can be removed)
- `package.json`: Added @octokit/rest (keep for API approach)
- Various shell scripts with volume mount updates

## Environment Details

- **Container**: Node.js 22 Alpine with Claude Code SDK v1.0.120
- **Git**: Version 2.49.1 in container
- **Communication**: WebSocket between browser and container
- **Working**: File operations, Claude Code queries, manual git commands
- **Failing**: Automated git execution via any method

## Conclusion

The container environment appears to have fundamental compatibility issues with spawning git processes from Node.js. The most practical solution is documenting the manual workflow while implementing GitHub API integration for automated scenarios.

---

*Document created: $(date)*
*Status: Investigation complete, manual workflow recommended*
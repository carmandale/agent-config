# Railway Troubleshooting Reference

Detailed diagnostic procedures for Railway deployment issues.

## Diagnostic Flowchart

```
Deployment Issue Reported
         │
         ▼
┌─────────────────────────┐
│ railway status --json   │
│ Check deployment status │
└───────────┬─────────────┘
            │
    ┌───────┴───────┐
    │               │
    ▼               ▼
 FAILED          SUCCESS but not working
    │               │
    ▼               ▼
┌─────────┐    ┌──────────────┐
│ Build   │    │ Runtime      │
│ phase?  │    │ issue?       │
└────┬────┘    └──────┬───────┘
     │                │
     ▼                ▼
logs --build     logs --deployment
     │                │
     │                ▼
     │           logs (live)
     │                │
     ▼                ▼
Fix build       Fix runtime
config/deps     config/code
```

## Deployment Status Values

From `railway status --json`:

| Status | Meaning | Next Steps |
|--------|---------|------------|
| `SUCCESS` | Deployed and running | Check logs if misbehaving |
| `FAILED` | Deployment failed | Check `--build` then `--deployment` logs |
| `BUILDING` | Build in progress | Wait or check build logs |
| `DEPLOYING` | Deploying to runtime | Wait or check deployment logs |
| `CRASHED` | Runtime crashed | Check logs, likely startup error |
| `REMOVED` | Deployment removed | Check if intentional |

## Build Phase Failures

### Symptoms
- `railway logs --build` shows errors
- Status shows FAILED early in process

### Common Causes

**1. Missing Dependencies**
```
Error: Cannot find module 'express'
```
Fix: Ensure all dependencies in package.json/requirements.txt

**2. Dockerfile Errors**
```
ERROR: failed to solve: dockerfile parse error
```
Fix: Validate Dockerfile syntax, check base image exists

**3. Build Command Failures**
```
npm ERR! code ELIFECYCLE
```
Fix: Check package.json scripts, build locally first

**4. Memory/Resource Limits**
```
Killed
SIGKILL
```
Fix: Optimize build, use multi-stage Dockerfile

### Diagnostic Commands
```bash
# View full build output
railway logs --build

# Check build configuration
railway status --json | jq '.services.edges[].node.serviceInstances.edges[].node.latestDeployment.meta.serviceManifest.build'
```

## Runtime Phase Failures

### Symptoms
- Build succeeds but service crashes
- `railway logs --deployment` shows errors
- Service not responding to requests

### Common Causes

**1. Missing Environment Variables**
```
Error: REQUIRED_VAR is not defined
```
Fix: 
```bash
railway variables --set "REQUIRED_VAR=value"
```

**2. Port Binding Issues**
```
Error: listen EADDRINUSE
Error: bind: address already in use
```
Fix: Use `process.env.PORT` or `$PORT` - Railway provides this

**3. Database Connection Failures**
```
Error: ECONNREFUSED
Error: connection refused
```
Fix:
```bash
# Verify DATABASE_URL is set
railway variables | grep DATABASE

# Test connection
railway connect postgres
```

**4. Startup Timeout**
Service must bind to PORT within ~5 minutes.

Fix: Reduce startup time, defer heavy initialization

### Diagnostic Commands
```bash
# Check runtime startup
railway logs --deployment

# Stream live logs
railway logs

# SSH in to inspect
railway ssh

# Check what start command is configured
railway status --json | jq '.services.edges[].node.serviceInstances.edges[].node.startCommand'
```

## Network/Domain Issues

### Symptoms
- Service running but not accessible
- DNS errors
- SSL certificate issues

### Diagnostic Commands
```bash
# Check domain configuration
railway status --json | jq '.services.edges[].node.serviceInstances.edges[].node.domains'

# Check public domain
railway status --json | jq -r '.services.edges[].node.serviceInstances.edges[].node.domains.serviceDomains[].domain'

# Generate domain if missing
railway domain
```

### Common Causes

**1. No Domain Configured**
```bash
railway domain  # Generate one
```

**2. Wrong Port in Domain Config**
```bash
railway domain -p 3000  # Specify correct port
```

**3. Custom Domain DNS Not Propagated**
Wait for DNS propagation, verify CNAME records

## Volume Issues

### Diagnostic Commands
```bash
# Check volume configuration
railway status --json | jq '.volumes.edges[].node.volumeInstances.edges[].node'

# Check mount path and size
railway status --json | jq '.volumes.edges[].node.volumeInstances.edges[].node | {mountPath, currentSizeMB, sizeMB}'
```

### Common Causes

**1. Volume Not Mounted**
Check railway.toml or service settings for volume configuration

**2. Disk Full**
```bash
# Check usage
railway status --json | jq '.volumes.edges[].node.volumeInstances.edges[].node | {currentSizeMB, sizeMB}'
```

**3. Permission Issues**
SSH in and check file permissions on mounted path

## Environment-Specific Issues

### Symptoms
- Works in staging, fails in production
- Different behavior between environments

### Diagnostic Commands
```bash
# Switch environments
railway environment staging
railway variables --json > staging-vars.json

railway environment production  
railway variables --json > prod-vars.json

# Compare
diff staging-vars.json prod-vars.json
```

## Recovery Procedures

### Rollback Deployment
```bash
railway down  # Removes most recent deployment
```

### Force Redeploy
```bash
railway redeploy -y
```

### Reset Service (Careful!)
1. Note current variables: `railway variables --json > backup.json`
2. Remove and recreate service via dashboard
3. Restore variables

### Emergency SSH Access
```bash
railway ssh
# Now you can:
# - Check process status
# - View log files
# - Test network connectivity
# - Inspect filesystem
```

## Useful jq Recipes

```bash
# Get just the deployment status
railway status --json | jq -r '.services.edges[0].node.serviceInstances.edges[0].node.latestDeployment.status'

# Get start command
railway status --json | jq -r '.services.edges[0].node.serviceInstances.edges[0].node.startCommand'

# Get all environment names
railway status --json | jq -r '.environments.edges[].node.name'

# Get volume usage percentage
railway status --json | jq '.volumes.edges[].node.volumeInstances.edges[].node | "\(.currentSizeMB)/\(.sizeMB) MB (\(.currentSizeMB/.sizeMB*100 | floor)%)"'

# Pretty print latest deployment info
railway status --json | jq '.services.edges[].node.serviceInstances.edges[].node.latestDeployment | {status, canRedeploy, id}'
```

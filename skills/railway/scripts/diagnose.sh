#!/bin/bash
# Railway Diagnostic Script
# Quick health check for Railway deployments

set -e

echo "🚂 Railway Diagnostic Report"
echo "============================"
echo ""

# Check if railway CLI is available
if ! command -v railway &> /dev/null; then
    echo "❌ Railway CLI not found. Install with: brew install railway"
    exit 1
fi

# Check if linked to a project
if ! railway status &> /dev/null; then
    echo "❌ Not linked to a Railway project. Run: railway link"
    exit 1
fi

echo "📍 Project Context:"
railway status
echo ""

# Get JSON status for detailed parsing
STATUS_JSON=$(railway status --json 2>/dev/null)

if [ -z "$STATUS_JSON" ]; then
    echo "❌ Could not fetch project status"
    exit 1
fi

# Extract key info
echo "📊 Deployment Status:"
echo "$STATUS_JSON" | jq -r '
    .services.edges[]?.node as $svc |
    $svc.serviceInstances.edges[]?.node as $inst |
    "  Service: \($svc.name // "unknown")\n  Status: \($inst.latestDeployment.status // "unknown")\n  Can Redeploy: \($inst.latestDeployment.canRedeploy // "unknown")"
' 2>/dev/null || echo "  Unable to parse deployment status"
echo ""

# Check for FAILED status
DEPLOY_STATUS=$(echo "$STATUS_JSON" | jq -r '.services.edges[0]?.node.serviceInstances.edges[0]?.node.latestDeployment.status // "unknown"' 2>/dev/null)

if [ "$DEPLOY_STATUS" == "FAILED" ]; then
    echo "⚠️  Deployment FAILED - Checking logs..."
    echo ""
    echo "📋 Build Logs (last 20 lines):"
    railway logs --build 2>&1 | tail -20 || echo "  No build logs available"
    echo ""
    echo "📋 Deployment Logs (last 20 lines):"
    railway logs --deployment 2>&1 | tail -20 || echo "  No deployment logs available"
elif [ "$DEPLOY_STATUS" == "SUCCESS" ]; then
    echo "✅ Deployment successful"
    echo ""
    echo "🌐 Domains:"
    echo "$STATUS_JSON" | jq -r '
        .services.edges[]?.node.serviceInstances.edges[]?.node.domains as $d |
        ($d.serviceDomains[]?.domain // empty) as $sd |
        "  Railway: https://\($sd)"
    ' 2>/dev/null || echo "  No domains configured"
    echo ""
    echo "📋 Recent Logs (last 10 lines):"
    timeout 5 railway logs 2>&1 | tail -10 || echo "  No recent logs or timeout"
else
    echo "⏳ Deployment status: $DEPLOY_STATUS"
fi

echo ""
echo "💾 Volumes:"
echo "$STATUS_JSON" | jq -r '
    .volumes.edges[]?.node.volumeInstances.edges[]?.node as $v |
    "  \($v.volume.name // "unknown"): \($v.currentSizeMB // 0)MB / \($v.sizeMB // 0)MB at \($v.mountPath // "unknown")"
' 2>/dev/null || echo "  No volumes configured"

echo ""
echo "🔧 Start Command:"
echo "$STATUS_JSON" | jq -r '.services.edges[0]?.node.serviceInstances.edges[0]?.node.startCommand // "Not configured"' 2>/dev/null

echo ""
echo "============================"
echo "🔍 For more details:"
echo "  railway logs --build      # Build phase logs"
echo "  railway logs --deployment # Startup logs"
echo "  railway logs              # Application logs"
echo "  railway ssh               # Shell access"
echo "  railway open              # Dashboard"

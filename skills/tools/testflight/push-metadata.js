#!/usr/bin/env node

/**
 * Push App Store Metadata via App Store Connect API
 * 
 * Usage: node push-metadata.js <app-id> <metadata-file> [--screenshots <dir>]
 */

const crypto = require('crypto');
const https = require('https');
const fs = require('fs');
const path = require('path');

// Load credentials
const credentialsPath = path.join(process.env.HOME, '.config/testflight/credentials.env');
const credentials = fs.readFileSync(credentialsPath, 'utf8');
const keyId = credentials.match(/TESTFLIGHT_API_KEY_ID="([^"]+)"/)?.[1];
const issuerId = credentials.match(/TESTFLIGHT_ISSUER_ID="([^"]+)"/)?.[1];
const keyPath = path.join(process.env.HOME, `.appstoreconnect/private_keys/AuthKey_${keyId}.p8`);
const privateKey = fs.readFileSync(keyPath, 'utf8');

function base64url(data) {
  return Buffer.from(data).toString('base64').replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');
}

function makeJWT() {
  const header = { alg: 'ES256', kid: keyId, typ: 'JWT' };
  const now = Math.floor(Date.now() / 1000);
  const payload = { iss: issuerId, iat: now, exp: now + 1200, aud: 'appstoreconnect-v1' };
  const headerEnc = base64url(JSON.stringify(header));
  const payloadEnc = base64url(JSON.stringify(payload));
  const msg = `${headerEnc}.${payloadEnc}`;
  const sign = crypto.createSign('SHA256');
  sign.update(msg);
  const sig = sign.sign({ key: privateKey, dsaEncoding: 'ieee-p1363' });
  return `${msg}.${sig.toString('base64').replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_')}`;
}

function apiRequest(method, endpoint, body = null) {
  return new Promise((resolve, reject) => {
    const jwt = makeJWT();
    const options = {
      hostname: 'api.appstoreconnect.apple.com',
      path: endpoint,
      method: method,
      headers: {
        'Authorization': `Bearer ${jwt}`,
        'Content-Type': 'application/json'
      }
    };
    
    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          const json = data ? JSON.parse(data) : {};
          if (res.statusCode >= 400) {
            console.error(`API Error ${res.statusCode}:`, JSON.stringify(json, null, 2));
            reject(new Error(`API Error ${res.statusCode}`));
          } else {
            resolve(json);
          }
        } catch (e) {
          resolve(data);
        }
      });
    });
    
    req.on('error', reject);
    if (body) req.write(JSON.stringify(body));
    req.end();
  });
}

function parseMetadata(filePath) {
  const content = fs.readFileSync(filePath, 'utf8');
  const metadata = {};
  
  // Extract promotional text
  const promoMatch = content.match(/### Promotional Text[^`]*```\n([\s\S]*?)```/);
  if (promoMatch) metadata.promotionalText = promoMatch[1].trim();
  
  // Extract description
  const descMatch = content.match(/### Description[^`]*```\n([\s\S]*?)```/);
  if (descMatch) metadata.description = descMatch[1].trim();
  
  // Extract keywords
  const keywordsMatch = content.match(/## Keywords[^`]*```\n([\s\S]*?)```/);
  if (keywordsMatch) metadata.keywords = keywordsMatch[1].trim();
  
  // Extract what's new
  const whatsNewMatch = content.match(/## What's New[^`]*```\n([\s\S]*?)```/);
  if (whatsNewMatch) metadata.whatsNew = whatsNewMatch[1].trim();
  
  // Extract URLs
  const supportUrlMatch = content.match(/\*\*Support URL\*\*[^|]*\|\s*([^\s|]+)/);
  if (supportUrlMatch) metadata.supportUrl = supportUrlMatch[1].trim();
  
  const marketingUrlMatch = content.match(/\*\*Marketing URL\*\*[^|]*\|\s*([^\s|]+)/);
  if (marketingUrlMatch) metadata.marketingUrl = marketingUrlMatch[1].trim();
  
  return metadata;
}

async function getAppStoreVersion(appId) {
  const response = await apiRequest('GET', `/v1/apps/${appId}/appStoreVersions?filter[appStoreState]=PREPARE_FOR_SUBMISSION,READY_FOR_SALE&limit=1`);
  return response.data?.[0];
}

async function getLocalization(versionId) {
  const response = await apiRequest('GET', `/v1/appStoreVersions/${versionId}/appStoreVersionLocalizations`);
  return response.data?.[0];
}

async function updateLocalization(localizationId, metadata, skipWhatsNew = false) {
  const attributes = {};
  
  if (metadata.description) attributes.description = metadata.description;
  if (metadata.keywords) attributes.keywords = metadata.keywords;
  if (metadata.whatsNew && !skipWhatsNew) attributes.whatsNew = metadata.whatsNew;
  if (metadata.promotionalText) attributes.promotionalText = metadata.promotionalText;
  if (metadata.supportUrl) attributes.supportUrl = metadata.supportUrl;
  if (metadata.marketingUrl) attributes.marketingUrl = metadata.marketingUrl;
  
  const body = {
    data: {
      type: 'appStoreVersionLocalizations',
      id: localizationId,
      attributes: attributes
    }
  };
  
  return apiRequest('PATCH', `/v1/appStoreVersionLocalizations/${localizationId}`, body);
}

async function getAppInfo(appId) {
  const response = await apiRequest('GET', `/v1/apps/${appId}/appInfos`);
  return response.data?.[0];
}

async function getAppInfoLocalization(appInfoId) {
  const response = await apiRequest('GET', `/v1/appInfos/${appInfoId}/appInfoLocalizations`);
  return response.data?.[0];
}

async function main() {
  const args = process.argv.slice(2);
  if (args.length < 2) {
    console.log('Usage: node push-metadata.js <app-id> <metadata-file> [--screenshots <dir>]');
    console.log('');
    console.log('App IDs:');
    console.log('  Pfizer: 6737364780');
    console.log('  GMP: 6757438008');
    console.log('  Media Server: 6757471795');
    console.log('  Orchestrator: 6754814714');
    process.exit(1);
  }
  
  const appId = args[0];
  const metadataFile = args[1];
  const screenshotsDir = args.includes('--screenshots') ? args[args.indexOf('--screenshots') + 1] : null;
  
  console.log(`\n📱 Pushing metadata for app ${appId}`);
  console.log(`📄 Metadata file: ${metadataFile}`);
  if (screenshotsDir) console.log(`🖼️  Screenshots: ${screenshotsDir}`);
  console.log('');
  
  // Parse metadata
  const metadata = parseMetadata(metadataFile);
  console.log('Parsed metadata:');
  console.log(`  - Description: ${metadata.description?.length || 0} chars`);
  console.log(`  - Keywords: ${metadata.keywords?.length || 0} chars`);
  console.log(`  - What's New: ${metadata.whatsNew?.length || 0} chars`);
  console.log(`  - Promotional Text: ${metadata.promotionalText?.length || 0} chars`);
  console.log(`  - Support URL: ${metadata.supportUrl || 'not set'}`);
  console.log(`  - Marketing URL: ${metadata.marketingUrl || 'not set'}`);
  console.log('');
  
  // Get app store version
  console.log('🔍 Getting App Store version...');
  const version = await getAppStoreVersion(appId);
  if (!version) {
    console.error('❌ No App Store version found in PREPARE_FOR_SUBMISSION state');
    process.exit(1);
  }
  console.log(`   Version: ${version.attributes.versionString} (${version.attributes.appStoreState})`);
  
  // Get localization
  console.log('🔍 Getting localization...');
  const localization = await getLocalization(version.id);
  if (!localization) {
    console.error('❌ No localization found');
    process.exit(1);
  }
  console.log(`   Locale: ${localization.attributes.locale}`);
  
  // Update localization
  console.log('📝 Updating metadata...');
  await updateLocalization(localization.id, metadata);
  console.log('   ✅ Metadata updated successfully');
  
  console.log('\n✅ Done!');
}

main().catch(err => {
  console.error('Error:', err.message);
  process.exit(1);
});

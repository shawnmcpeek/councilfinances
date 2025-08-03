# Deployment Guide - Knights Management Web App

This guide explains how to deploy the Knights Management Flutter web app to Netlify.

## Prerequisites

1. **Flutter SDK** installed and configured
2. **Node.js** installed (for Netlify CLI)
3. **Netlify CLI** installed globally: `npm install -g netlify-cli`
4. **Netlify account** with the `knightsmanagement` project created

## Quick Deployment (Recommended)

### Step 1: Build the Flutter Web App
```bash
flutter build web --base-href /
```

### Step 2: Deploy to Netlify
```bash
netlify deploy --dir=build/web --prod
```

That's it! Your app will be live at: **https://knightsmanagement.netlify.app**

## Initial Setup (One-time only)

If this is your first time deploying or you need to link to the project:

### Step 1: Link to Netlify Project
```bash
netlify link --id bd025aad-8b39-4301-8609-47777db2d72c
```

### Step 2: Build and Deploy
```bash
flutter build web --base-href /
netlify deploy --dir=build/web --prod
```

## Configuration Files

The following files are required for proper deployment:

### `netlify.toml` (Project Root)
```toml
[build]
  publish = "build/web"
  command = "flutter build web"

[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200

[build.environment]
  FLUTTER_VERSION = "3.19.0"
```

### `build/web/_redirects`
```
/*    /index.html   200
```

### `build/web/_headers`
```
/*
  X-Frame-Options: DENY
  X-XSS-Protection: 1; mode=block
  X-Content-Type-Options: nosniff
  Referrer-Policy: strict-origin-when-cross-origin

/*.js
  Cache-Control: public, max-age=31536000, immutable

/*.css
  Cache-Control: public, max-age=31536000, immutable

/*.wasm
  Content-Type: application/wasm
```

## Troubleshooting

### 404 Errors
- Ensure you're using `netlify deploy` instead of manual upload
- Verify the `_redirects` file is in the `build/web` directory
- Check that all configuration files are present

### Build Errors
- Run `flutter clean` before building
- Ensure all dependencies are up to date: `flutter pub get`
- Check for any linting errors: `flutter analyze`

### Deployment Issues
- Verify you're linked to the correct project: `netlify status`
- Check deployment logs in the Netlify dashboard
- Ensure you have the correct project ID: `bd025aad-8b39-4301-8609-47777db2d72c`

## Alternative: GitHub Integration

For automatic deployments on every push:

1. Connect your GitHub repository to Netlify
2. Set build command: `flutter build web`
3. Set publish directory: `build/web`
4. Push to GitHub to trigger automatic deployment

## Useful Commands

```bash
# Check Netlify status
netlify status

# List all sites
netlify sites:list

# View deployment logs
netlify logs

# Create preview deployment (without --prod)
netlify deploy --dir=build/web
```

## Project Details

- **Project Name**: knightsmanagement
- **Project ID**: bd025aad-8b39-4301-8609-47777db2d72c
- **Live URL**: https://knightsmanagement.netlify.app
- **Build Directory**: `build/web`
- **Framework**: Flutter Web 
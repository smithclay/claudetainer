# Homebrew Automation Setup Guide

This guide explains how to set up automated Homebrew formula updates for claudetainer.

## Prerequisites

### 1. Create Homebrew Tap Repository

Create a new repository: `https://github.com/smithclay/homebrew-tap`

```bash
# Clone and set up the tap
git clone https://github.com/smithclay/homebrew-tap.git
cd homebrew-tap

# Create Formula directory and add claudetainer formula
mkdir -p Formula
cp /path/to/claudetainer/Formula/claudetainer.rb Formula/

# Commit and push
git add Formula/claudetainer.rb
git commit -m "Add claudetainer formula"
git push origin main
```

### 2. Create Personal Access Token

1. Go to GitHub Settings → Developer settings → Personal access tokens
2. Create a new token with these scopes:
   - `repo` (Full control of private repositories)
   - `workflow` (Update GitHub Action workflows)
3. Name it something like "Homebrew Formula Updates"
4. Copy the token (you won't see it again!)

### 3. Add Token to Repository Secrets

In your `smithclay/claudetainer` repository:

1. Go to Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Name: `HOMEBREW_TAP_TOKEN`
4. Value: [paste your personal access token]
5. Click "Add secret"

## How It Works

### Automatic Updates

When you create a new release:

1. **GitHub Action Triggers** - The `update-homebrew.yaml` workflow runs
2. **Formula Update** - Uses `dawidd6/action-homebrew-bump-formula@v3` to:
   - Download the new release tarball
   - Calculate SHA256 hash
   - Update version and URL in formula
   - Create a pull request in your tap repository
3. **Testing** - Optional macOS test to verify the formula works
4. **Merge** - Review and merge the PR to publish the update

### Manual Updates (if needed)

```bash
# Calculate SHA256 for a specific version
curl -L https://github.com/smithclay/claudetainer/archive/v0.1.0.tar.gz | shasum -a 256

# Update formula manually
# Edit Formula/claudetainer.rb with new version and SHA256
# Commit and push
```

## Release Process

### Creating a Release

```bash
# 1. Update version in bin/claudetainer
# 2. Update version in Formula/claudetainer.rb (if not using automation)
# 3. Commit changes
git add .
git commit -m "Bump version to v0.2.0"
git push

# 4. Create and push tag
git tag v0.2.0
git push origin v0.2.0

# 5. Create GitHub release (this triggers the Homebrew update)
gh release create v0.2.0 --title "v0.2.0" --notes "Release notes here"
```

### Testing the Update

```bash
# Add your tap (users only need to do this once)
brew tap smithclay/tap

# Install claudetainer
brew install claudetainer

# Verify installation
claudetainer --version

# Test functionality
claudetainer doctor
```

## Troubleshooting

### Action Fails: "Permission denied"
- Verify `HOMEBREW_TAP_TOKEN` has correct scopes
- Ensure token hasn't expired

### Formula Syntax Error
- Test formula locally: `brew install --build-from-source Formula/claudetainer.rb`
- Check Homebrew formula documentation

### SHA256 Mismatch
- Recalculate: `curl -L [tarball_url] | shasum -a 256`
- Ensure URL points to correct release

### Users Can't Install
- Verify tap repository is public
- Check formula passes `brew audit --strict`

## Advanced Configuration

### Custom Release Notes in Formula

The action automatically includes release notes in the commit message. To customize:

```yaml
message: |
  claudetainer {{version}}

  🚀 New release: {{version}}
  📦 Updated from {{old_version}}
  🔗 Release: https://github.com/smithclay/claudetainer/releases/tag/{{version}}
```

### Test Matrix

Add multiple macOS versions to test compatibility:

```yaml
test-formula:
  strategy:
    matrix:
      os: [macos-12, macos-13, macos-14]
  runs-on: ${{ matrix.os }}
```

This ensures your formula works across different macOS versions.

## References

- [Homebrew Formula Cookbook](https://docs.brew.sh/Formula-Cookbook)
- [action-homebrew-bump-formula](https://github.com/dawidd6/action-homebrew-bump-formula)
- [Homebrew Tap Documentation](https://docs.brew.sh/How-to-Create-and-Maintain-a-Tap)

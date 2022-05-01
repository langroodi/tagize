# tagize
![CI workflow](https://github.com/langroodi/tagize/actions/workflows/docker-image.yml/badge.svg)

This is a GitHub Action to automatically add/adjust Git tag aliases based on a semantic versioning schema.

## Docker Image Dependecies
- Bash: > 4.0
- Git: > 2.0
- OpenSSH: > 7.0

## Setup
- Call `action/checkoutv3` in the workflow to clone the repository;
- Add following step to your respository workflow script:
```yaml
uses: langroodi/tagize@[version/tag/commit hash (i.e., v1)]
```

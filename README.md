# tagize
![CI workflow](https://github.com/langroodi/tagize/actions/workflows/docker-image.yml/badge.svg)

This is a GitHub Action to automatically add/adjust Git tag aliases based on a semantic versioning schema.

## Docker Image Dependecies
- Bash: > 4.0
- Git: > 2.0
- OpenSSH: > 7.0

## Setup
- Give the GitHub Actions the write permission to the repo using [this tutorial](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-github-actions-settings-for-a-repository#configuring-the-default-github_token-permissions);
- Add/merge following YAML to your workflow:

```yaml
# This is a basic workflow to help you get started with Actions

name: CI

# Controls when the workflow will run
on:
  # Triggers on (pre-)release
  release:
    types: [published]

# A workflow run is made up of one or more jobs that can run sequentially or in parallel
jobs:
  # This workflow contains a single job called "build"
  build:
    # The type of runner that the job will run on
    runs-on: ubuntu-latest

    # Steps represent a sequence of tasks that will be executed as part of the job
    steps:
      # Checks-out your repository under $GITHUB_WORKSPACE, so your job can access it
      - uses: actions/checkout@v3

      # Execute 'tagize' action
      - uses: langroodi/tagize@v1
```

#!/usr/bin/env bash

owner='microsoft'
repo='vscode'
archive="vscode-server-linux-x64.tar.gz"

get_vscode_release() {
      tag=$(curl --silent "https://api.github.com/repos/${1}/releases/latest" | jq -r '.tag_name')
      tag_data=$(curl --silent "https://api.github.com/repos/${1}/git/ref/tags/${tag}")
      sha=$(echo "${tag_data}" | jq -r '.object.sha')
      sha_type=$(echo "${tag_data}" | jq -r '.object.type')

      if [ "${sha_type}" != "commit" ]; then
            combo_sha=$(curl -s "https://api.github.com/repos/${1}/git/tags/${sha}" | jq -r '.object.sha')
            sha=$(echo "${combo_sha}" | sed -E "s/${sha}//" | xargs)
      fi

      printf "${sha}"
}

commit_sha=$(get_vscode_release "${owner}/${repo}")

echo "will attempt to download VS Code Server version = '${commit_sha}'"

# Download VS Code Server tarball to tmp directory.
curl -L "https://update.code.visualstudio.com/commit:${commit_sha}/server-linux-x64/stable" -o "/tmp/${archive}"

# Make the parent directory where the server should live.
# NOTE: Ensure VS Code will have read/write access; namely the user running VScode or container user.
mkdir -vp ~/.vscode-server/bin/"${commit_sha}"

# Extract the tarball to the right location.
tar --no-same-owner -xzv --strip-components=1 -C ~/.vscode-server/bin/"${commit_sha}" -f "/tmp/${archive}"

export PATH="$PATH:/home/godev/.vscode-server/bin/${commit_sha}/bin"
code-server --install-extension golang.go 
code-server --install-extension GitHub.vscode-pull-request-github 
code-server --install-extension bierner.markdown-preview-github-styles
code-server --install-extension ms-azuretools.vscode-docker
code-server --install-extension github.vscode-github-actions

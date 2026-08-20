# Asymmetric local vs Cloud on-disk layout

Local: symlink repo → `~/.cursor/plugins/local`. Cloud: sync pack into VM `~/.cursor/skills/cursor-cloud-home/` (pack-owned subtree; user-skills roots recurse). Same git SSOT; different discovery paths because Cloud reliably loads user skills dirs and Team Marketplace is out of scope.

Never `rm -rf` the entire VM `~/.cursor/skills`. Keep clone credentials out of the remote URL. Missing token fails the Build.

Rejected: requiring Cloud to load `plugins/local` without verification; full-tree wipe on each install.

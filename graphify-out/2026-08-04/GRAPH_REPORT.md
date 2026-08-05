# Graph Report - cursor-cloud-home  (2026-08-04)

## Corpus Check
- 586 files · ~1,389,889 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 4 nodes · 5 edges · 1 communities
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `539d0dc2`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- install-on-cloud.sh

## God Nodes (most connected - your core abstractions)
1. `install-on-cloud.sh script` - 3 edges
2. `clone_https_token()` - 2 edges
3. `clone_deploy_key()` - 2 edges

## Surprising Connections (you probably didn't know these)
- None detected - all connections are within the same source files.

## Import Cycles
- None detected.

## Communities (1 total, 0 thin omitted)

### Community 0 - "install-on-cloud.sh"
Cohesion: 0.83
Nodes (3): clone_deploy_key(), clone_https_token(), install-on-cloud.sh script

## Suggested Questions
_Not enough signal to generate questions. This usually means the corpus has no AMBIGUOUS edges, no bridge nodes, no INFERRED relationships, and all communities are tightly cohesive. Add more files or run with --mode deep to extract richer edges._
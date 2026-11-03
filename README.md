# fd-8066-freeze-snapshots

Minimal reproducer: `wave.freeze = true` + Fusion Snapshots + an image with a multi-element
ENTRYPOINT (every Seqera Containers / pixi image: `["/bin/bash","/shell-hook.sh"]`).

Freeze writes `WAVE_ENTRY_CHAIN` as a space-joined string (`/bin/bash /shell-hook.sh`). Affected
Fusion versions pass that to `fusion-snapshot` as a single argument, so the task dies before
`.command.run` with:

```
Error (exec.c:135): execvp failed [errno_str=No such file or directory, errno=2]
```

Tracking: seqeralabs/wave#1245 (Wave emits JSON from freeze), COMP-3034 (Fusion split-before-wrap mitigation).

## Runs

Both use `launch/pre-run.sh` (pins Nextflow 26.04.7) and an AWS Batch compute environment with Wave + Fusion.
Edit the ECR repository in `launch/common.config` for your account.

| Launch config | Fusion | Expected |
|---|---|---|
| `launch/baseline.config` | Nextflow default with snapshots (`v2.5-snap_amd64.json`, Fusion 2.5.15) | `execvp failed` |
| `launch/devfix.config` | Fusion PR #1916 build (`2.5.16-fceb0fb`), snapshot manifest | task runs |

`devfix.config` must point at the PR's `fusion-snap_amd64.json`. Setting `fusion.containerConfigUrl`
replaces Nextflow's snapshot-manifest choice, so the plain `fusion-amd64.json` runs without
`fusion-snapshot` and passes whether or not the fix works.

A passing task prints `WAVE_ENTRY_CHAIN`, `FUSION_SNAPSHOT_ENABLED`, a fingerprint of `/usr/bin/fusion`,
and its process ancestry, which should end at `fusion-snapshot -- /bin/bash /shell-hook.sh ...`.

// FD-8066: wave.freeze + Fusion Snapshots + multi-element ENTRYPOINT (pixi image).
// Broken Fusion: task dies before this script runs, with
//   Error (exec.c:135): execvp failed [errno_str=No such file or directory, errno=2]
// Fixed Fusion: script runs, and the ancestry shows fusion-snapshot wrapping /shell-hook.sh.

process PROBE {
    container 'community.wave.seqera.io/library/python:3.14.5--dc8358b3c5eeb927'

    output:
    stdout

    script:
    """
    echo "WAVE_ENTRY_CHAIN=[\${WAVE_ENTRY_CHAIN:-unset}]"
    echo "FUSION_SNAPSHOT_ENABLED=\${FUSION_SNAPSHOT_ENABLED:-unset}"
    echo "fusion sha256: \$(sha256sum /usr/bin/fusion | cut -c1-16)  (pr-1916 2.5.16-fceb0fb = 52f253e9d2f3c890, 2.5.15 = 74834459954be05e)"
    ls -l /usr/bin/fusion-snapshot 2>&1
    python --version
    echo "process ancestry (fusion-snapshot clones a new PID namespace, so the walk stops at its pid 1):"
    pid=\$\$
    while [ "\$pid" -gt 1 ]; do
        printf '  %s: ' "\$pid"; tr '\\0' ' ' < /proc/\$pid/cmdline; echo
        pid=\$(awk '/^PPid:/{print \$2}' /proc/\$pid/status)
    done
    printf '  1: '; tr '\\0' ' ' < /proc/1/cmdline; echo
    """
}

workflow {
    PROBE() | view
}

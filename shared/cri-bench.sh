#!/bin/bash
# set -e -o pipefail
REPETITIONS=1000
SLEEP_TIME=120s
RUNTIMES=("crun" "runc" "runsc" "youki" "io.containerd.kata.v2")
# kata-manager -S fc
# service amazon-ssm-agent stop

# CRI_EXTRA_ARGS="--memory 4mb"

# Make sure tools are installed
apt-get install -qq -y bc jq curl time lsb-release >/dev/null

# Tool setup
if ! command -v nerdctl >/dev/null 2>&1; then
    echo "Installing nerdctl!"
    if [ "$(uname -m)" = "x86_64" ]; then
        ARCH=amd64
    elif [ "$(uname -m)" = "aarch64" ]; then
        ARCH=arm64
    fi
    NERDCTL_DEFAULT_VERSION=$(curl -sL https://api.github.com/repos/containerd/nerdctl/releases/latest | jq -r .name)
    NERDCTL_VERSION="${NERDCTL_VERSION-$NERDCTL_DEFAULT_VERSION}"
    if echo "${NERDCTL_VERSION}" | grep -q "v"; then
        NERDCTL_VERSION="${NERDCTL_VERSION:1}"
    fi
    curl -sL --output /tmp/nerdctl.tar.gz "https://github.com/containerd/nerdctl/releases/download/v${NERDCTL_VERSION}/nerdctl-${NERDCTL_VERSION}-linux-${ARCH-amd64}.tar.gz"
    tar -xzf /tmp/nerdctl.tar.gz -C /usr/local/bin/ --exclude={containerd-rootless-setuptool.sh,containerd-rootless.sh}
    nerdctl --version
fi
nerdctl pull --quiet busybox >/dev/null
# ctr i pull docker.io/library/busybox:latest >/dev/null
# ctr run $CRI_EXTRA_ARGS --rm --runc-binary crun --runtime io.containerd.runc.v2 docker.io/library/busybox:latest true

echo -e "System info:\n$(uname -a)\n$(lsb_release -a)"
echo "Errors:" >error.log
echo "Will run ${RUNTIMES[*]} for $REPETITIONS times"
echo "-----------------------------------"
for rt in "${RUNTIMES[@]}"; do
    cmd="nerdctl run $CRI_EXTRA_ARGS --network=none --rm --runtime $rt busybox true"
    echo "Running: $cmd"
    bash -c "${rt} --version"
    total=0
    min=999999999
    max=0
    errors=0
    SECONDS=0
    bash -c "${cmd}" 2 >/dev/null >&1
    for ((i = 1; i <= REPETITIONS; i++)); do
        result=$(/usr/bin/time -f "%e" -o /dev/stdout -a $cmd 2>&1)
        if [ "${#result}" -gt 5 ]; then
            echo "${result}" >>error.log
            errors=$(echo $errors+1 | bc)
        else
            total=$(echo $total+$result | bc)
            if (($(echo "$result < $min" | bc -l))); then
                min=$result
            fi
            if (($(echo "$result > $max" | bc -l))); then
                max=$result
            fi
        fi
        # sleep 1s
    done
    echo "The benchmark for ${rt} took $SECONDS seconds"
    mean=$(echo "scale=2; $total / $REPETITIONS" | bc)

    echo "Err: $errors"
    echo "Mean: $mean"
    echo "Min: $min"
    echo "Max: $max"
    echo "-----------------------------------"
    sleep $SLEEP_TIME
done
echo "All done!"

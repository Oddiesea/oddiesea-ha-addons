#!/usr/bin/env bash
# Protocol tests against the fake radio, then a container check that port 5000 accepts a connection.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "${ROOT}"

echo "Building coresplitter for the protocol tests"
cargo build

echo "Running fake-radio protocol tests"
python3 tools/test_proxy.py

IMAGE="ha-meshcore-tcproxy:smoke"
echo "Building the add-on image"
docker build -t "${IMAGE}" "${ROOT}"

NET="ha-meshcore-tcproxy-smoke"
docker rm -f smoke-supervisor smoke-radio smoke-proxy >/dev/null 2>&1 || true
docker network rm "${NET}" >/dev/null 2>&1 || true
docker network create "${NET}"

cleanup() {
    docker rm -f smoke-supervisor smoke-radio smoke-proxy >/dev/null 2>&1 || true
    docker network rm "${NET}" >/dev/null 2>&1 || true
}
trap cleanup EXIT

docker run -d --name smoke-radio --network "${NET}" --network-alias radio \
    -v "${ROOT}/tools:/tools:ro" \
    python:3-alpine \
    python /tools/fake_radio.py --port 5000

docker run -d --name smoke-supervisor --network "${NET}" --network-alias supervisor \
    -v "${ROOT}/smoke:/smoke:ro" \
    python:3-alpine \
    python /smoke/mock-supervisor.py

for _ in $(seq 1 30); do
    if docker exec smoke-radio python -c "import socket; s=socket.create_connection(('127.0.0.1', 5000), 2); s.close()" >/dev/null 2>&1; then
        break
    fi
    sleep 1
done

docker run -d --name smoke-proxy --network "${NET}" \
    -e SUPERVISOR_TOKEN=smoke \
    -p 5000:5000 \
    "${IMAGE}"

for _ in $(seq 1 60); do
    if python3 -c "import socket; s=socket.create_connection(('127.0.0.1', 5000), 2); s.close()" >/dev/null 2>&1; then
        echo "TCP port 5000 accepted a connection"
        docker logs smoke-proxy
        exit 0
    fi
    if [[ "$(docker inspect -f '{{.State.Running}}' smoke-proxy)" != "true" ]]; then
        echo "add-on container exited"
        docker logs smoke-proxy || true
        exit 1
    fi
    sleep 1
done

echo "timed out waiting for port 5000"
docker logs smoke-proxy || true
exit 1

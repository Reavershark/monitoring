#!/usr/bin/env bash

UUID=$(echo "{\"type\": \"query\", \"path\": [{\"name\": \"createScript\", \"args\": [\"Python\", \"print(\\\"Hello World!\\\")\"]}]}" | jq -c | websocat ws://localhost:8080/ws)
echo "{\"type\": \"query\", \"path\": [{\"name\": \"getScript\", \"args\": ["${UUID}"]}, {\"name\": \"run\"}]}" | jq -c | websocat ws://localhost:8080/ws

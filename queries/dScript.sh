#!/usr/bin/env bash

UUID=$(echo "{\"type\": \"query\", \"path\": [{\"name\": \"createScript\", \"args\": [\"D\", \"import std;\nvoid main(){writeln(\\\"Hello World!\\\");}\"]}]}" | jq -c | websocat ws://localhost:3000/ws)
echo "{\"type\": \"query\", \"path\": [{\"name\": \"getScript\", \"args\": ["${UUID}"]}, {\"name\": \"run\"}]}" | jq -c | websocat ws://localhost:3000/ws
echo "{\"type\": \"query\", \"path\": [{\"name\": \"getScript\", \"args\": ["${UUID}"]}, {\"name\": \"run\"}]}" | jq -c | websocat ws://localhost:3000/ws
echo "{\"type\": \"query\", \"path\": [{\"name\": \"getScript\", \"args\": ["${UUID}"]}, {\"name\": \"run\"}]}" | jq -c | websocat ws://localhost:3000/ws
echo "{\"type\": \"query\", \"path\": [{\"name\": \"getScript\", \"args\": ["${UUID}"]}, {\"name\": \"run\"}]}" | jq -c | websocat ws://localhost:3000/ws
echo "{\"type\": \"query\", \"path\": [{\"name\": \"getScript\", \"args\": ["${UUID}"]}, {\"name\": \"run\"}]}" | jq -c | websocat ws://localhost:3000/ws

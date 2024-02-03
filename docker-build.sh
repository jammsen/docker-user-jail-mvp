#!/bin/bash
docker stop user-jail-mvp
docker rm user-jail-mvp
docker build -t user-jail-mvp:local .
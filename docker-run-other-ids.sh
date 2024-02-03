#!/bin/bash
docker run --rm --name user-jail-mvp -e 'PUID=666' -e 'PGID=999'  user-jail-mvp:local $1 $2
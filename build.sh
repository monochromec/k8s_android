docker build -t minisrv .
docker rmi localhost:6000/minisrv 2>/dev/null
docker tag minisrv localhost:6000/minisrv
docker push localhost:6000/minisrv

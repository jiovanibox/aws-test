# イメージ、コンテナ、ネットワーク
docker system prune -f

# volumeも含める場合
docker system prune --volumes -f

# キャッシュの削除
docker builder prune -f

docker image prune -f

docker rmi $(docker images -q) -f
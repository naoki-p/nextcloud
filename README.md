## k8sマニフェストファイルを作る
$ ./generate.sh

## pod実行/終了
$ podman kube play nc.yml
$ podman kube down nc.yml

## log確認
$ podman pod logs -f nc
$ podman logs -f nc-proxy

## Caddy設定反映
$ podman exec -it -w /etc/caddy nc-proxy caddy reload

## 構成
* pod
  * nc
* container
  * nc-db
  * nc-app
  * nc-proxy
* image
  * localhost/postgresjp:latest
* volume
  * nc-pgdata
  * nc-html
  * nc-caddydata


# [`./vd-dcr.pl`] Value-DomainでCertbotのDNS-01 challengeを自動化するためのツール

`./vd-dns-util.pl`を利用した実装サンプルでもある。

## 動作確認環境

| Env  | Ver                |
| ---- | ------------------ |
| OS   | Ubuntu 24.04.3 LTS |
| perl | 5.38.2             |

## 必須モジュール

[vd-dns-util.pl](vd-dns-util.md)の必須モジュール及び、下記モジュール。

| モジュール | 用途                      |
| ---------- | ------------------------- |
| `JSON::PP` | JSONのエンコード/デコード |
| `FindBin`  | スクリプトのパス解決      |

## 使い方

1. certbotがない場合インストールする
   ```bash
   sudo apt install certbot
   ```
2. 本リポジトリの中身を任意の場所に展開し、適切な実行権限を付与する
   ```bash
   chmod +x /path/to/vd-dcr.pl
   ```
3. 証明書を作るためのコマンドを叩く
   ```bash
   sudo certbot certonly --manual -n \
     --preferred-challenges dns \
     --agree-tos -m <your-email> \
     --manual-auth-hook "/path/to/vd-dcr.pl <value-domain-api-key> <root-domain> <optional:ttl>" \
     -d <target-domain>
   ```
   **記述例**
   ```bash
   sudo certbot certonly --manual -n \
     --preferred-challenges dns \
     --agree-tos -m postmaster@example.com \
     --manual-auth-hook "/path/to/vd-dcr.pl x9FwKp3RmT7vLnYq2sUcBj6hXoDiA8gZeJrN4aMbQV5tWlCy0EdGuHfS1oIxP9wKmR7nTvLjYq3sUcBp6hXoZiD2gJeKr4aMbQkV example.com" \
     -d hoge.example.com
   ```

apt経由でインストールした場合、以降は勝手に自動更新が走るはず。

何故なら、`/etc/cron.d/certbot`や`cat /usr/lib/systemd/system/certbot.service`には定期的な更新処理が記述されており、これらは恐らく`/etc/letsencrypt/renewal/*.conf`を参照して更新しているからだ。

`/etc/letsencrypt/renewal/*.conf`には、過去に実行した証明書更新用の設定が書き込まれており、態々毎回フルパラメーターを指定せずとも動くようになっているものと思われる。

この辺りは`sudo certbot renew --no-random-sleep-on-renew`を実行するとわかる。

## おまけ

### 生成した証明書の削除方法

以下のコマンドを叩くことでcertbotが生成した、そのドメインに対するファイルがすべて削除される。

```bash
sudo certbot delete --cert-name <target-domain>
# 例：
# sudo certbot delete --cert-name hoge.example.com
```

### 生成した証明書の失効と削除

```bash
sudo certbot revoke --cert-name <target-domain>
# 例：
# sudo certbot revoke --cert-name hoge.example.com
```

### OpenWrtで使う方法

[OpenWrtにPerlを入れてHTTPSやJSON、自作ライブラリを扱えるようにする](https://blog.lycolia.info/0620)を参照のこと。OpenWrt 24.10.0で確認済み。

## 既知の問題

## 1. ワイルドカードドメインに対応していない気がしている

以下でValue-DomainのDNSレコードが更新されることは確認しているが、正しく機能する状態で動作しているかは確認できていない。

```bash
sudo certbot certonly --manual -n \
  --preferred-challenges dns \
  --agree-tos -m <your-email> \
  --manual-auth-hook "/path/to/vd-dcr.pl 'XXXXXX' 'example.com' \
  -d 'example.com' -d '*.example.com'
```

## 2. 複数ドメインを一括指定した場合に正しく動くかどうかが不明

以下でValue-DomainのDNSレコードが更新されることは確認しているが、正しく機能する状態で動作しているかは確認できていない。

```bash
sudo certbot certonly --manual -n \
  --preferred-challenges dns \
  --agree-tos -m <your-email> \
  --manual-auth-hook "/path/to/vd-dcr.pl 'XXXXXX' 'example.com' \
  -d 'hoge.example.com' -d 'fuga.example.com'
```

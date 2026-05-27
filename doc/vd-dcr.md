# [`vd-dcr-auth.pl`, `vd-dcr-cleanup.pl`] Value-DomainでCertbotのDNS-01 challengeを自動化するためのツール

`lib/VdDnsUtil.pm`を利用した実装サンプルでもある。

両スクリプトで共通する処理（起動時表示、レスポンスのパース、Certbot環境変数の読み取り、TTL補正など）は[`lib/DcrUtil.pm`](DcrUtil.md)にまとめている。

複数ドメイン指定や、ワイルドカードドメインにも対応しているはず。

## 動作確認環境

| Env  | Ver                |
| ---- | ------------------ |
| OS   | Ubuntu 24.04.3 LTS |
| perl | 5.38.2             |

## 必須モジュール

[VdDnsUtil.pm](VdDnsUtil.md)の必須モジュール及び、下記モジュール。

| モジュール      | 用途                                   |
| --------------- | -------------------------------------- |
| `JSON::PP`      | JSONのエンコード/デコード              |
| `FindBin`       | スクリプトのパス解決                   |
| `Net::DNS::Dig` | DNSにTXTレコードが登録されたかの確認用 |

## 環境構築方法

1. certbotがない場合インストールする
   ```bash
   sudo apt install certbot
   ```
2. 本リポジトリの中身を任意の場所に展開し、適切な実行権限を付与する
   ```bash
   chmod +x /path/to/vd-dcr-auth.pl
   chmod +x /path/to/vd-dcr-cleanup.pl
   ```

## 使い方

### 一つのドメインに対し証明書を作る場合

**コマンドの基本書式**

```bash
sudo certbot certonly --manual -n \
  --preferred-challenges dns \
  --agree-tos -m <your-email> \
  --manual-auth-hook "/path/to/vd-dcr-auth.pl <value-domain-api-key> <root-domain> <optional:ttl>" \
  --manual-cleanup-hook "/path/to/vd-dcr-cleanup.pl <value-domain-api-key> <root-domain> <optional:ttl>" \
  -d <FQDN>
```

**記述例**

```bash
TARGET=example.com; \
VDAPIKEY=x9FwKp3RmT7vLnYq2sUcBj6hXoDiA8gZeJrN4aMbQV5tWlCy0EdGuHfS1oIxP9wKmR7nTvLjYq3sUcBp6hXoZiD2gJeKr4aMbQkV; \
sudo certbot certonly --manual -n \
  --preferred-challenges dns \
  --agree-tos -m postmaster@example.com \
  --manual-auth-hook "/path/to/vd-dcr-auth.pl $VDAPIKEY $TARGET" \
  --manual-cleanup-hook "/path/to/vd-dcr-cleanup.pl $VDAPIKEY $TARGET" \
  -d "$TARGET"
```

### ワイルドカードドメインに対し証明書を作る場合

**コマンドの基本書式**

```bash
sudo certbot certonly --manual -n \
  --preferred-challenges dns \
  --agree-tos -m <your-email> \
  --manual-auth-hook "/path/to/vd-dcr-auth.pl <value-domain-api-key> <root-domain> <optional:ttl>" \
  --manual-cleanup-hook "/path/to/vd-dcr-cleanup.pl <value-domain-api-key> <root-domain> <optional:ttl>" \
  -d <FQDN> \
  -d *.<FQDN>
```

**記述例**

```bash
TARGET=example.com; \
VDAPIKEY=x9FwKp3RmT7vLnYq2sUcBj6hXoDiA8gZeJrN4aMbQV5tWlCy0EdGuHfS1oIxP9wKmR7nTvLjYq3sUcBp6hXoZiD2gJeKr4aMbQkV; \
sudo certbot certonly --manual -n \
  --preferred-challenges dns \
  --agree-tos -m postmaster@example.com \
  --manual-auth-hook "path/to/vd-dcr-auth.pl $VDAPIKEY $TARGET" \
  --manual-cleanup-hook "path/to/vd-dcr-cleanup.pl $VDAPIKEY $TARGET" \
  -d "$TARGET" \
  -d "*.$TARGET"
```

### 複数のドメインに対し証明書を作る場合

**※このパターンは動作確認してません。**

```bash
sudo certbot certonly --manual -n \
  --preferred-challenges dns \
  --agree-tos -m <your-email> \
  --manual-auth-hook "/path/to/vd-dcr-auth.pl <value-domain-api-key> <root-domain> <optional:ttl>" \
  --manual-cleanup-hook "/path/to/vd-dcr-cleanup.pl <value-domain-api-key> <root-domain> <optional:ttl>" \
  -d <FQDN-1> \
  -d <FQDN-2> \
  -d <FQDN-3> \
  ...
```

**記述例**

```bash
TARGET=example.com; \
VDAPIKEY=x9FwKp3RmT7vLnYq2sUcBj6hXoDiA8gZeJrN4aMbQV5tWlCy0EdGuHfS1oIxP9wKmR7nTvLjYq3sUcBp6hXoZiD2gJeKr4aMbQkV; \
sudo certbot certonly --manual -n \
  --preferred-challenges dns \
  --agree-tos -m postmaster@example.com \
  --manual-auth-hook "path/to/vd-dcr-auth.pl $VDAPIKEY $TARGET" \
  --manual-cleanup-hook "path/to/vd-dcr-cleanup.pl $VDAPIKEY $TARGET" \
  -d "hoge.$TARGET" \
  -d "fuga.$TARGET" \
  -d "piyo.$TARGET"
```

## 自動的に更新を走らせる方法

apt経由でインストールした場合、以降は勝手に自動更新が走るはず。

何故なら、`/etc/cron.d/certbot`や`cat /usr/lib/systemd/system/certbot.service`には定期的な更新処理が記述されており、これらは恐らく`/etc/letsencrypt/renewal/*.conf`を参照して更新しているからだ。

`/etc/letsencrypt/renewal/*.conf`には、過去に実行した証明書更新用の設定が書き込まれており、態々毎回フルパラメーターを指定せずとも動くようになっているものと思われる。

この辺りは`sudo certbot renew`を実行するとわかる。

## おまけ

### 生成した証明書の削除方法

以下のコマンドを叩くことでcertbotが生成した、そのドメインに対するファイルがすべて削除される。

```bash
sudo certbot delete --cert-name <FQDN>
# 例：
# sudo certbot delete --cert-name hoge.example.com
```

### 生成した証明書の失効と削除

多分これで失効できるが確認してない。ついでにファイルも消してくれる

```bash
sudo certbot revoke --cert-name <FQDN>
# 例：
# sudo certbot revoke --cert-name hoge.example.com
```

### OpenWrtで使う方法

[OpenWrtにPerlを入れてHTTPSやJSON、自作ライブラリを扱えるようにする](https://blog.lycolia.info/0620)を参照のこと。OpenWrt 24.10.0で確認済み。

## デバッグ方法

以下のように`--dry-run`を足すとデバッグが可能。Value-DomainのDNSレコードが更新されるので注意。

```bash
sudo certbot certonly --manual -n \
  --dry-run \
  --preferred-challenges dns \
  --agree-tos -m <your-email> \
  --manual-auth-hook "/path/to/vd-dcr-auth.pl <value-domain-api-key> <root-domain> <optional:ttl>" \
  -d <FQDN>
```

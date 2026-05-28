# [`VdUtil.pm`] Value-Domain系処理の共通処理ユーティリティ

## 動作確認環境

| Env  | Ver                |
| ---- | ------------------ |
| OS   | Ubuntu 24.04.3 LTS |
| perl | 5.38.2             |

## 必須モジュール

[VdDnsUtil.pm](VdDnsUtil.md)、[DnsUtil.pm](DnsUtil.md)の必須モジュール及び、下記モジュール。

| モジュール | 用途                      |
| ---------- | ------------------------- |
| `JSON::PP` | JSONのエンコード/デコード |

## 使い方

`./vd-dcr-auth.pl`にあるように`use`して利用する想定。

```perl
use FindBin qw($Bin);
use lib "$Bin/lib";
use VdUtil;
```

## 実装関数

### `print_program_title($title, $version)`

起動時のプログラム名とバージョン情報（自身および利用ライブラリのバージョン）を標準出力に表示する。

**引数**

| 変数名     | 意味合い             |
| ---------- | -------------------- |
| `$title`   | プログラムタイトル   |
| `$version` | プログラムバージョン |

**戻り値**

なし。

**実装例**

```perl
VdUtil::print_program_title("Value-Domain DNS-01 challenge Authenticator", $VERSION);
```

出力例:

```text
=== Value-Domain DNS-01 challenge Authenticator ===
VERSION: 0.2.0
VdDnsUtil: 0.2.0
DnsUtil: 0.1.0
```

### `create_acme_domain($root_domain, $target_domain)`

`_acme-challenge`用のドメイン文字列（DNSレコードのレコード名部分）を生成する。

**引数**

| 変数名           | 意味合い       |
| ---------------- | -------------- |
| `$root_domain`   | ルートドメイン |
| `$target_domain` | 対象ドメイン   |

**戻り値**

`$target_domain`が`$root_domain`のサブドメインなら`_acme-challenge.<subdomain>`、それ以外（ルートドメインそのものなど）なら`_acme-challenge`。

**実装例**

```perl
VdUtil::create_acme_domain('example.com', 'example.com');
# => '_acme-challenge'

VdUtil::create_acme_domain('example.com', 'hoge.example.com');
# => '_acme-challenge.hoge'
```

### `print_source_data($body)`

Value-Domain DNS APIのGETレスポンスボディを標準出力に表示する。

**引数**

| 変数名  | 意味合い                          |
| ------- | --------------------------------- |
| `$body` | APIのレスポンスボディ(JSON文字列) |

**戻り値**

なし。

### `parse_dns_response($body, $code)`

Value-Domain DNS APIのGETレスポンスを検証してパースする。

HTTPステータスが200以外の場合は標準エラーへ理由を出力した上で`die`する。

**引数**

| 変数名  | 意味合い                            |
| ------- | ----------------------------------- |
| `$body` | APIのレスポンスボディ(JSON文字列)   |
| `$code` | APIのHTTPレスポンスステータスコード |

**戻り値**

リストで `($records, $ttl, $ns_type)` を返す。

| 変数名     | 意味合い                                |
| ---------- | --------------------------------------- |
| `$records` | APIのレスポンスにある`.results.records` |
| `$ttl`     | APIのレスポンスにある`.results.ttl`     |
| `$ns_type` | APIのレスポンスにある`.results.ns_type` |

**実装例**

```perl
my ($get_body, $get_code) = VdDnsUtil::request_get_records($apikey, $root_domain);
VdUtil::print_source_data($get_body);
my ($source_records, $source_ttl, $source_ns_type) = VdUtil::parse_dns_response($get_body, $get_code);
```

### `read_certbot_env()`

Certbotから渡される環境変数 `CERTBOT_DOMAIN` と `CERTBOT_VALIDATION` を取得する。

どちらか一方でも未設定の場合は`die`する。

**引数**

なし。

**戻り値**

リストで `($certbot_domain, $certbot_validation)` を返す。

| 変数名                | 意味合い                  |
| --------------------- | ------------------------- |
| `$certbot_domain`     | `CERTBOT_DOMAIN` の値     |
| `$certbot_validation` | `CERTBOT_VALIDATION` の値 |

**実装例**

```perl
my ($certbot_domain, $certbot_validation) = VdUtil::read_certbot_env();
```

### `adjust_ttl($argv_ttl, $source_ttl)`

スクリプト引数で指定されたTTLがあればそれを、なければAPIから返ってきたTTLを使い、Value-DomainのTTLバグ対策（[`VdDnsUtil::adjust_ttl`](VdDnsUtil.md)）を適用した値を返す。

**引数**

| 変数名        | 意味合い                                 |
| ------------- | ---------------------------------------- |
| `$argv_ttl`   | スクリプト引数のTTL（未指定なら`undef`） |
| `$source_ttl` | APIのレスポンスから取得したTTL           |

**戻り値**

補正後のTTL（120未満の値は120に補正される）。

**実装例**

```perl
my $adjusted_ttl = VdUtil::adjust_ttl($ttl, $source_ttl);
```

# [`t/VdUtil.t`] テストコード

## 必須モジュール

| モジュール   | 用途   |
| ------------ | ------ |
| `Test::More` | テスト |

## 実行方法

```bash
prove t/VdUtil.t
```

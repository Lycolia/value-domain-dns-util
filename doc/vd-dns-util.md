# [`./vd-dns-util.pl`] ツールキット本体

## 動作確認環境

### Ubuntu

| Env  | Ver                |
| ---- | ------------------ |
| OS   | Ubuntu 24.04.3 LTS |
| perl | 5.38.2             |

### OpenWrt

| Env                  | Ver             |
| -------------------- | --------------- |
| OS                   | OpenWrt 24.10.0 |
| perl                 | 5.40.0-r2       |
| perl-io-socket-ssl   | 2.089.5.40-r1   |
| perl-net-ssleay      | 1.94.5.40-r1    |
| perlbase-autoloader  | 5.40.0-r2       |
| perlbase-b           | 5.40.0-r2       |
| perlbase-base        | 5.40.0-r2       |
| perlbase-bytes       | 5.40.0-r2       |
| perlbase-class       | 5.40.0-r2       |
| perlbase-config      | 5.40.0-r2       |
| perlbase-cwd         | 5.40.0-r2       |
| perlbase-dynaloader  | 5.40.0-r2       |
| perlbase-errno       | 5.40.0-r2       |
| perlbase-essential   | 5.40.0-r2       |
| perlbase-fcntl       | 5.40.0-r2       |
| perlbase-feature     | 5.40.0-r2       |
| perlbase-file        | 5.40.0-r2       |
| perlbase-filehandle  | 5.40.0-r2       |
| perlbase-findbin     | 5.40.0-r2       |
| perlbase-http-tiny   | 5.40.0-r2       |
| perlbase-i18n        | 5.40.0-r2       |
| perlbase-integer     | 5.40.0-r2       |
| perlbase-io          | 5.40.0-r2       |
| perlbase-json-pp     | 5.40.0-r2       |
| perlbase-list        | 5.40.0-r2       |
| perlbase-locale      | 5.40.0-r2       |
| perlbase-mime        | 5.40.0-r2       |
| perlbase-params      | 5.40.0-r2       |
| perlbase-posix       | 5.40.0-r2       |
| perlbase-re          | 5.40.0-r2       |
| perlbase-scalar      | 5.40.0-r2       |
| perlbase-selectsaver | 5.40.0-r2       |
| perlbase-socket      | 5.40.0-r2       |
| perlbase-symbol      | 5.40.0-r2       |
| perlbase-tie         | 5.40.0-r2       |
| perlbase-unicore     | 5.40.0-r2       |
| perlbase-utf8        | 5.40.0-r2       |
| perlbase-xsloader    | 5.40.0-r2       |

## 必須モジュール

| モジュール   | 用途           |
| ------------ | -------------- |
| `HTTP::Tiny` | HTTPリクエスト |

## 使い方

`./vd-dcr.pl`にあるように`require`して利用する想定。

```perl
use FindBin qw($Bin);
require "$Bin/vd-dns-util.pl";
```

## 実装関数

### `request_get_records($apikey, $root_domain)`

Value-DomainのDNS APIに指定ドメインのDNSレコード設定の問い合わせを行い当該ドメインのDNSレコード設定を取得する。

**引数**

| 変数名         | 意味合い                  |
| -------------- | ------------------------- |
| `$apikey`      | Value-DomainのAPIトークン |
| `$root_domain` | ルートドメイン            |

**戻り値**

リストで `($body, $code)` を返す。

| 変数名  | 意味合い                            | 備考 |
| ------- | ----------------------------------- | ---- |
| `$body` | APIのレスポンスボディ(JSON文字列)   |      |
| `$code` | APIのHTTPレスポンスステータスコード |      |

**実装例**

```perl
my ($get_body, $get_code) = request_get_records($apikey, $root_domain);

if ($get_code != 200) {
    print STDERR "CODE:$get_code\tDNSレコードの取得に失敗しました。\n";
    exit 10;
}

use JSON::PP;
my $json         = decode_json($get_body);
my $records      = $json->{results}{records};
my $ttl          = $json->{results}{ttl};
my $ns_type      = $json->{results}{ns_type};
```

### `find_first_record($records, $subject)`

Value-DomainのDNSレコードのレコードを検索し、一致した先頭一件を取得する。

**引数**

| 変数名     | 意味合い                                       | 備考           |
| ---------- | ---------------------------------------------- | -------------- |
| `$records` | APIのレスポンスにある`.results.records`        |                |
| `$subject` | 検索するレコード文字列（レコード名の完全一致） | `txt hoge`など |

**戻り値**

一致したものがあれば、その最初のレコード行。なければ空文字。

**実装例**

```perl
my $exists = find_first_record($records, "txt $certbot_domain");

if ($exists eq '') {
    # レコードがなかった時の処理
} else {
    # レコードがあった時の処理
}
```

### `append_record($records, $record)`

Value-DomainのDNSレコードデータ（records）にレコードを追加する。

**引数**

| 変数名     | 意味合い                                |
| ---------- | --------------------------------------- |
| `$records` | APIのレスポンスにある`.results.records` |
| `$record`  | 追加するレコード行文字列                |

**戻り値**

`$records`の末尾に`$record`を追加した文字列。

**実装例**

```perl
# $records はDNS APIの .results.records
# $record はDNSレコード一行分
my $new_records = append_record($records, $record);
```

### `replace_record($records, $subject, $replacement)`

Value-DomainのDNSレコードデータ（records）にあるレコードを置換する。

検索文字列に一致した行のレコードを置換するレコードで置き換える。

**引数**

| 変数名         | 意味合い                                |
| -------------- | --------------------------------------- |
| `$records`     | APIのレスポンスにある`.results.records` |
| `$subject`     | 検索文字列（レコード名の完全一致）      |
| `$replacement` | 置換するレコード行                      |

**戻り値**

`$records`の中にある`$subject`と一致するレコードを`$replacement`で置換した文字列。

**実装例**

```perl
my $new_record  = qq(txt $acme_domain "$certbot_validation");
my $new_records = replace_record($source_records, "txt $acme_domain", $new_record);
```

### `adjust_ttl($ttl)`

ttlが120未満であれば120に補正し、そうでなければそのままを返す。

これはValue-Domain APIの仕様上、ttlに120未満を指定すると、3600が割り当てられるため、最短の120を割り当てるようにするための補助関数である。

**引数**

| 変数名 | 意味合い  |
| ------ | --------- |
| `$ttl` | ttlの秒数 |

**戻り値**

`$ttl`が120未満なら120、そうでなければ`$ttl`。

**実装例**

```perl
my $source_ttl   = 60;
my $adjusted_ttl = adjust_ttl($source_ttl);  # => 120

my $source_ttl   = 130;
my $adjusted_ttl = adjust_ttl($source_ttl);  # => 130
```

### `request_update_records($apikey, $root_domain, $json)`

Value-DomainのDNS APIに指定ドメインのDNSレコード更新の要求行い当該ドメインのDNSレコード設定を更新する。

**引数**

| 変数名         | 意味合い                  | 備考                                                              |
| -------------- | ------------------------- | ----------------------------------------------------------------- |
| `$apikey`      | Value-DomainのAPIトークン |                                                                   |
| `$root_domain` | ルートドメイン            |                                                                   |
| `$json`        | 更新データのJSON文字列    | `{"ns_type":"<文字列>","records":"<文字列>","ttl":<数値>}` の形式 |

**戻り値**

リストで `($body, $code)` を返す。

| 変数名  | 意味合い                            |
| ------- | ----------------------------------- |
| `$body` | APIのレスポンスボディ(JSON文字列)   |
| `$code` | APIのHTTPレスポンスステータスコード |

**実装例**

```perl
use JSON::PP;
my $json = encode_json({
    ns_type => $source_ns_type,
    records => $new_records,
    ttl     => $adjusted_ttl,
});

my ($update_body, $update_code) = request_update_records($apikey, $root_domain, $json);

if ($update_code != 200) {
    print STDERR "CODE:$update_code\tDNSレコードの更新に失敗しました。\n";
    exit 11;
}
```

# [`./test_vd-dns-util.pl`] テストコード

## 必須モジュール

| モジュール   | 用途   |
| ------------ | ------ |
| `Test::More` | テスト |

## 実行方法

```bash
./test_vd-dns-util.pl
```

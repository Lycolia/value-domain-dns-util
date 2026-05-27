# [`DnsUtil.pm`] DNS操作用のユーティリティ

`Net::DNS::Dig`を用いてDNSレコードを問い合わせるためのユーティリティ関数群。

## 動作確認環境

| Env  | Ver                |
| ---- | ------------------ |
| OS   | Ubuntu 24.04.3 LTS |
| perl | 5.38.2             |

## 必須モジュール

| モジュール      | 用途                    |
| --------------- | ----------------------- |
| `Net::DNS::Dig` | DNSレコードの問い合わせ |

## 使い方

`./vd-dcr-auth.pl`にあるように`use`して利用する想定。

```perl
use FindBin qw($Bin);
use lib "$Bin/lib";
use DnsUtil;
```

## 実装関数

### `dig_value($fqdn, $type, @nameservers)`

指定したFQDNに対してDNSレコードの問い合わせを行い、レコードタイプに紐づく値を取得する。

**引数**

| 変数名         | 意味合い                                   | 備考                          |
| -------------- | ------------------------------------------ | ----------------------------- |
| `$fqdn`        | レコードを確認するFQDN                     |                               |
| `$type`        | レコードタイプ                             | `A`, `AAAA`, `NS`, `TXT` など |
| `@nameservers` | 問い合わせ先のネームサーバー（可変長引数） | 空ならローカルリゾルバを使用  |

**戻り値**

`dig`の実行結果を配列で返す。レコードが取れなかった場合は空配列。

**実装例**

```perl
# ローカルリゾルバで権威NSを引く
my @auth_ns = DnsUtil::dig_value($root_domain, 'NS');

# ネームサーバを指定してTXTレコードを引く
my @txt = DnsUtil::dig_value('_acme-challenge.example.com', 'TXT', 'ns1.example.com');
```

### `find_record($fqdn, $type, $search_string, $poll_times, $poll_wait, @nameservers)`

DNSレコードが全ネームサーバーに反映されたかをポーリングで確認する。

ネームサーバーごとに個別問い合わせを行い、すべてのネームサーバーで`$search_string`に部分一致するレコードが返ってきた場合のみ成功とする。

ある試行において、いずれかのネームサーバーで一致が得られなかった場合は同試行内の残りのネームサーバーへの問い合わせは打ち切り、`$poll_wait`秒待機して次の試行へ進む。

**引数**

| 変数名           | 意味合い                                   | 備考                          |
| ---------------- | ------------------------------------------ | ----------------------------- |
| `$fqdn`          | FQDN                                       |                               |
| `$type`          | レコードタイプ                             | `A`, `AAAA`, `NS`, `TXT` など |
| `$search_string` | 検索する文字列（部分一致）                 |                               |
| `$poll_times`    | ポーリングする回数                         | `0`を指定した場合は何もしない |
| `$poll_wait`     | ポーリングする間隔（秒）                   |                               |
| `@nameservers`   | 問い合わせ先のネームサーバー（可変長引数） | 空ならローカルリゾルバを使用  |

**戻り値**

すべてのネームサーバーに反映されていれば`1`、`$poll_times`回試行しても反映されていなければ`0`。

**実装例**

```perl
my @auth_ns = DnsUtil::dig_value($root_domain, 'NS');

my $fqdn = "$acme_domain.$root_domain";
my $found = DnsUtil::find_record($fqdn, 'TXT', $certbot_validation, 180, 3, @auth_ns);

if ($found) {
    exit 0;
} else {
    exit 13;
}
```

# [`t/DnsUtil.t`] テストコード

## 必須モジュール

| モジュール   | 用途   |
| ------------ | ------ |
| `Test::More` | テスト |

## 実行方法

```bash
prove t/DnsUtil.t
```

# [`vd-ddns-v4.pl`] Value-Domainで複数のAレコードに対しDDNSするためのツール

指定したルートドメインのDNSレコードから、指定したホスト名のAレコードを検索し、IPv4アドレスを一括更新する。

## 動作確認環境

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

[vd-dns-util.pl](vd-dns-util.md)の必須モジュール及び、下記モジュール。

| モジュール | 用途                 |
| ---------- | -------------------- |
| `FindBin`  | スクリプトのパス解決 |

## 使い方

1. 本リポジトリの中身を任意の場所に展開し、適切な実行権限を付与する
   ```bash
   chmod +x /path/to/vd-ddns-v4.pl
   ```
2. 更新したいホスト名と新しいIPアドレスを指定して実行する
   ```bash
   /path/to/vd-ddns-v4.pl <value-domain-api-key> <root-domain> <new-ipv4> <hostname> [hostname...]
   ```
   **記述例**
   ```bash
   /path/to/vd-ddns-v4.pl x9FwKp3RmT7vLnYq2sUcBj6hXoDiA8gZeJrN4aMbQV5tWlCy0EdGuHfS1oIxP9wKmR7nTvLjYq3sUcBp6hXoZiD2gJeKr4aMbQkV example.com 22.33.44.55 hoge fuga piyo
   ```
   上記の例では `hoge.example.com`、`fuga.example.com`、`piyo.example.com` のAレコードを `22.33.44.55` に更新する。

指定したホスト名が既存レコードに存在しない場合、そのホスト名はスキップされ標準エラーに警告を出力する（新規追加はしない）。

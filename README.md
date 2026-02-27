# Value-Domain DNS API Utility

[Value-DomainのDNS API](https://www.value-domain.com/api/doc/domain/#tag/DNS)をValue-DomainのDNS APIをPerlから叩くためのスクリプトと、そのユーティリティ関数群（ツールキット）。

DNSラウンドロビンのような同じドメインに複数のレコードがあるものは想定していない。

## 内容物

| ファイル                                 | 内容                                              |
| ---------------------------------------- | ------------------------------------------------- |
| [lib/vd-dns-util.pl](doc/vd-dns-util.md) | ツールキット本体                                  |
| [vd-dcr.pl](doc/vd-dcr.md)               | CertbotのDNS-01 challengeを自動化するためのツール |
| [vd-ddns-v4.pl](doc/vd-ddns-v4.md)       | 特定のAレコードに対しDDNSするためのツール         |

## ライセンス

MIT

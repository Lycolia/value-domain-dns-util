# Value-Domain DNS API Utility

[Value-DomainのDNS API](https://www.value-domain.com/api/doc/domain/#tag/DNS)をPerlから叩くためのツールキットと、すぐに使えるツール群。

DNSラウンドロビンのような同じドメインに複数のレコードがあるものは想定していない。

## 内容物

| ファイル                                 | 内容                                              |
| ---------------------------------------- | ------------------------------------------------- |
| [lib/vd-dns-util.pl](doc/vd-dns-util.md) | ツールキット本体                                  |
| [vd-dcr.pl](doc/vd-dcr.md)               | CertbotのDNS-01 challengeを自動化するためのツール |
| [vd-ddns_v4.pl](doc/vd-ddns_v4.md)       | 特定のAレコードに対しDDNSするためのツール         |

## ライセンス

MIT

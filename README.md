# Value-Domain DNS API Utility

[Value-DomainのDNS API](https://www.value-domain.com/api/doc/domain/#tag/DNS)をValue-DomainのDNS APIをPerlから叩くためのスクリプトと、そのユーティリティ関数群（ツールキット）。

DNSラウンドロビンのような同じドメインに複数のレコードがあるものは想定していない。

## 内容物

| ファイル                             | 内容                                              |
| ------------------------------------ | ------------------------------------------------- |
| [lib/VdDnsUtil.pm](doc/VdDnsUtil.md) | ValueDomain DNS APIのツールキット本体             |
| [lib/DnsUtil.pm](doc/DnsUtil.md)     | DNS操作用のユーティリティ                         |
| [vd-dcr.pl](doc/vd-dcr.md)           | CertbotのDNS-01 challengeを自動化するためのツール |
| [vd-ddns-v4.pl](doc/vd-ddns-v4.md)   | 特定のAレコードに対しDDNSするためのツール         |

## ライセンス

MIT

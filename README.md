# Value-Domain DNS API Utility

[Value-DomainのDNS API](https://www.value-domain.com/api/doc/domain/#tag/DNS)をPerlから叩くためのスクリプトと、そのユーティリティ関数群（ツールキット）。

DNSラウンドロビンのような同じドメインに複数のレコードがあるものは想定していない。

## 内容物の説明書

| ファイル                                           | 内容                                                 |
| -------------------------------------------------- | ---------------------------------------------------- |
| [lib/VdDnsUtil.pm](doc/VdDnsUtil.md)               | ValueDomain DNS APIのツールキット本体                |
| [lib/DnsUtil.pm](doc/DnsUtil.md)                   | DNS操作用のユーティリティ                            |
| [lib/VdUtil.pm](doc/VdUtil.md)                     | 本リポジトリのスクリプトの共通処理ユーティリティ     |
| [vd-dcr-auth.pl, vd-dcr-cleanup.pl](doc/vd-dcr.md) | CertbotのDNS-01 challengeを自動化するためのツール    |
| [vd-ddns-v4.pl](doc/vd-ddns-v4.md)                 | IPv4向け複数ドメインへのDDNSを自動化するためのツール |

## ライセンス

MIT

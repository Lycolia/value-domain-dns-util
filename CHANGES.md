# 2026-05-28

- モジュール系を`.pl`から`.pm`に移行
- DNSの伝播前にLet's Encryptが検証するときに失敗する問題を修正
  - DNSの伝播を確認し、若干待機してからスクリプトを終了するように変更
- バージョンをつけて欲しいという要望に対応
  - 起動時に出ます。`--version`的なオプションをつけての表示には対応してません
- ワイルドカードドメインなど、複数ドメインを指定した時に`--manual-cleanup-hook`がないと失敗する問題に対応
  - `--manual-cleanup-hook`用のスクリプトを追加し、従来のスクリプトに持たせていたクリーンアップ処理を削除
- `vd-dcr-*.pl`系の共通処理置き場として`lib/DcrUtil.pm`を作成
  - 起動時表示、レスポンスのパース、Certbot環境変数の読み取り、TTL補正をユーティリティ関数化
- その他、`vd-dcr-*.pl`系の使い方の例にワイルドカードドメインや、複数ドメインの一括指定方法を追加

# 2026-02-26

TypeScriptで実装していた[value-domain-dns-cert-register](https://github.com/Lycolia/value-domain-dns-cert-register)をPerlにコンバートし、ワイルドカードドメインで利用できるように整備。

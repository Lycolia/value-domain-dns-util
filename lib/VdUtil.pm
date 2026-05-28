package VdUtil;

use strict;
use warnings;
use JSON::PP;

our $VERSION = '2026-05-28';

# 起動時のプログラム名とバージョン情報を標準出力に表示する
# 引数:
#   $title   : プログラムタイトル
#   $prg_ver : プログラムバージョン
#   @libs    : (ライブラリ名, バージョン) のペアの並び（可変長）
sub print_program_title {
    my ($title, $prg_ver, @libs) = @_;
    print "=== $title ===\n";
    print "VERSION: $prg_ver\n";
    while (my ($name, $ver) = splice(@libs, 0, 2)) {
        print "$name: $ver\n";
    }
    print "VdUtil: $VERSION\n";
}

# _acme-challenge用のドメイン文字列を生成する
# 引数:
#   $root_domain   : ルートドメイン
#   $target_domain : 対象ドメイン
# 戻り値:
#   サブドメインがあれば "_acme-challenge.<subdomain>"、なければ "_acme-challenge"
sub create_acme_domain {
    my ($root_domain, $target_domain) = @_;
    if ($target_domain =~ /^(.+)\.\Q$root_domain\E$/) {
        return "_acme-challenge.$1";
    } else {
        return "_acme-challenge";
    }
}

# Value-Domain DNS APIのGETレスポンスボディを標準出力に表示する
# 引数:
#   $body : APIのレスポンスボディ（JSON文字列）
sub print_source_data {
    my ($body) = @_;
    print "=== SOURCE DATA ===\n";
    print "$body\n";
}

# Value-Domain DNS APIのGETレスポンスを検証してパースする
# HTTPステータスが200以外ならSTDERRにエラーを出力して exit 10 する
# 引数:
#   $body : APIのレスポンスボディ（JSON文字列）
#   $code : HTTPステータスコード
# 戻り値: ($records, $ttl, $ns_type) のリスト
#   $records : DNSレコード本文（複数行文字列）
#   $ttl     : APIから返ってきたTTL
#   $ns_type : APIから返ってきたns_type
sub parse_dns_response {
    my ($body, $code) = @_;

    if ($code == 200) {
        my $json = decode_json($body);

        return (
            $json->{results}{records},
            $json->{results}{ttl},
            $json->{results}{ns_type},
        );
    } else {
        print STDERR "CODE:$code\tDNSレコードの取得に失敗しました。\n";
        print STDERR "$body\n";
        exit 10;
    }
}

# Certbotから渡される環境変数を取得する
# CERTBOT_DOMAIN または CERTBOT_VALIDATION が未設定なら exit 20 する
# 戻り値: ($certbot_domain, $certbot_validation) のリスト
sub read_certbot_env {
    my $certbot_domain     = $ENV{CERTBOT_DOMAIN};
    unless ($certbot_domain) {
        print STDERR "CERTBOT_DOMAIN is not set\n";
        exit 20;
    }
    my $certbot_validation = $ENV{CERTBOT_VALIDATION};
    unless ($certbot_validation) {
        print STDERR "CERTBOT_VALIDATION is not set\n";
        exit 21;
    }
    return ($certbot_domain, $certbot_validation);
}

# Value-Domain DNS APIの更新レスポンスを処理する
# HTTPステータスが200以外なら標準エラーにリクエスト/レスポンスを出力して0を返す
# 200なら標準出力にレスポンスボディを表示して1を返す
# 引数:
#   $code : HTTPステータスコード
#   $body : APIのレスポンスボディ
#   $req  : 送信したリクエストボディ（JSON文字列）
# 戻り値: 成功なら1、失敗なら0
sub handle_update_response {
    my ($code, $body, $req) = @_;

    if ($code != 200) {
        print STDERR "CODE:$code\tDNSレコードの更新に失敗しました。\n";
        print STDERR "=== RESPONSE DATA ===\n";
        print STDERR "$body\n";
        print STDERR "=== REQUEST DATA ===\n";
        print STDERR "$req\n";

        return 0;
    } else {
        print "CODE:$code\tDNSレコードの更新に成功しました。\n";
        print "=== UPDATED DATA ===\n";
        print "$body\n";

        return 1;
    }
}

1;

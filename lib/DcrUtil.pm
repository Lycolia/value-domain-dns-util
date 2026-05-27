package DcrUtil;

use strict;
use warnings;
use JSON::PP;
use VdDnsUtil;
use DnsUtil;

# 起動時のプログラム名とバージョン情報を標準出力に表示する
# 引数:
#   $title   : プログラムタイトル
#   $version : プログラムバージョン
sub print_program_title {
    my ($title, $version) = @_;
    print "=== $title ===\n";
    print "VERSION: $version\n";
    print "VdDnsUtil: ${VdDnsUtil::VERSION}\n";
    print "DnsUtil: ${DnsUtil::VERSION}\n";
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
    }
    return "_acme-challenge";
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
# HTTPステータスが200以外ならSTDERRにエラーを出力してdieする
# 引数:
#   $body : APIのレスポンスボディ（JSON文字列）
#   $code : HTTPステータスコード
# 戻り値: ($records, $ttl, $ns_type) のリスト
#   $records : DNSレコード本文（複数行文字列）
#   $ttl     : APIから返ってきたTTL
#   $ns_type : APIから返ってきたns_type
sub parse_get_response {
    my ($body, $code) = @_;
    if ($code != 200) {
        print STDERR "CODE:$code\tDNSレコードの取得に失敗しました。\n";
        print STDERR "$body\n";
        die "request_get_records failed\n";
    }
    my $json = decode_json($body);
    return (
        $json->{results}{records},
        $json->{results}{ttl},
        $json->{results}{ns_type},
    );
}

# Certbotから渡される環境変数を取得する
# CERTBOT_DOMAIN または CERTBOT_VALIDATION が未設定ならdieする
# 戻り値: ($certbot_domain, $certbot_validation) のリスト
sub read_certbot_env {
    my $certbot_domain     = $ENV{CERTBOT_DOMAIN}     or die "CERTBOT_DOMAIN is not set\n";
    my $certbot_validation = $ENV{CERTBOT_VALIDATION} or die "CERTBOT_VALIDATION is not set\n";
    return ($certbot_domain, $certbot_validation);
}

# スクリプト引数のTTLがあればそれを、なければソースのTTLを使い、120未満なら120に補正する
# 引数:
#   $argv_ttl   : スクリプト引数で指定されたTTL（未指定ならundef）
#   $source_ttl : APIのレスポンスから取得したTTL
# 戻り値:
#   補正後のTTL
sub adjust_ttl {
    my ($argv_ttl, $source_ttl) = @_;
    return defined $argv_ttl
        ? VdDnsUtil::adjust_ttl($argv_ttl + 0)
        : VdDnsUtil::adjust_ttl($source_ttl + 0);
}

1;
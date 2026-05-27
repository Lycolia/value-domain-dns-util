#!/usr/bin/perl
# Value-DomainでCertbotのDNS-01 challengeを自動化するためのツール
# vd-dcr-cleanup.pl <value-domain-api-key> <root-domain> [ttl]
#
# [ttl]はオプションなので省いてもよい
# 120未満を指定した場合、120として解釈、無指定の場合はAPIから来た値を割り当てるが
# APIから来た値が120未満の場合、120を割り当てる
# これはValue-Domain APIの仕様上、120未満を指定すると、3600が割り当てられるため
# 最短の120を割り当てるようにしている

use strict;
use warnings;
use POSIX;
use JSON::PP;
use FindBin qw($Bin);
use lib "$Bin/lib";
use VdDnsUtil;
use DnsUtil;
use DcrUtil;

my $VERSION = '0.1.0';

DcrUtil::print_program_title("Value-Domain DNS-01 challenge Cleaner", $VERSION);

my ($apikey, $root_domain, $ttl) = @ARGV;

unless ($apikey && $root_domain) {
    die "Usage: $0 <apikey> <root-domain> [ttl]\n";
}

# ValueDomainAPIからレコードを取得
my ($get_body, $get_code) = VdDnsUtil::request_get_records($apikey, $root_domain);

DcrUtil::print_source_data($get_body);

my ($source_records, $source_ttl, $source_ns_type) = DcrUtil::parse_get_response($get_body, $get_code);
my ($certbot_domain, $certbot_validation) = DcrUtil::read_certbot_env();

my $acme_domain = DcrUtil::create_acme_domain($root_domain, $certbot_domain);

# Certbotの情報でレコードを削除
my $old_record = qq(txt $acme_domain "$certbot_validation");
my $new_records = VdDnsUtil::delete_records($source_records, $old_record);

# ValueDomainAPIにあるTTLのバグ対応
my $adjusted_ttl = DcrUtil::adjust_ttl($ttl, $source_ttl);

my $json = encode_json({
    ns_type => $source_ns_type,
    records => $new_records,
    ttl => $adjusted_ttl,
});

# ValueDomainAPIにレコードの更新要求を出す
my ($update_body, $update_code) = VdDnsUtil::request_update_records($apikey, $root_domain, $json);

if ($update_code != 200) {
    print STDERR "CODE:$update_code\tDNSレコードの更新に失敗しました。\n";
    print STDERR "=== RESPONSE DATA ===\n";
    print STDERR "$update_body\n";
    print STDERR "=== REQUEST DATA ===\n";
    print STDERR "$json\n";
    exit 11;
}

print "=== UPDATED DATA ===\n";
print "$update_body\n";

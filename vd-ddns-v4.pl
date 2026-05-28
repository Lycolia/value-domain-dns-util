#!/usr/bin/perl
# Value-DomainでIPv4向けのバルクDDNSを自動化するためのツール
# vd-ddns-v4.pl <apikey> <root-domain> <new-ipv4> [hostname...]
#
# 指定したホスト名のAレコードのIPv4アドレスを<new-ipv4>に一括更新する
# [hostname...] は $get_json->{results}{records} 内の "a <hostname> <ip>" の
# <hostname> 部分に一致するサブドメイン名を指定する

use strict;
use warnings;
use JSON::PP;
use FindBin qw($Bin);
use lib "$Bin/lib";
use VdDnsUtil;
use VdUtil;

my $VERSION = '2026-05-28';

print "=== Value-Domain DDNS tool ===\n";
print "VERSION: $VERSION\n";
print "VdDnsUtil: ${VdDnsUtil::VERSION}\n";

my ($apikey, $root_domain, $new_ip, @hostnames) = @ARGV;

unless ($apikey && $root_domain && $new_ip && @hostnames) {
    die "Usage: $0 <apikey> <root-domain> <new-ipv4> <hostname> [hostname...]\n";
}

# ValueDomainAPIからレコードを取得
my ($get_body, $get_code) = VdDnsUtil::request_get_records($apikey, $root_domain);
VdUtil::print_source_data($get_body);
my ($source_records, $source_ttl, $source_ns_type) = VdUtil::parse_dns_response($get_body, $get_code);

if ($source_records == 0) {
    exit 10;
}

# 指定ホスト名ごとにAレコードを新しいIPに置換
my $new_records = $source_records;
for my $hostname (@hostnames) {
    my $subject = "a $hostname";
    my $exists = VdDnsUtil::find_first_record($new_records, $subject);
    my $new_record = "a $hostname $new_ip";
    if ($exists ne '') {
        $new_records = VdDnsUtil::replace_record($new_records, $subject, $new_record);
    } else {
        print STDERR "$subject は既存レコードに見つかりませんでした。\n";
    }
}

my $adjusted_ttl = VdDnsUtil::adjust_ttl($source_ttl + 0);

my $json = encode_json({
    ns_type => $source_ns_type,
    records => $new_records,
    ttl => $adjusted_ttl,
});

# ValueDomainAPIにレコードの更新要求を出す
my ($update_body, $update_code) = VdDnsUtil::request_update_records($apikey, $root_domain, $json);
my $succeed = VdUtil::handle_update_response($update_code, $update_body, $json);

if ($succeed == 1) {
    exit 0;
} else {
    exit 11;
}

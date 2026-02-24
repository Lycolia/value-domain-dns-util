#!/usr/bin/perl
# vd-ddns_v4.pl <apikey> <root-domain> <new-ipv4> [hostname...]
#
# 指定したホスト名のAレコードのIPv4アドレスを<new-ipv4>に一括更新する
# [hostname...] は $get_json->{results}{records} 内の "a <hostname> <ip>" の
# <hostname> 部分に一致するサブドメイン名を指定する

use strict;
use warnings;
use JSON::PP;
use FindBin qw($Bin);
require "$Bin/lib/vd-dns-util.pl";

my ($apikey, $root_domain, $new_ip, @hostnames) = @ARGV;

unless ($apikey && $root_domain && $new_ip && @hostnames) {
    die "Usage: $0 <apikey> <root-domain> <new-ipv4> <hostname> [hostname...]\n";
}

# ValueDomainAPIからレコードを取得
my ($get_body, $get_code) = request_get_records($apikey, $root_domain);

if ($get_code != 200) {
    print STDERR "CODE:$get_code\tDNSレコードの取得に失敗しました。\n";
    print STDERR "$get_body\n";
    exit 10;
}

my $get_json       = decode_json($get_body);
my $source_records = $get_json->{results}{records};
my $source_ttl     = $get_json->{results}{ttl};
my $source_ns_type = $get_json->{results}{ns_type};

# 指定ホスト名ごとにAレコードを新しいIPに置換
my $new_records = $source_records;
for my $hostname (@hostnames) {
    my $subject     = "a $hostname";
    my $exists      = find_first_record($new_records, $subject);
    my $new_record  = "a $hostname $new_ip";
    if ($exists ne '') {
        $new_records = replace_record($new_records, $subject, $new_record);
    } else {
        print STDERR "$subject は既存レコードに見つかりませんでした。\n";
    }
}

my $adjusted_ttl = adjust_ttl($source_ttl + 0);

my $json = encode_json({
    ns_type => $source_ns_type,
    records => $new_records,
    ttl     => $adjusted_ttl,
});

# ValueDomainAPIにレコードの更新要求を出す
my ($update_body, $update_code) = request_update_records($apikey, $root_domain, $json);

if ($update_code != 200) {
    print STDERR "CODE:$update_code\tDNSレコードの更新に失敗しました。\n";
    print STDERR "$update_body\n";
    exit 11;
}

print "$update_body\n";

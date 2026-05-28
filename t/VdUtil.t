#
# 実行方法:
#   prove t/VdUtil.t
#
# Test::MoreはPerlコアモジュールのため追加インストール不要
#

use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use VdUtil;

# STDOUT/STDERRを文字列に取り込むためのヘルパー
# 引数: 実行する無名sub
# 戻り値: (stdout, stderr, exception) のリスト
#   $code内でdieしても例外を再throwせず、第三戻り値として返す
sub capture {
    my ($code) = @_;
    my ($stdout, $stderr) = ('', '');
    open(my $oldout, '>&', \*STDOUT) or die "dup STDOUT: $!";
    open(my $olderr, '>&', \*STDERR) or die "dup STDERR: $!";
    close STDOUT;
    close STDERR;
    open(STDOUT, '>', \$stdout) or die "redirect STDOUT: $!";
    open(STDERR, '>', \$stderr) or die "redirect STDERR: $!";
    eval { $code->() };
    my $err = $@;
    open(STDOUT, '>&', $oldout) or die "restore STDOUT: $!";
    open(STDERR, '>&', $olderr) or die "restore STDERR: $!";
    return ($stdout, $stderr, $err);
}

# ========================================
# VdUtil::create_acme_domain()のテスト
# ========================================
is(
    VdUtil::create_acme_domain('example.com', 'example.com'),
    '_acme-challenge',
    'create_acme_domain: ルートドメインそのものなら _acme-challenge を返す',
);
is(
    VdUtil::create_acme_domain('example.com', 'hoge.example.com'),
    '_acme-challenge.hoge',
    'create_acme_domain: サブドメインがあれば _acme-challenge.<subdomain> を返す',
);
is(
    VdUtil::create_acme_domain('example.com', 'a.b.example.com'),
    '_acme-challenge.a.b',
    'create_acme_domain: 多段サブドメインも保持される',
);
is(
    VdUtil::create_acme_domain('example.com', 'other.jp'),
    '_acme-challenge',
    'create_acme_domain: ルートドメインに一致しないなら _acme-challenge を返す',
);

# ========================================
# VdUtil::parse_dns_response()のテスト
# ========================================
{
    my $body = '{"results":{"records":"a www 192.168.1.1","ttl":120,"ns_type":"vd"}}';
    my ($stdout, $stderr, $err) = capture(sub {
        my ($r, $t, $n) = VdUtil::parse_dns_response($body, 200);
        is($r, 'a www 192.168.1.1', 'parse_dns_response: recordsを返す');
        is($t, 120,                 'parse_dns_response: ttlを返す');
        is($n, 'vd',                'parse_dns_response: ns_typeを返す');
    });
    is($err,    '', 'parse_dns_response: 200成功時はdieしない');
    is($stdout, '', 'parse_dns_response: 200成功時は標準出力に何も書かない');
    is($stderr, '', 'parse_dns_response: 200成功時は標準エラーに何も書かない');
}
{
    my $body = '{"error":"Unauthorized"}';
    my ($stdout, $stderr, $err) = capture(sub {
        VdUtil::parse_dns_response($body, 401);
    });
    isnt($err, '',                  'parse_dns_response: 200以外ならdieする');
    like($stderr, qr/CODE:401/,     'parse_dns_response: 200以外ならSTDERRにステータスを出す');
    like($stderr, qr/Unauthorized/, 'parse_dns_response: 200以外ならSTDERRにbodyを出す');
}

# ========================================
# VdUtil::read_certbot_env()のテスト
# ========================================
{
    local $ENV{CERTBOT_DOMAIN}     = 'hoge.example.com';
    local $ENV{CERTBOT_VALIDATION} = 'validation-token';
    my ($d, $v) = VdUtil::read_certbot_env();
    is($d, 'hoge.example.com', 'read_certbot_env: CERTBOT_DOMAINを返す');
    is($v, 'validation-token', 'read_certbot_env: CERTBOT_VALIDATIONを返す');
}
{
    local %ENV = %ENV;
    delete $ENV{CERTBOT_DOMAIN};
    local $ENV{CERTBOT_VALIDATION} = 'validation-token';
    eval { VdUtil::read_certbot_env(); };
    like($@, qr/CERTBOT_DOMAIN/, 'read_certbot_env: CERTBOT_DOMAIN未設定ならdieする');
}
{
    local %ENV = %ENV;
    local $ENV{CERTBOT_DOMAIN} = 'hoge.example.com';
    delete $ENV{CERTBOT_VALIDATION};
    eval { VdUtil::read_certbot_env(); };
    like($@, qr/CERTBOT_VALIDATION/, 'read_certbot_env: CERTBOT_VALIDATION未設定ならdieする');
}

# ========================================
# VdUtil::print_program_title()のテスト
# ========================================
{
    my ($stdout, $stderr) = capture(sub {
        VdUtil::print_program_title('My Tool', '1.2.3');
    });
    like($stdout, qr/=== My Tool ===/,                  'print_program_title: タイトル行を表示する');
    like($stdout, qr/VERSION: 1\.2\.3/,                 'print_program_title: バージョン行を表示する');
    like($stdout, qr/VdDnsUtil: \Q$VdDnsUtil::VERSION\E/, 'print_program_title: VdDnsUtilのVERSIONを表示する');
    like($stdout, qr/DnsUtil: \Q$DnsUtil::VERSION\E/,     'print_program_title: DnsUtilのVERSIONを表示する');
}

# ========================================
# VdUtil::print_source_data()のテスト
# ========================================
{
    my ($stdout, $stderr) = capture(sub {
        VdUtil::print_source_data('{"results":{}}');
    });
    like($stdout, qr/=== SOURCE DATA ===/,    'print_source_data: ヘッダ行を表示する');
    like($stdout, qr/\Q{"results":{}}\E/,     'print_source_data: bodyを表示する');
}

done_testing();

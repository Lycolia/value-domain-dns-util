#
# 実行方法:
#   prove t/DnsUtil.t
#
# Test::MoreはPerlコアモジュールのため追加インストール不要
#

use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use DnsUtil;

# ========================================
# DnsUtil::dig_value()のテスト
# Net::DNS::Dig->new->for->rdataのチェーンをモックする
# ========================================
{
    no warnings 'redefine';
    local *Net::DNS::Dig::new   = sub { bless {}, shift };
    local *Net::DNS::Dig::for   = sub { $_[0] };
    local *Net::DNS::Dig::rdata = sub { ('192.168.1.1') };

    my @r = DnsUtil::dig_value('example.com', 'A');
    is_deeply([@r], ['192.168.1.1'], 'dig_value: digの結果を配列で返す');
}
{
    no warnings 'redefine';
    local *Net::DNS::Dig::new   = sub { bless {}, shift };
    local *Net::DNS::Dig::for   = sub { $_[0] };
    local *Net::DNS::Dig::rdata = sub { () };

    my @r = DnsUtil::dig_value('nonexistent.example.com', 'A');
    is_deeply([@r], [], 'dig_value: 取得結果がなければ空配列を返す');
}
{
    no warnings 'redefine';
    local *Net::DNS::Dig::new   = sub { bless {}, shift };
    local *Net::DNS::Dig::for   = sub { $_[0] };
    local *Net::DNS::Dig::rdata = sub { ('ns1.example.com.', 'ns2.example.com.') };

    my @r = DnsUtil::dig_value('example.com', 'NS');
    is_deeply([@r], ['ns1.example.com.', 'ns2.example.com.'], 'dig_value: 複数レコードを配列で返す');
}
{
    no warnings 'redefine';
    local *Net::DNS::Dig::new   = sub { bless {}, shift };
    local *Net::DNS::Dig::for   = sub { $_[0] };
    local *Net::DNS::Dig::rdata = sub { ('"acme-token"') };

    my @r = DnsUtil::dig_value('_acme-challenge.example.com', 'TXT', 'ns1.example.com');
    is_deeply([@r], ['"acme-token"'], 'dig_value: ネームサーバー指定でTXTレコードを取得できる');
}

# for()に渡されるfqdnとtypeの検証
{
    my @captured_for_args;
    no warnings 'redefine';
    local *Net::DNS::Dig::new = sub { bless {}, shift };
    local *Net::DNS::Dig::for = sub {
        my $self = shift;
        @captured_for_args = @_;
        return $self;
    };
    local *Net::DNS::Dig::rdata = sub { ('1.2.3.4') };

    DnsUtil::dig_value('example.com', 'A');
    is_deeply(\@captured_for_args, ['example.com', 'A'], 'dig_value: forにfqdnとtypeが渡される');
}

# ========================================
# DnsUtil::find_record()のテスト
# DnsUtil::dig_valueをモックしてfind_recordのロジックだけ検証する
# 試行間のsleepを発生させないため$poll_waitは0を渡す
# ========================================

# 1回目で見つかる
{
    my @responses = (['"validation-token"']);
    no warnings 'redefine';
    local *DnsUtil::dig_value = sub {
        my $r = shift @responses;
        return $r ? @$r : ();
    };

    my $found = DnsUtil::find_record(
        '_acme-challenge.example.com', 'TXT', 'validation-token',
        3, 0, 'ns1.example.com',
    );
    is($found, 1, 'find_record: 1回目で見つかれば1を返す');
}

# 全試行で見つからない
{
    my @responses = ([], [], []);
    no warnings 'redefine';
    local *DnsUtil::dig_value = sub {
        my $r = shift @responses;
        return $r ? @$r : ();
    };

    my $found = DnsUtil::find_record(
        '_acme-challenge.example.com', 'TXT', 'validation-token',
        3, 0, 'ns1.example.com',
    );
    is($found, 0, 'find_record: 試行回数を消化しても見つからなければ0を返す');
}

# 途中で見つかる
{
    my @responses = ([], [], ['"validation-token"']);
    no warnings 'redefine';
    local *DnsUtil::dig_value = sub {
        my $r = shift @responses;
        return $r ? @$r : ();
    };

    my $found = DnsUtil::find_record(
        '_acme-challenge.example.com', 'TXT', 'validation-token',
        5, 0, 'ns1.example.com',
    );
    is($found, 1, 'find_record: 途中の試行で見つかれば1を返す');
}

# 検索文字列が部分一致する
{
    my @responses = (['"prefix_validation-token_suffix"']);
    no warnings 'redefine';
    local *DnsUtil::dig_value = sub {
        my $r = shift @responses;
        return $r ? @$r : ();
    };

    my $found = DnsUtil::find_record(
        '_acme-challenge.example.com', 'TXT', 'validation-token',
        1, 0, 'ns1.example.com',
    );
    is($found, 1, 'find_record: 検索文字列が部分一致してもマッチする');
}

# 複数NSで全一致なら1
{
    my @log;
    my @responses = (
        ['"validation-token"'],   # 1st attempt: ns1 一致
        ['"validation-token"'],   # 1st attempt: ns2 一致
    );
    no warnings 'redefine';
    local *DnsUtil::dig_value = sub {
        my ($fqdn, $type, @ns) = @_;
        push @log, { ns => [@ns] };
        my $r = shift @responses;
        return $r ? @$r : ();
    };

    my $found = DnsUtil::find_record(
        '_acme-challenge.example.com', 'TXT', 'validation-token',
        3, 0,
        'ns1.example.com', 'ns2.example.com',
    );
    is($found, 1, 'find_record: 複数NSの全てで一致すれば1を返す');
    is(scalar @log, 2, 'find_record: 複数NS全一致時はNSの数だけdig_valueを呼ぶ');
    is_deeply($log[0]{ns}, ['ns1.example.com'], 'find_record: 1つ目のNSに対してdig_valueを呼ぶ');
    is_deeply($log[1]{ns}, ['ns2.example.com'], 'find_record: 2つ目のNSに対してdig_valueを呼ぶ');
}

# 1つのNSが未反映なら同試行内で打ち切り、次の試行へ
{
    my @log;
    my @responses = (
        [],                        # 1st: ns1 未反映 → 即 last
        # ns2 は問い合わせない
        ['"validation-token"'],    # 2nd: ns1 一致
        ['"validation-token"'],    # 2nd: ns2 一致
    );
    no warnings 'redefine';
    local *DnsUtil::dig_value = sub {
        my ($fqdn, $type, @ns) = @_;
        push @log, { ns => [@ns] };
        my $r = shift @responses;
        return $r ? @$r : ();
    };

    my $found = DnsUtil::find_record(
        '_acme-challenge.example.com', 'TXT', 'validation-token',
        3, 0,
        'ns1.example.com', 'ns2.example.com',
    );
    is($found, 1, 'find_record: 1つ目のNSが未反映でも次の試行で全一致すれば1を返す');
    is(scalar @log, 3, 'find_record: 同試行内の早期lastにより余分なdig_value呼び出しが起きない');
}

# 1つでも未反映なNSが残り続ければ0
{
    my @responses = (
        ['"validation-token"'], [],   # 1st: ns2 未反映
        ['"validation-token"'], [],   # 2nd: ns2 未反映
    );
    no warnings 'redefine';
    local *DnsUtil::dig_value = sub {
        my $r = shift @responses;
        return $r ? @$r : ();
    };

    my $found = DnsUtil::find_record(
        '_acme-challenge.example.com', 'TXT', 'validation-token',
        2, 0,
        'ns1.example.com', 'ns2.example.com',
    );
    is($found, 0, 'find_record: 全試行で1つでも未反映NSがあれば0を返す');
}

# ネームサーバー未指定（ローカルリゾルバ扱い）
{
    my @log;
    my @responses = (['"validation-token"']);
    no warnings 'redefine';
    local *DnsUtil::dig_value = sub {
        my ($fqdn, $type, @ns) = @_;
        push @log, { ns => [@ns] };
        my $r = shift @responses;
        return $r ? @$r : ();
    };

    my $found = DnsUtil::find_record(
        '_acme-challenge.example.com', 'TXT', 'validation-token',
        3, 0,
    );
    is($found, 1, 'find_record: ネームサーバー未指定でも検索できる');
    is_deeply($log[0]{ns}, [], 'find_record: ネームサーバー未指定時はdig_valueにNSなしで呼ぶ');
}

# 試行回数0なら問い合わせず0を返す
{
    my $called = 0;
    no warnings 'redefine';
    local *DnsUtil::dig_value = sub { $called++; return ('"validation-token"') };

    my $found = DnsUtil::find_record(
        '_acme-challenge.example.com', 'TXT', 'validation-token',
        0, 0, 'ns1.example.com',
    );
    is($found,  0, 'find_record: 試行回数が0なら0を返す');
    is($called, 0, 'find_record: 試行回数が0ならdig_valueを呼ばない');
}

done_testing();

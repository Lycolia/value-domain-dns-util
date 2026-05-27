package DnsUtil;

use strict;
use warnings;
use Net::DNS::Dig;

our $VERSION = '0.1.0';

# DNSレコードからレコードタイプに紐づく値を取得するユーティリティ関数
# 引数:
#   $fqdn        : レコードを確認するFQDN
#   $type        : レコードタイプ、A, AAAA, NS, TXTなど
#   $nameserver : ネームサーバー、空文字ならローカルリゾルバ
# 戻り値:
#   digの実行結果。レコード分の配列。レコードが取れなかった場合は空配列。
sub dig_value {
    my ($fqdn, $type, $nameserver) = @_;

    my @records = Net::DNS::Dig->new(PeerAddr => $nameserver)->for($fqdn, $type)->rdata();

    return @records;
}

# DNSレコードが全ネームサーバーに反映されたかをポーリングで確認するユーティリティ関数
# ネームサーバーごとに個別問い合わせを行い、すべてで一致した場合のみ成功とする
# 引数:
#   $fqdn          : FQDN
#   $type          : レコードタイプ、A, AAAA, NS, TXTなど
#   $search_string : 検索する文字列
#   $poll_times    : ポーリングする回数
#   $poll_wait     : ポーリングする間隔（秒）
#   @nameservers   : digに渡すネームサーバーの配列（空ならローカルリゾルバ）
# 戻り値:
#   すべてのネームサーバーに反映されたかどうか
sub find_record {
    my ($fqdn, $type, $search_string, $poll_times, $poll_wait, @nameservers) = @_;

    # ネームサーバー未指定の場合はローカルリゾルバへの一回問い合わせ扱いにする
    my @targets = @nameservers ? @nameservers : (undef);

    for (my $tries = 0; $tries < $poll_times; $tries++) {
        my $all_matched = 1;
        for my $ns (@targets) {
            my @answers = defined $ns ? dig_value($fqdn, $type, $ns) : dig_value($fqdn, $type);
            unless (grep { /\Q$search_string\E/ } @answers) {
                $all_matched = 0;
                last;
            }
        }
        return 1 if $all_matched;

        sleep($poll_wait) if $tries < $poll_times - 1;
    }

    return 0;
}

1;

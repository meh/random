# Perl script to auto leave certain channels

use Irssi;
use Irssi::TextUI;
use vars qw($VERSION %IRSSI);

$VERSION = '0.1';
%IRSSI = (
    author      => 'meh',
    contact     => 'meh@paranoici.org',
    name        => 'autoleave',
    description => 'Autoleave certain channels.',
    license     => 'AGPLv3',
);

sub leave {
    $channel = shift;

    for my $chan (split /\s+/, Irssi::settings_get_str('autoleave_channels')) {
        my ($name, $server) = split /@/, $chan;

        if ($channel->{name} eq $name && $channel->{server}->{chatnet} eq $server) {
            return 1;
        }
    }

    return 0;
}

Irssi::signal_add 'channel joined' => sub {
    $joined = shift || return 0;

    if (leave($joined)) {
        $joined->{server}->send_raw("PART $joined->{name} :" . Irssi::settings_get_str('autoleave_message'));
    }
};

Irssi::settings_add_str('autoleave', 'autoleave_channels', '');
Irssi::settings_add_str('autoleave', 'autoleave_message', 'leaving');

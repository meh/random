# Perl script to auto leave certain channels

use Irssi;
use Irssi::TextUI;
use vars qw($VERSION %IRSSI);

use Data::Dumper;

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

    print Dumper $channel;

    for my $chan (split /\s+/, Irssi::settings_get_str('autoleave_channels')) {
        $name, $server = split /@/, $chan;

        if ($channel->{name} == $name && $channel->{server}->{chatnet}) {
            return 1;
        }
    }

    return 0;
}

Irssi::signal_add 'channel joined' => sub {
    $joined = shift || return 0;

    if (leave($joined)) {
        $joined->destroy();
    }
};

Irssi::settings_add_str('autoleave', 'autoleave_channels', '');

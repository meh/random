# Automatically leave certain channels, useful for autojoins and such.

use Irssi;
use Irssi::TextUI;
use vars qw($VERSION %IRSSI);

$VERSION = '0.1';
%IRSSI = (
	author      => 'meh',
	contact     => 'meh@schizofreni.co',
	name        => 'autoleave',
	description => 'Autoleave certain channels.',
	license     => 'AGPLv3',
);

# space separated list of channel@server
Irssi::settings_add_str('autoleave', 'autoleave_channels', '');

# message to leave with
Irssi::settings_add_str('autoleave', 'autoleave_message', 'leaving');

sub has_to_leave {
	my $channel = shift;

	for my $current (split /\s+/, Irssi::settings_get_str('autoleave_channels')) {
		my ($name, $server) = split /@/, $current;

		if ($channel->{name} eq $name and (not $server or $channel->{server}->{tag} eq $server)) {
			return 1;
		}
	}

	return 0;
}

Irssi::signal_add 'channel joined' => sub {
	my $joined = shift || return 0;

	if (has_to_leave($joined)) {
		$joined->{server}->send_raw("PART $joined->{name} :" . Irssi::settings_get_str('autoleave_message'));
	}
};



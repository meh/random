# Installation
# ============
#
# To install this properly you have to and add the status bar in irssi with:
#
#    /statusbar window add connection_notice
#

use strict;
use Irssi;
use Irssi::TextUI;

use vars qw($VERSION %IRSSI);

$VERSION = '0.1';
%IRSSI   = (
	authors     => 'meh.',
	contact     => 'meh@schizofreni.co',
	name        => 'BitlBee connection notice',
	description => 'Adds an item to the status bar which shows when someone important connects.',
	license     => 'GPLv3',
	url         => 'http://github.com/meh/random/perl/irssi',
	changed     => '2012-04-24',
);

# space separated list of nicks to notice the connection of
Irssi::settings_add_str('bitlbee', 'notice_connection_of', '');

my $notice;

Irssi::signal_add_first 'message join' => sub {
	my ($server, $channel, $nick, $address) = @_;

	return unless $server->isupport('NETWORK') eq 'BitlBee';

	my @nicks = split / /, Irssi::settings_get_str('notice_connection_of');

	for my $current (@nicks) {
		if ($current eq $nick) {
			if ($notice !~ /$nick/) {
				$notice .= " $nick";
			}

			Irssi::statusbar_items_redraw('connection_notice');

			return;
		}
	}
};

Irssi::signal_add_last 'window changed' => sub {
	my $win = !Irssi::active_win() ? undef : Irssi::active_win()->{active};

	if (ref $win and $win->{server}->isupport('NETWORK') eq 'BitlBee') {
		$notice = "";
	}
	else {
		Irssi::statusbar_items_redraw('connection_notice');
	}
};

sub connection_notice {
	my ($item, $get_size_only) = @_;

	if ($notice ne "") {
		return $item->default_handler($get_size_only, "{sb Connected:$notice}", 0, 1);
	}
	else {
		return $item->default_handler($get_size_only, "", 0, 1);
	}
}

Irssi::statusbar_item_register('connection_notice', undef, 'connection_notice');
Irssi::statusbars_recreate_items();

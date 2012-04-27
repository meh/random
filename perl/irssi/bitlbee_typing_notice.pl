# Installation
# ============
#
# To install this properly you have to enable type_notice in bitlbee,
# and add the status bar in irssi with:
#
#    /statusbar window add typing_notice
#

use Irssi;
use Irssi::TextUI;
use vars qw($VERSION %IRSSI);

$VERSION = '0.1';
%IRSSI = (
	author      => 'meh',
	contact     => 'meh@paranoici.org',
	name        => 'bitlbee_typing',
	description => 'BitlBee typing support.',
	license     => 'WTFPL',
);

# send the typing notice to the current buddy
Irssi::settings_add_bool('bitlbee', 'send_typing_notice', 'true');

use constant NOT_TYPING => 0;
use constant TYPING     => 1;
use constant THINKING   => 2;

my %typing;

sub redraw {
	my ($from)  = @_;
	my $window  = Irssi::active_win();
	my $channel = $window->get_active_name();

	if ($from eq $channel) {
		Irssi::statusbar_items_redraw('typing_notice');
	}
}

sub typing {
	my ($from, $type, $no_redraw) = @_;

	if ($type == 0) {
		delete $typing{$from};
	}
	elsif ($type == 1) {
		$typing{$from} = 1;
	}
	elsif ($type == 2) {
		$typing{$from} = 2;
	}

	redraw($from) unless $no_redraw;
}

Irssi::signal_add 'ctcp msg' => sub {
	my ($server, $msg, $from, $address) = @_;

	return unless $server->isupport('NETWORK') eq 'BitlBee';

	if (my($type) = $msg =~ /TYPING ([0-9])/) {
		Irssi::signal_stop();

		typing($from, $type);
	}
};

my $last_key;

Irssi::signal_add_last 'gui key pressed' => sub {
	return unless Irssi::settings_get_bool('send_typing_notice');

	my $key = shift;

	if ($key != 9 && $key != 10 && $lastkey != 27 && $key != 27 && $lastkey != 91 && $key != 126 && $key != 127) {
		my $server = Irssi::active_server();
		my $window = Irssi::active_win();
		my $nick   = $window->get_active_name();

		return unless $server->isupport('NETWORK') eq 'BitlBee';

		my $input    = Irssi::parse_special('$L');
		my $cmdchars = Irssi::settings_get_str('cmdchars');

		if ($input !~ /^$cmdchars/ && length($input) > 0) {
			send_typing($nick);
		}
	}

	$lastkey = $key;
};

Irssi::signal_add_last 'window changed' => sub {
	Irssi::statusbar_items_redraw('typing_notice');
};

Irssi::signal_add 'message private' => sub {
	my ($server, $data, $from, $address, $target) = @_;

	return unless $server->isupport('NETWORK') eq 'BitlBee';

	typing($from, NOT_TYPING, 1);
	typing(Irssi::active_win()->get_active_name(), NOT_TYPING);
};

Irssi::signal_add 'message quit' => sub {
	my ($server, $nick) = @_;

	return unless $server->isupport('NETWORK') eq 'BitlBee';

	typing($nick, NOT_TYPING);
};

sub typing_notice {
	my ($item, $get_size_only) = @_;
	my $window                 = Irssi::active_win();
	my $channel                = $window->get_active_name();

	if (exists($typing{$channel})) {
		my $mode = $typing{$channel} == 2 ? 'thinking' : 'typing';

		$item->default_handler($get_size_only, "{sb $mode}", 0, 1);
	}
	else {
		$item->default_handler($get_size_only, '', 0, 1);
	}
}

Irssi::statusbar_item_register 'typing_notice', undef, 'typing_notice';

Irssi::statusbars_recreate_items();

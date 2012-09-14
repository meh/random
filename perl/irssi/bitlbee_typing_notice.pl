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
	contact     => 'meh@schizofreni.co',
	name        => 'bitlbee_typing',
	description => 'BitlBee typing support.',
	license     => 'WTFPL',
);

# send the typing notice to the current buddy
Irssi::settings_add_bool('bitlbee', 'send_typing_notice', 'true');

use constant NOT_TYPING => 0;
use constant TYPING     => 1;
use constant THINKING   => 2;

use constant TIMEOUT => {
	msn => 7
};

my %typing;
my %timeouts;
my %protocols;
my %querying;

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
		delete $typing->{$from};
	}
	elsif ($type == 1) {
		$typing->{$from} = 1;
	}
	elsif ($type == 2) {
		$typing->{$from} = 2;
	}

	redraw($from) unless $no_redraw;
}

Irssi::signal_add 'ctcp msg' => sub {
	my ($server, $msg, $from, $address) = @_;

	return unless $server->isupport('NETWORK') eq 'BitlBee';

	if (my ($type) = $msg =~ /TYPING ([0-9])/) {
		unless ($querying->{$from} || defined $protocols->{$address}) {
			$querying->{$from} = 1;

			$server->command("whois $from");
		}

		Irssi::signal_stop();

		typing($from, $type);

		if ($timeouts->{$from}) {
			Irssi::timeout_remove($timeouts->{$from});

			delete $timeouts->{$from};
		}

		if ($protocols->{$address} && TIMEOUT->{$protocols->{$address}}) {
			$timeouts->{$from} = Irssi::timeout_add_once(TIMEOUT->{$protocols->{$address}} * 1000, 'typing', $from);
		}
	}
};

Irssi::signal_add_first 'server event' => sub {
	my ($server, $data) = @_;

	return unless $server->isupport('NETWORK') eq 'BitlBee';

	my ($number, $nick) = $data =~ m/^(\d+) .*? (.*?) /;

	if ($querying->{$nick}) {
		Irssi::signal_stop() if $number == 301 || $number == 311 || $number == 312 || $number == 317 || $number == 318 || $number == 320;

		if ($number == 312) {
			if ($data =~ m/:(.*?) /) {
				my $protocol = $1;
				my $query    = $server->query_find($nick);
				
				if (ref $query && (my $address = $query->{address})) {
					$protocols->{$address} = $protocol;

					if (TIMEOUT->{$protocol}) {
						$timeouts->{$nick} = Irssi::timeout_add_once(TIMEOUT->{$protocol} * 1000, 'typing', $nick);
					}
				}
			}
		}

		if ($number == 318) {
			$protocols->{$address} = 0;

			delete $querying->{$nick};
		}
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

	if (exists $typing->{$channel}) {
		my $mode = $typing->{$channel} == 2 ? 'thinking' : 'typing';

		return $item->default_handler($get_size_only, "{sb $mode}", 0, 1);
	}
	else {
		return $item->default_handler($get_size_only, '', 0, 1);
	}
}

Irssi::statusbar_item_register 'typing_notice', undef, 'typing_notice';

Irssi::statusbars_recreate_items();

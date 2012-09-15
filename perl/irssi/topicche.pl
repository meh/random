# INSTALLATION
# ------------
# You need to install Text::CharWidth either from CPAN or your package manager.
#
#   /sbar topic remove topic
#   /sbar topic remove topic_empty
#   /sbar topic add -after topicbarstart -priority 0 -alignment left topicche
#

use Encode;
use Text::CharWidth qw(mbswidth mbwidth);

use Irssi;
use Irssi::UI;
use Irssi::TextUI;
use vars qw($VERSION %IRSSI);

$VERSION = '0.4';
%IRSSI = (
	author      => 'meh',
	contact     => 'meh@schizofreni.co',
	name        => 'topicche',
	description => 'Animated topic.',
	license     => 'WTFPL',
);

# the refresh rate in milliseconds
Irssi::settings_add_int('topicche', 'topicche_refresh', 150);

# the default ticks waiting before starting the rotation
Irssi::settings_add_int('topicche', 'topicche_wait', 10);

# set the theme formatters at the beginning of the topic
Irssi::settings_add_str('topicche', 'topicche_format', '');

# center the topic when it fits
Irssi::settings_add_bool('topicche', 'topicche_center', 0);

sub escape {
	my $text = shift;

	$text =~ s/%/%%/g;
	$text =~ s/\\/\\\\/g;
	$text =~ s/\$/\$\$/g;
	$text =~ s/\{/%{/g;

	return $text;
}

sub topic {
	my $topic;
	my $window = Irssi::active_win();
	
	if ($window && ($window = $window->{active})) {
		my $server;

		if ($server = $window->{server}) {
			if ($window->{type} eq 'QUERY') {
				my $query = $server->query_find($window->{name});

				$topic = "$query->{address} ($server->{tag})";
			}
			elsif ($window->{type} eq 'CHANNEL') {
				my $channel = $server->channel_find($window->{name});

				$topic = $channel->{topic};
			}
		}
	}

	unless (defined $topic) {
		$topic = 'Irssi v' . Irssi::parse_special('$J') . ' - http://www.irssi.org';
	}

	if ($topic) {
		$topic =~ s/\003((\d\d?)(,\d\d?)?)?//g;
		$topic =~ s/\001//g;
		$topic =~ s/\002//g;

		return $topic;
	}
	else {
		return '';
	}
}

my $current;
my $spacing,
my $wide;
my $wait;

sub restart {
	$current = 0;
	$spacing = -1;
	$wide    = 0;
}

sub restart_and_wait {
	restart();

	$wait = Irssi::settings_get_int('topicche_wait');
}

sub show {
	my ($item, $get_size_only) = @_;

	$item->default_handler(1, ' ' x 1024, undef);

	if ($get_size_only) {
		return;
	}

	my $topic = decode_utf8(topic());
	my $width = $item->{size} - Irssi::format_get_length(Irssi::settings_get_str('topicche_format'));

	if ($wait > 0 || mbswidth($topic) <= $width) {
		if (Irssi::settings_get_bool('topicche_center')) {
			$topic = ' ' x (($width / 2) - (mbswidth($topic) / 2)) . $topic;
		}

		$item->default_handler(0, Irssi::settings_get_str('topicche_format') . escape($topic), undef);
		$wait--;

		return;
	}

	if ($spacing == -1) {
		$spacing = $width / 2;
	}

	my $text = substr $topic, $current;

	if (mbswidth($text) == 0) {
		$text .= ' ' x $spacing . $topic;
		$spacing--;

		if ($spacing <= 0) {
			restart();
		}
	}
	elsif (mbswidth($text) < $width / 2) {
		$text .= ' ' x ($width / 2) . substr $topic, 0, $width - mbswidth($text);
		$current++;
	}
	else {
		if ($wide) {
			$wide = 0;
			$current++;
		}
		else {
			if (mbwidth($text) == 2) {
				$wide = 1;
			}
			else {
				$current++;
			}
		}
	}

	$item->default_handler(0, Irssi::settings_get_str('topicche_format') . escape($text), undef);
}

Irssi::statusbar_item_register('topicche', '$0', 'show');

sub redraw {
	Irssi::statusbar_items_redraw('topicche');
}

Irssi::signal_add 'window changed' => sub {
	restart_and_wait();
	redraw();
};

Irssi::signal_add 'channel topic changed' => sub {
	my ($channel) = @_;

	my $active = Irssi::active_win()->{active};

	if ($active->{name} eq $channel->{name} && $active->{server}->{tag} eq $channel->{server}->{tag}) {
		restart_and_wait();
		redraw();
	}
};

my $timeout;

Irssi::signal_add 'setup changed' => sub {
	if ($timeout) {
		Irssi::timeout_remove($timeout);
	}

	$timeout = Irssi::timeout_add(Irssi::settings_get_int('topicche_refresh'), 'redraw', undef);
};

$timeout = Irssi::timeout_add(Irssi::settings_get_int('topicche_refresh'), 'redraw', undef);

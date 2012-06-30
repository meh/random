use Encode;

use Irssi;
use Irssi::TextUI;
use vars qw($VERSION %IRSSI);

$VERSION = '0.1';
%IRSSI = (
	author      => 'meh',
	contact     => 'meh@paranoici.org',
	name        => 'trackbarre',
	description => 'Last read line thing.',
	license     => 'WTFPL',
);

# bool to wether put a trackbar when nothing has been said or not
Irssi::settings_add_bool('trackbarre', 'trackbarre_always', 'false');

# the char to use to draw the line
Irssi::settings_add_str('trackbarre', 'trackbarre_char', '-');

# the format string for the line
Irssi::settings_add_str('trackbarre', 'trackbarre_theme', '%K');

sub mark {
	my $window = shift;
	my $line   = $window->view->get_bookmark('trackbarre');

	if ($line) {
		$window->view->remove_line($line);
	}

	$window->print(Irssi::settings_get_str('trackbarre_theme') . decode_utf8(Irssi::settings_get_str('trackbarre_char')) x $window->{width}, MSGLEVEL_NEVER);
	$window->view->set_bookmark_bottom('trackbarre');
}

sub unmark_if_needed {
	my $window = shift;
	my $line   = $window->view->get_bookmark('trackbarre');

	if ($line && $line->{info}->{time} == $window->view->{buffer}->{cur_line}->{info}->{time}) {
		$window->view->remove_line($line);
	}
}

Irssi::signal_add 'window changed' => sub {
	my ($current, $old) = @_;

	if ($old) {
		mark($old);
	}

	if ($current && !Irssi::settings_get_bool('trackbarre_always')) {
		unmark_if_needed($current) if $current;
	}
};

Irssi::command_bind 'mark' => sub {
	mark(Irssi::active_win());
	Irssi::command('redraw');
};

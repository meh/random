use Encode;

use Irssi;
use Irssi::TextUI;
use vars qw($VERSION %IRSSI);

$VERSION = '0.2';
%IRSSI = (
	author      => 'meh',
	contact     => 'meh@schizofreni.co',
	name        => 'trackbarre',
	description => 'Last read line thing.',
	license     => 'WTFPL',
);

# bool to wether put a trackbar when nothing has been said or not
Irssi::settings_add_bool('trackbarre', 'trackbarre_always', 'false');

# the char to use to draw the line
Irssi::settings_add_str('trackbarre', 'trackbarre_separator', '-');

Irssi::theme_register([
	'trackbarre', '%K$0'
]);

sub escape {
	my $text = shift;

	$text =~ s/%/%%/g;
	$text =~ s/\\/\\\\/g;
	$text =~ s/\$/\$\$/g;
	$text =~ s/\{/%{/g;

	return $text;
}

sub mark {
	my $window = shift;
	my $width  = $window->{width};
	my $line   = $window->view->get_bookmark('trackbarre');

	if ($line) {
		$window->view->remove_line($line);
	}

	$line = decode_utf8(Irssi::settings_get_str('trackbarre_separator'));
	$line = $line x int($width / length($line));

	if (length($line) < $width) {
		$line = ' ' x (($width - length($line)) / 2) . $line;
	}

	$window->printformat(MSGLEVEL_NEVER, 'trackbarre', escape($line));
	$window->view->set_bookmark_bottom('trackbarre');
}

sub unmark {
	my $window = shift;
	my $line   = $window->view->get_bookmark('trackbarre');

	if ($line) {
		$window->view->remove_line($line);
	}
}

sub unmark_if_needed {
	my $window = shift;
	my $line   = $window->view->get_bookmark('trackbarre');

	if ($line && $line->{info}->{time} == $window->view->{buffer}->{cur_line}->{info}->{time}) {
		unmark($window);
	}
}

Irssi::signal_add 'window changed' => sub {
	my ($current, $old) = @_;

	if ($old) {
		mark($old);
	}

	if ($current && !Irssi::settings_get_bool('trackbarre_always')) {
		unmark_if_needed($current);
	}
};

Irssi::command_bind 'mark' => sub {
	if (my $window = Irssi::active_win()) {
		mark($window);
		$window->view->redraw();
	}
};

Irssi::command_bind 'unmark' => sub {
	if (my $window = Irssi::active_win()) {
		unmark($window);
		$window->view->redraw();
	}
}

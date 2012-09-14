# INSTALLATION
# ------------
#
#   /sbar window add -after more -alignment right char_count
#

use Encode;

use Irssi;
use Irssi::TextUI;
use vars qw($VERSION %IRSSI);

$VERSION = '0.1';
%IRSSI = (
	author      => 'meh',
	contact     => 'meh@schizofreni.co',
	name        => 'char_count',
	description => 'Count characters supporting UTF-8.',
	license     => 'WTFPL',
);

sub char_count {
	my ($item, $get_size_only) = @_;
	my $length = length(decode_utf8(Irssi::parse_special('$L')));

	return $item->default_handler($get_size_only, "{sbr $length}", 0, 1);
}

Irssi::signal_add_last 'gui key pressed' => sub {
	Irssi::statusbar_items_redraw('char_count')
};

Irssi::statusbar_item_register 'char_count', undef, 'char_count';
Irssi::statusbars_recreate_items();

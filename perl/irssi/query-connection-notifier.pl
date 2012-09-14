use Irssi;
use Irssi::UI;
use Irssi::TextUI;
use vars qw($VERSION %IRSSI);

$VERSION = '0.1';
%IRSSI = (
	author      => 'meh',
	contact     => 'meh@schizofreni.co',
	name        => 'Query connection notification',
	description => 'Notify in the query window when the nick connects',
	license     => 'WTFPL',
);

Irssi::theme_register([
	'connect', '{channick_hilight $0} {chanhost_hilight $1} has connected'
]);

my %quit;

Irssi::signal_add 'message join' => sub {
	my ($server, $channel, $nick, $address) = @_;

	if ($quit{"$server->{tag}:$nick"}) {
		delete $quit{"$server->{tag}:$nick"};

		foreach $query (Irssi::queries()) {
			if ($query->{server_tag} eq $server->{tag} && $query->{name} eq $nick) {
				$query->printformat(MSGLEVEL_JOINS, 'connect', $nick, $address);

				break;
			}
		}
	}
};

Irssi::signal_add 'message quit' => sub {
	my ($server, $nick, $address, $reason) = @_;

	$quit{"$server->{tag}:$nick"} = 1;
};

Irssi::signal_add 'query created' => sub {
	my ($query, $automatic) = @_;

	foreach $channel ($query->{server}->channels) {
		foreach $nick ($channel->nicks) {
			if ($nick eq $query->{name}) {
				return;
			}
		}
	}

	$quit{"$query->{server}->{tag}:$query->{name}"} = 1;
};

Irssi::signal_add 'query destroyed' => sub {
	my ($query) = @_;

	delete $quit{"$query->{server}->{tag}:$query->{name}"};
};

Irssi::signal_add 'message private' => sub {
	my ($server, $msg, $nick, $address) = @_;

	delete $quit{"$server->{tag}:$nick"};
};

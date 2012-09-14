# Perl script to output the notifications, usable with a screen backtick
# ---
# my $notifications = '';
#
# open $FILE, '<', "$ENV{HOME}/.irssi/notifications";
# my $content = <$FILE>;
#
# $content =~ s/:/@/g;
#
# for my $notification (split /, /, $content) {
#     $notifications .= "\005{= rW}$notification\005{= dd} ";
# }
#
# $notifications =~ s/ $//;
#
# if ($notifications) {
#     print "\005{= r}[\005{= W}IRC: $notifications\005{= dr}]";
# }
# ---
# You can change the colors following the usual hardstatus syntax, just replace % with \005.
#
# I suggest using http://github.com/meh/random/blob/master/c/X/vbell.c with command_on_notification

use Irssi;
use vars qw($VERSION %IRSSI);

$VERSION = '0.1';
%IRSSI = (
	author      => 'meh',
	contact     => 'meh@schizofreni.co',
	name        => 'notification',
	description => 'Persistent notification script.',
	license     => 'AGPLv3',
);

# Notify even if the highlight came from the active window
Irssi::settings_add_bool('notification', 'current_window_notification', 'false');

# Notify on every message (even not highlights) on the following wildcard matching windows
Irssi::settings_add_str('notification', 'always_notify', '');

# Notify on every message (even not highlights) on every window
Irssi::settings_add_bool('notification', 'always_notify_everything', 'false');

# Notify on every message (even not highlights) on the active window
Irssi::settings_add_bool('notification', 'always_notify_current_window', 'false');

# Ignore notifications from the wildcard matching windows
Irssi::settings_add_str('notification', 'ignore_notifications_from', '');

# Notify only the wildcard matching windows
Irssi::settings_add_str('notification', 'notify_only', '');

# Notify on connection of the following wildcard matching nick@server
Irssi::settings_add_str('notification', 'notify_connection_of', '');

# Execute this command on notification, the command line is appended with `2>&1 &`
Irssi::settings_add_str('notification', 'command_on_notification', '');

# Windows syntax is name@server so a wildcard like *@server matches every message from that server
# or nick@* matches that nick everywhere.

unlink "$ENV{'HOME'}/.irssi/notifications";

my %notify_connection_of;

sub wildcard {
	my $value = shift;

	$value =~ s/\*/.*?/;
	$value =~ s/\?/./;

	return $value;
}

sub can_notify {
	my $name   = shift || return 0;
	my $server = shift || return 0;
	my $on     = $name.'@'.$server;

	my @notify = split /\s*[:,]\s*/, Irssi::settings_get_str('notify_only');
	if ($#notify >= 0) {
		for my $expression (@notify) {
			if (eval { $on =~ /$expression/; }) {
				return 1;
			}
		}

		return 0;
	}

	my @ignores = split /\s*[:,]\s*/, Irssi::settings_get_str('ignore_notifications_from');
	if ($#ignores >= 0) {
		for my $expression (@ignores) {
			if (eval { $on =~ /$expression/; }) {
				return 0;
			}
		}
	}

	return 1;
}

sub notify {
	my $name   = shift || return 0;
	my $server = shift || return 0;
	my $clean  = shift || 0;

	if (!$clean) {
		notify($name, $server, 1);

		if (not can_notify($name, $server)) {
			return 0;
		}

		if (my $command = Irssi::settings_get_str('command_on_notification')) {
			system("$command &> /dev/null &");
		}

		open my $FILE, '>>', "$ENV{'HOME'}/.irssi/notifications";
		print $FILE "$name:$server, ";
		close $FILE;
	}
	else {
		open my $FILE, '<', "$ENV{'HOME'}/.irssi/notifications";
		my $content = <$FILE>;
		close $FILE;

		$name   = wildcard($name);
		$server = wildcard($server);

		my $tmp = $content;
		$content =~ s/\Q$name:$server\E, //;

		if ($content ne $tmp) {
			open $FILE, '>', "$ENV{'HOME'}/.irssi/notifications";
			print $FILE $content;
			close $FILE;
		}
	}

	return 1;
}

Irssi::signal_add 'print text' => sub {
	my ($dest, $text, $stripped) = @_;

	if (!Irssi::settings_get_bool('current_window_notification')) {
		my $win = !Irssi::active_win() ? undef : Irssi::active_win()->{active};

		if (ref $win && $dest->{target} eq $win->{name} && $dest->{server}->{tag} eq $win->{server}->{tag}) {
			return;
		}
	}

	if ($dest->{level} & (MSGLEVEL_HILIGHT)) {
		notify($dest->{target}, $dest->{server}->{tag});
	}
	elsif (($dest->{level} & (MSGLEVEL_MSGSMSGLEVEL_HILIGHT | MSGLEVEL_MSGS)) && ($dest->{level} & MSGLEVEL_NOHILIGHT) == 0) {
		notify($dest->{target}, $dest->{server}->{tag});
	}
};

Irssi::signal_add 'message public' => sub {
	my ($server, $msg, $nick, $address, $target) = @_;

	if (Irssi::settings_get_bool('always_notify_everything')) {
		notify($target, $server->{tag});

		return;
	}

	if (Irssi::settings_get_bool('always_notify_current_window')) {
		my $win = !Irssi::active_win() ? undef : Irssi::active_win()->{active};

		unless (ref $win && $target eq $win->{name} && $server->{tag} eq $win->{server}->{tag}) {
			return;
		}

		notify($target, $server->{tag});

		return;
	}

	if (Irssi::settings_get_str('always_notify')) {
		for my $expression (split /\s*[:,]\s*/, Irssi::settings_get_str('always_notify')) {
			if (eval { ($target.'@'.$server->{tag}) =~ /$expression/; }) {
				notify($target, $server->{tag});

				return;
			}
		}
	}
};

Irssi::signal_add_first 'message join' => sub {
	my ($server, $channel, $nick, $address) = @_;

	if ($notify_connection_of{$nick.'@'.$server->{tag}}) {
		notify($channel, $server->{tag});
		delete $notify_connection_of{$nick.'@'.$server->{tag}};

		return;
	}

	for my $expression (split /\s*[:,]\s*/, Irssi::settings_get_str('notify_connection_of')) {
		if (eval { ($nick.'@'.$server->{tag}) =~ /$expression/; }) {
			notify($channel, $server->{tag});

			return;
		}
	}
};

Irssi::signal_add 'send text' => sub {
	my ($text, $server, $window) = @_;

	if ($window->{name}) {
		notify($window->{name}, $window->{server}->{tag}, 1);
	}
};

Irssi::signal_add 'window changed' => sub {
	my ($current, $old) = @_;

	if ($current->{active}->{name}) {
		notify($current->{active}->{name}, $current->{active}->{server}->{tag}, 1);
	}
};

Irssi::signal_add 'server quit' => sub {
	my ($server, $message) = @_;

	notify('*', $server->{tag}, 1);
};

Irssi::signal_add 'gui exit' => sub {
	unlink("$ENV{'HOME'}/.irssi/notifications");
};

Irssi::command_bind 'clear_notifications' => sub {
	unlink("$ENV{'HOME'}/.irssi/notifications");
};

Irssi::command_bind 'notify_connection' => sub {
	my $match = shift;

	$notify_connection_of{$match} = 1;
};

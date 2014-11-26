#------------------------------------------------------------------------
# intruder            by otaku
#------------------------------------------------------------------------
#  Plays a WAV sound file when someone tries to connect
# to your account.
#------------------------------------------------------------------------
#  This plugin needs the Win32::Sound module on Perl
#  You can get it by typing this on the command prompt:
#
#      ppm install Win32::Sound
#
#  Or:
#
#      cpan install Win32::Sound
#------------------------------------------------------------------------
#  Licensed under the GNU General Public License v2.0
#------------------------------------------------------------------------
package intruder;

use strict;
use Win32::Sound;

Plugins::register('intruder', 'makes sure you notice when someone logs into your account', \&onUnload);
my $hook = Plugins::addHook('packet/errors', \&checkIntruder);

sub onUnload {
	Plugins::delHook($hook);
}

sub checkIntruder {
	my ($self, $args) = @_;
	if ($args->{type} == 2) {
		Win32::Sound::Volume("100%");
		Win32::Sound::Play("plugins/intruder/sound.wav",SND_ASYNC | SND_LOOP);
	}
}

1;
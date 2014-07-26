#------------------------------------------------------------------------
# pinBreaker            by otaku
#------------------------------------------------------------------------
#
#  Bruteforce plugin. Tries all possible combinations of pin codes
# until it finds the right one. It may take several minutes.
#
#  Set this line in control/config.txt as:
#
#  	loginPinCode 0000
#
#------------------------------------------------------------------------
#  Licensed under the GNU General Public License v2.0
#------------------------------------------------------------------------

package pinBreaker;

use strict;
use warnings;
use Globals qw($messageSender %config);
use Misc qw(configModify);
use Log qw(warning);

Plugins::register("pinBreaker","crack pin code using bruteforce",\&onUnload);

my $hooks = Plugins::addHooks(["packet_pre/login_pin_code_request",\&check]);

sub onUnload {
	Plugins::delHooks($hooks);
}

sub check {
	my ($self, $args) = @_;
	if ($args->{flag} != 0 && $args->{flag} != 1) {
		generateNewPin();
		$messageSender->sendLoginPinCode($args->{seed}, 0);		
		$args->{flag} = 10;
	}
}

sub generateNewPin {
	my $pin;
	my $pin_str;
	my $num = 0;

	while(1) {
		$num++;
		$pin = (int $config{loginPinCode}) + $num;
		$pin_str = sprintf("%04d",$pin);
		if ($pin_str =~ /(\d)(\d)(\d)(\d)/) {
			next if ($1 == $2 && $2 == $3 && $3 == $4); # Invalid PIN
			next if (($1 + 1) == $2 && ($2 + 1) == $3 && ($3 + 1) == $4); # Invalid PIN
			next if (($1 - 1) == $2 && ($2 - 1) == $3 && ($3 - 1) == $4); # Invalid PIN
			configModify('loginPinCode',sprintf("%04d",$pin),silent => 1);			
			return;
		}		
	}
}
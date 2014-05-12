####################################
# yggdrasilLeaf      by otaku
#---------------------------------------------------------------------
# Licensed under the GNU General Public License v2.0
# License: http://www.gnu.org/licenses/gpl-2.0.htm
####################################

#-------------------------------------------------------------------------------------------------------------
# INSTRUCTIONS
#-------------------------------------------------------------------------------------------------------------
#  This plugin will only work if the dead party member is on the screen, kore won't walk
# to a dead target on the map. So if the party member dies outside kore's view, this
# plugin won't work. YOU CAN get around with the bus system, so you can make your
# bots not run too far from each other.
#
#  You need to modify 'ai_dead_respawn' value on target's control/timeouts.txt (assuming
# your target player is another bot), kore will wait a given number of seconds before
# returning to the spawn point once it dies. The default value is 4 seconds, but you need
# to raise it, because there's a cast time for the Yggdrasil Leaf (and you need to look out
# for the lag). So it's wise to set this for 60 seconds or so.
#-------------------------------------------------------------------------------------------------------------

package yggdrasilLeaf;

use strict;
use Plugins;
use Commands;
use Globals;
use Utils;
use Log qw(message error);

Plugins::register('yggdrasilLeaf','resurrect dead party member with an yggdrasil leaf',\&unload);

my $hook = Plugins::addHooks(['packet/party_hp_info',\&checkPlayer]); 

sub unload {
	Plugins::delHooks($hook);
}

sub checkPlayer {
	my ($self,$args) = @_;
	my $target = Actor::get($args->{ID});

	return unless $args->{hp} <= 1;

	message "[yggdrasilLeaf] ". $target->{name} ." is dead.\n";	
	my $ygg = $char->inventory()->getByNameID(610);
	
	if ($ygg) {
		message "[yggdrasilLeaf] Attempting to resurrect ". $target->{name} ."...\n";
		$ygg->use();
		$messageSender->sendSkillUse(54,1,$args->{ID});
	} else {
		error "[yggdrasilLeaf] You don't have an Yggdrasil Leaf in your inventory!\n";
	}

}

1;
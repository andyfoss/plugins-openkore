# dcOnGetItem       by otaku
# Licensed under the GNU General Public License v2.0 
#-----------------------------------------------------------
# Disconnects Openkore once you looted the items you wanted.
# Add these lines to your control/config.txt file:
#
#  dcOnGetItem_name <item name>
#  dcOnGetItem_amount <amount>
#
# Example, if you wanted kore to disconnect once it looted
# 15 Jellopy:
#
#  dcOnGetItem_name Jellopy
#  dcOnGetItem_amount 15
#-----------------------------------------------------------
package dcOnGetItem;
use strict;
use Globals;
use Log qw(warning);
use Misc qw(quit);

Plugins::register('dcOnGetItem','disconnects once you acquire the items you wanted to loot', \&onUnload);
my $hooks = Plugins::addHooks(['packet/inventory_item_added', \&checkItem]);

sub onUnload {
	Plugins::delHooks($hooks);
}

sub checkItem {
	my ($self, $args) = @_;
	my $item = $items_lut{$args->{nameID}}; # Get the name of the item
	
	if ($item eq $config{dcOnGetItem_name}) {
		if ($char->inventory->sumByName($item) >= $config{dcOnGetItem_amount}) {
			warning "[dcOnGetItem] You've reached the quota of ". $config{dcOnGetItem_amount} ." ". $config{dcOnGetItem_name}."\n";
			quit();
		}
	}
}

1;
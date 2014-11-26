#------------------------------------------------------------------------
# blackjack            by otaku
#------------------------------------------------------------------------
#  A simple Blackjack card game simulation
#------------------------------------------------------------------------
#  Licensed under the GNU General Public License v2.0
#------------------------------------------------------------------------
package blackjack;

use strict;
use encoding 'utf8';

Plugins::register('blackjack','a simple blackjack game',\&onUnload);
my $hooks = Plugins::addHooks(['packet/private_message',\&pmReceived]);
my $cmds = Commands::register(['advertise','make a quick advertise so we can find players',\&dealerAds]);

sub onUnload { 
	Plugins::delHooks($hooks);
	Commands::unregister($cmds);
}

# Global variables
my $inGame = 0;
my $player_name;
my @cards;
my @player_hand;
my @dealer_hand;
my $player_hold = 0;
my $dealer_hold = 0;
my $player_turn = 1;
my $round = 0;


# When there's no bet going on
sub dealerAds {
	# Let's look for someone to play with:
	Commands::run("c ================== Blackjack (21) ================== ");
	Commands::run("c Olá, que tal uma partida de blackjack pra animar o dia? ");
	Commands::run("c Envie uma PM com a palavra \"jogar\" para iniciar um novo jogo.");
	Commands::run("c Envie uma PM com \"regras\" para saber as regras do jogo.");
	Commands::run("c ==================================================== ");
}

# Treat the received PM by case:
sub pmReceived {
	my ($self, $args) = @_;
	
	# Game session commands:
	if ($inGame && $args->{privMsgUser} eq $player_name) {
		if ($args->{privMsg} eq 'hit') {
			$args->{action} = 'hit';
			game($args);
		}
		if ($args->{privMsg} eq 'hold') {
			$args->{action} = 'hold';
			game($args);
		}
	}	
	# Start a new game session:
	if (!$inGame && $args->{privMsg} eq 'jogar') {
		$args->{action} = 'start';
		$player_name = $args->{privMsgUser};
		$inGame = 1;
		game($args);
	}	
	# Check the rules
	if ($args->{privMsg} eq 'regras') {
		gameRules($args);
	}
	# Warn someone that we're already in a game:
	if ($inGame && $args->{privMsg} eq 'jogar') {
		Commands::run("pm \"".$args->{privMsgUser}."\" Estou nesse momento em uma partida com $player_name");
		Commands::run("pm \"".$args->{privMsgUser}."\" Tente novamente em alguns instantes");
	}
}

sub gameRules {
	my $args = shift;
	my $pmHeader = "pm \"". $args->{privMsgUser} ."\" ";
	Commands::run($pmHeader."========================= REGRAS =========================");
	Commands::run($pmHeader."As regras do Blackjack (conhecido como 21) são bem simples");
	Commands::run($pmHeader."Existe um baralho de 52 cartas, sendo 13 de cada um dos 4 naipes");
	Commands::run($pmHeader."Você (jogador) e eu (dealer) começamos com 2 cartas cada um");
	Commands::run($pmHeader."E podemos escolher hit pra pegar outra ou hold pra segurar a mão");
	Commands::run($pmHeader."O objetivo é juntar 21 pontos ou o mais próximo disso possível");
	Commands::run($pmHeader."A mão que ultrapassar 21 pontos acaba perdendo, então não hesite de usar hold!");
	Commands::run($pmHeader."A pontuação é a seguinte: ");
	Commands::run($pmHeader."'J', 'Q' e 'K' valem 10 pontos");
	Commands::run($pmHeader."'A' é um valor coringa. Ele pode valer 1 ou 11 pontos. Se adapta à sua mão.");
	Commands::run($pmHeader."O resto das cartas é o valor descrito nelas. Ex: 5 de Copas vale 5 pontos");
	Commands::run($pmHeader."------------------ Boa sorte!!! ------------------");	
}

# Return the deck to the initial state (full):
sub populateCards {
	@cards = (
		# Hearts
		'2-1', '3-1', '4-1', '5-1', '6-1', '7-1', '8-1', '9-1', '10-1', 'J-1', 'Q-1', 'K-1', 'A-1',
		# Spades
		'2-2', '3-2', '4-2', '5-2', '6-2', '7-2', '8-2', '9-2', '10-2', 'J-2', 'Q-2', 'K-2', 'A-2',
		# Diamonds
		'2-3', '3-3', '4-3', '5-3', '6-3', '7-3', '8-3', '9-3', '10-3', 'J-3', 'Q-3', 'K-3', 'A-3',
		# Clubs
		'2-4', '3-4', '4-4', '5-4', '6-4', '7-4', '8-4', '9-4', '10-4', 'J-4', 'Q-4', 'K-4', 'A-4'
	);
	
	# Shuffle the deck
	for (my $i = 0; $i < @cards; $i++) {
		my $index = int(rand(@cards));
		my $temp = $cards[$i];
		$cards[$i] = $cards[$index];
		$cards[$index] = $temp;
	}
}

# This is the "main" function per say. 
# This is where the state of the game is being changed and verified
sub game {
	my $args = shift;	
	$round++;	
	my $pmHeader = "pm \"". $args->{privMsgUser} ."\" Round ". $round ." - ";
	
	# A new game
	if ($args->{action} eq 'start') {
		# Restore our deck:
		populateCards();
		
		# Deal the cards:
		my $p_card1 = pop(@cards);
		my $p_card2 = pop(@cards);
		my $d_card1 = pop(@cards);
		my $d_card2 = pop(@cards);
		
		@player_hand = ($p_card1,$p_card2);
		@dealer_hand = ($d_card1,$d_card2);
		
		# Present the results to the player:
		Commands::run($pmHeader."Suas cartas são ".printCard($p_card1)." e ".printCard($p_card2).", total de ".score(@player_hand)." pontos!");
		Commands::run($pmHeader."Uma de minhas cartas é ". printCard($d_card1) ."!");		
		# Ask for the next step of the player:
		Commands::run($pmHeader."Envie uma PM com \"hit\" para receber mais uma carta");
		Commands::run($pmHeader."Envie uma PM com \"hold\" para apostar na sua mão atual");
	}
	
	# The player chose to get another card
	if ($args->{action} eq 'hit') {
		my $p_card = pop(@cards);
		push(@player_hand,$p_card);
		Commands::run($pmHeader."Você escolheu hit, sua nova carta é: ".printCard($p_card).".");
		Commands::run($pmHeader."Sua pontuação passa a ser: ".score(@player_hand).".");
		if (score(@player_hand) < 21) {
			Commands::run($pmHeader."Envie uma PM com \"hit\" para receber mais uma carta");
			Commands::run($pmHeader."Envie uma PM com \"hold\" para apostar na sua mão atual");
		}
		$player_turn = 0;
	}
	
	# The player chose to hold this hand for this game
	if ($args->{action} eq 'hold') {
		Commands::run($pmHeader."Você escolheu hold. Sua pontuação é de ". score(@player_hand) ." pontos!");
		$player_hold = 1;
		$player_turn = 0;
	}
	
	# The dealer hits for another card
	if ($args->{action} eq 'hit-dealer') {
		Commands::run($pmHeader."Eu escolhi hit, acho que estou com sorte.");
		push(@dealer_hand,pop(@cards));
		checkGame($args);
	}
	
	# The dealer decides to hold this hand for this game
	if ($args->{action} eq 'hold-dealer') {
		Commands::run($pmHeader."Eu escolhi hold, gostei da minha mão atual.");
		$dealer_hold = 1;
	}
	
	$args->{action} = ""; # The lack of this line made my PC scream in pain...
	dealerAction($args) if (!$player_turn && !$dealer_hold);
	checkGame($args);
}

# The decision the dealer makes in a round.
sub dealerAction {
	my $args = shift;
	if (score(@dealer_hand) < 16) {
		$player_turn = 1 unless ($player_hold);
		# There's 85% chance that he'll hit when his hand is under 16
		if (int(rand(100)) > 15) {
			$args->{action} = 'hit-dealer';
		} else {
			$args->{action} = 'hold-dealer';
		}
		game($args);
	} else {
		$player_turn = 1 unless ($player_hold);;
		# There's 85% chance that he'll hold when his hand is greater or equal to 16
		if (int(rand(100)) > 15) {
			$args->{action} = 'hold-dealer';
		} else {
			$args->{action} = 'hit-dealer';
		}
		game($args);
	}
}

# Check the game state for winners
sub checkGame {
	my $args = shift;
	return unless($inGame);
	my $pmHeader = "pm \"". $args->{privMsgUser} ."\" ";
		
	# Both the dealer and player chose hold
	if ($player_hold && $dealer_hold && score(@player_hand) <= 21 && score(@dealer_hand) <= 21) {
		Commands::run($pmHeader."Minhas cartas são: ". printHand(@dealer_hand));
		Commands::run($pmHeader."Minha pontuação total foi ". score(@dealer_hand) ." pontos.");
		Commands::run($pmHeader."Suas cartas são: ". printHand(@player_hand));
		Commands::run($pmHeader."Sua pontuação total foi ". score(@player_hand) ." pontos.");
		
		if (score(@player_hand) > score(@dealer_hand)) {
			Commands::run($pmHeader."VOCÊ VENCEU!");
			endGame();
			return;
		} elsif (score(@player_hand) == score(@dealer_hand)) {
			Commands::run($pmHeader."A PARTIDA TERMINOU EM UM EMPATE!");
			endGame();
			return;
		} else {
			Commands::run($pmHeader."VOCÊ PERDEU!");
			endGame();
			return;
		}
	}
	
	# Blackjack
	if (score(@player_hand) == 21) {
		Commands::run($pmHeader."Suas cartas são: ". printHand(@player_hand));
		Commands::run($pmHeader."Sua pontuação foi 21 pontos! BLACKJACK!");
		Commands::run($pmHeader."VOCÊ VENCEU!");
		endGame();
		return;
	}
	if (score(@dealer_hand) == 21) {
		Commands::run($pmHeader."Minhas cartas são: ". printHand(@dealer_hand));
		Commands::run($pmHeader."Minha pontuação foi 21 pontos! BLACKJACK!");
		Commands::run($pmHeader."VOCÊ PERDEU!");
		endGame();
		return;
	}	
	
	# Over the 21 points
	if (score(@player_hand) > 21) {
		Commands::run($pmHeader."Suas cartas são: ". printHand(@player_hand));
		Commands::run($pmHeader."Sua pontuação foi ". score(@player_hand) .", excedendo 21 pontos!");
		Commands::run($pmHeader."VOCÊ PERDEU!");
		endGame();
		return;
	}
	if (score(@dealer_hand) > 21) {
		Commands::run($pmHeader."Minhas cartas são: ". printHand(@dealer_hand));
		Commands::run($pmHeader."Minha pontuação foi ". score(@dealer_hand) .", excedendo 21 pontos!");
		Commands::run($pmHeader."VOCÊ VENCEU!");
		endGame();
		return;
	}
}

# End of the game procedure:
sub endGame {
	$inGame = 0;
	$player_name = "";
	@player_hand = ();
	@dealer_hand = ();
	$player_hold = 0;
	$dealer_hold = 0;
	$player_turn = 1;
	$round = 0;
}

# Print the card in an human-friendly way:
sub printCard {
	my $card = shift;
	if ($card =~ /^(.*)-1$/) {
		return $1 . " de Copas";
	}
	if ($card =~ /^(.*)-2$/) {
		return $1 . " de Espadas";
	}
	if ($card =~ /^(.*)-3$/) {
		return $1 . " de Ouros";
	}
	if ($card =~ /^(.*)-4$/) {
		return $1 . " de Paus";
	}
	return "<Valor Incorreto!>";
}

# Print the hand in an human-friendly way:
sub printHand {
	my @hand = @_;
	my $list = "";
	foreach (@hand) {
		$list .= " ".printCard($_).",";
	}
	chop($list);
	return $list;
}

# Calculate the score of a hand:
sub score {
	my @hand = @_;
	my $score = 0;
	my $hasAce = 0;
	
	foreach my $h (@hand) {
		if ($h =~ /^J-/ || $h =~ /^Q-/ || $h =~ /^K-/) {
			$score += 10;
		} elsif ($h =~ /^A-/) {
			$hasAce++;
		} elsif ($h =~ /^(.*)-/) {
			$score += int($1);
		}
	}
	
	# Ace can either be 11 or 1: (and we can have multiple aces in a hand)
	while ($hasAce) {
		if (($score + 11) <= 21) {
			$score += 11;
		} else {
			$score++;
		}
		$hasAce--;
	}
	
	return int($score);
}

1;

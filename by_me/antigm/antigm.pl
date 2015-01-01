# AntiGM        
# Author: otaku
# License: GNU GPL v3
#
# OVERVIEW
#
# This is a plugin to avoid some common GM tests on the bRO server.
# Sometimes the GM will talk to you through the system chat, sometimes through PMs
# and sometimes he'll just speak through the public chat.
# It identifies the GM and disconnects if he is talking to you.
#
# * On the system chat it checks for your name on the message (as it happens on tests)
#
# CONFIG
#
# You must add to your control/config.txt de lines:
# 
#		antigm_relog <seconds>
#		antigm_warning <boolean>
#		antigm_reaction <option>
#		antigm_alarm <boolean>
#
# DETAILS
#
#   antigm_relog: It will relog for <seconds> seconds if Openkore identifies the GM.
#   If the value of <seconds> is 0 or less, then Openkore will quit instead of relog.
#
#   antigm_warning: If the value is 1, the bot will try to warn the other bots through
#   the bus system.
#
#   antigm_reaction: This is the reaction the bot will take when another bot sends it
#   a bus message with a GM warning. The values of <option> can be:
#			0 (It won't react to the message)
#			1 (It reacts to the message ONLY if the GM is in the same map as him)
#			2 (It reacts to the message regardless of the map)
#
#		antigm_alarm: If set to 1 triggers an alarm sound when Openkore detects a GM. 
package AntiGM;

use strict;
use warnings;
use encoding "utf8";
use Log qw(warning message error);
use Globals qw($char $bus $field %config @servers);
use Misc qw(relog quit);
use Utils::Win32;

Plugins::register('AntiGM','driblar os GMs do jogo',\&onUnload);

my $hooks = Plugins::addHooks(
	['packet/system_chat',\&handleSystemChat],
	['packet/public_chat',\&handlePublicChat],
	['packet/private_message',\&handlePrivateMessage],
	['initialized',\&setCallback]
);

my $debug_cmd = Commands::register(['antigm_emular','emula o avistamento de um GM',\&GMfound]);

sub setCallback {
	return unless $config{'antigm_warning'};
	if ($bus) {
		warning "[AntiGM] Registrando callback: handleBusMessage\n";
		$bus->onMessageReceived->add(undef, \&handleBusMessage);
	} else {
		error "[AntiGM] Bus está desativado!\n";
		error "[AntiGM] Não será possível enviar/receber mensagens para outros bots.\n";
	}
}

sub onUnload {
	Plugins::delHooks($hooks);
	Commands::unregister($debug_cmd);
}

sub handleSystemChat {
	my $message = $_[1]->{message};
	my $name = $char->{name};
	if ($message =~ /$name/) {
		warning "[AntiGM] Situação suspeita encontrada.\n";
		GMfound('Meu nome apareceu na mensagem do sistema');
	}
}

sub handlePublicChat {
	my $message = $_[1]->{message};
	if ($message =~ /^(\[GM\]|\[GE\]|\[LU\])/) {
		warning "[AntiGM] Situação suspeita encontrada.\n";
		GMfound('O GM disse alguma coisa no chat publico');
	}
}

sub handlePrivateMessage {
	my $nick = $_[1]->{privMsgUser};
	if ($nick =~ /^(\[GM\]|\[GE\]|\[LU\])/) {
		warning "[AntiGM] Situação suspeita encontrada.\n";
		GMfound('O GM me mandou uma PM');
	}
}

sub handleBusMessage {
	my $msg = $_[2];
	if ($msg->{messageID} eq 'antigm' && $msg->{args}{server} eq $servers[$config{server}]{name}) {		
		if ($config{antigm_reaction} == 2) {
			warning "[AntiGM] ".$msg->{args}{bot_name}." me avisou que há GMs online.\n";
			GMreaction('Avisado através do Bus pelo o bot'. $msg->{args}{bot_name});
			return;
		}
		if ($config{antigm_reaction} == 1 && $msg->{args}{map_name} eq $field->baseName()) {
			warning "[AntiGM] ".$msg->{args}{bot_name}." me avisou que há GMs nesse mapa.\n";
			GMreaction('Avisado através do Bus pelo o bot'. $msg->{args}{bot_name});
			return;
		} 
		warning "[AntiGM] ".$msg->{args}{bot_name}." avistou um GM em ". $msg->{args}{map_name} ." no servidor ". $msg->{args}{server} ."\n";
	}
}

sub GMfound {
	my $reason = shift;
	open(FH,'>>:utf8',$Settings::logs_folder.'/antigm_log.txt');
	print FH "================================================================\n";
	print FH "Conta: ". $config{username} ."\n";
	print FH "Personagem: ". $char->{name} ."\n";
	print FH "Mapa: ". $field->baseName() ."\t\tData: ". timeFormat() ."\n";
	print FH "Motivo: ". $reason ." chat\n";
	close(FH);
	
	# Warn other bots through the bus system
	if ($config{'antigm_warning'}) {
		if (!$bus) {
			error "[AntiGM] Não foi possível avisar os outros bots.\n";
			error "[AntiGM] O bus está desativado.\n";
		} else {
			warning "[AntiGM] Enviando informação para o bus para avisar outros bots.\n";
			$bus->send('antigm', { 
				map_name => $field->baseName(),
				server => $servers[$config{server}]{name},
				bot_name => $char->{name}
			});
		}
	}
	
	if ($config{antigm_alarm}) {
		my $filepath;
		$filepath = "plugins/antigm.wav" if (-e "plugins/antigm.wav");
		$filepath = "plugins/antigm/antigm.wav" if (-e "plugins/antigm/antigm.wav");
		if ($filepath) {
			Utils::Win32::playSound($filepath);
		} else {
			error "[AntiGM] Sound file not found!\n";
		}
	}
	
	GMreaction();	
}

sub GMreaction {
	if ($config{antigm_relog} > 0) {
		relog($config{antigm_relog});
	} else {
		quit();
	}
}

sub timeFormat {
  my ($seg,$min,$hora,$dia,$mes,$ano,$resto) = localtime();
  return sprintf("%02d/%02d/%04d %02d:%02d:%02d",$dia,$mes+1,$ano+1900,$hora,$min,$seg);
}

1;
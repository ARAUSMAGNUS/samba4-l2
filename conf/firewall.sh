#!/bin/sh
# Modificado por: Robson Vaamonde
# Site: www.procedimentosemti.com.br
# Facebook: facebook.com/ProcedimentosEmTI
# Facebook: facebook.com/BoraParaPratica
# YouTube: youtube.com/BoraParaPratica
# Data de cria��o: 31/05/2016
# Data de atualiza��o: 30/07/2016
# Vers�o: 0.4
# Testado e homologado para a vers�o do Ubuntu Server 16.04 LTS x64
# Kernel >= 4.4.x
#
# Configura��o do Firewall atrav�s do iptables
# Autoria do Script
# Site: https://www.vivaolinux.com.br/artigo/Script-de-firewall-completissimo?pagina=1
#
# "::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
# "| Script de Firewall - IPTABLES"
# "| Criado por: Marcelo Magno"
# "| Contribuindo por: Josemar, Marcelo, Urubatan Neto e todos os"
# "| membros da comunidade viva o linux"
# "| T�cnico em Inform�tica"
# "| marcelo.espindola@gmail.com"
# "| Uso: firewall start|stop|restart"
# "::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"

#Declara��o de variaveis
PATH=/sbin:/bin:/usr/sbin:/usr/bin
IPTABLES="/sbin/iptables"
PROGRAMA="/etc/init.d/firewall.sh"

#lista de MAC liberados
MACLIST="/etc/configuracao_personalizada/macsliberadosfirewall"

#portas liberadas e bloqueadas
PORTSLIB="/etc/configuracao_personalizada/portslib"
PORTSBLO="/etc/configuracao_personalizada/portsblo"

#Interfaces de Rede
LAN=eth1
WAN=eth0
REDE="192.168.1.0/24"

#lista de sites negados e redirecionamento
SITESNEGADOS="/etc/configuracao_personalizada/sitesnegados"
REDILIST="/etc/configuracao_personalizada/listaderedirecionamento"

#diversos m�dulos do iptables s�o chamdos atrav�s do modprobe
modprobe ip_tables
modprobe iptable_nat
modprobe ip_conntrack
modprobe ip_conntrack_ftp
modprobe ip_nat_ftp
modprobe ipt_LOG
modprobe ipt_REJECT
modprobe ipt_MASQUERADE
modprobe ipt_state
modprobe ipt_multiport
modprobe iptable_mangle
modprobe ipt_tos
modprobe ipt_limit
modprobe ipt_mark
modprobe ipt_MARK

case "$1" in
start)

#mensagem de inicializa��o
echo "::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
echo "| Script de Firewall - IPTABLES"
echo "| Criado por: Marcelo Magno"
echo "| Contribuindo por: Josemar, Marcelo, Urubatan Neto e todos os"
echo "| membros da comunidade viva o linux"
echo "| T�cnico em Inform�tica"
echo "| marcelo.espindola@gmail.com"
echo "| Uso: firewall start|stop|restart"
echo "::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
echo 
echo "=========================================================|"
echo "|:INICIANDO A CONFIGURA��O DO FIREWALL NETFILTER ATRAV�S:|"
echo "|:                    DO IPTABLES                       :|"
echo "=========================================================|"

#limpando todas as regras das tabelas do iptables
$IPTABLES -F
$IPTABLES -F INPUT
$IPTABLES -F OUTPUT
$IPTABLES -F FORWARD
$IPTABLES -t mangle -F
$IPTABLES -t nat -F
$IPTABLES -X
echo "limpeza das tabelas do iptables"
echo "ON .................................................[ OK ]"

#zerando os contadores das cadeias ###
$IPTABLES -t nat -Z
$IPTABLES -t mangle -Z
$IPTABLES -t filter -Z
echo "zerando os contadores das cadeiras"
echo "ON .................................................[ OK ]"

#setando as pol�ticas padr�o das tabelas do iptables
$IPTABLES -P INPUT DROP
$IPTABLES -P OUTPUT ACCEPT
$IPTABLES -P FORWARD DROP
echo "setando as pol�ticas padr�o das tabelas do iptables"
echo "ON .................................................[ OK ]"

#ativar o redirecionamento no arquivo ip_forward
echo "1" > /proc/sys/net/ipv4/ip_forward
echo "ativado o redirecionamento no arquivo ip_forward"
echo "ON .................................................[ OK ]"

#habilitando o fluxo interno entre os processos
$IPTABLES -I INPUT -i lo -j ACCEPT
$IPTABLES -I OUTPUT -o lo -j ACCEPT
echo "ativado o fluxo interno entre os processos"
echo "ON .................................................[ OK ]"

#liberar as portas principais do servidor
for i in `cat $PORTSLIB`; do
	$IPTABLES -A INPUT -p tcp --dport $i -j ACCEPT
	$IPTABLES -A FORWARD -p tcp --dport $i -j ACCEPT
	$IPTABLES -A OUTPUT -p tcp --sport $i -j ACCEPT
done
	$IPTABLES -I INPUT -m state --state ESTABLISHED -j ACCEPT
	$IPTABLES -I INPUT -m state --state RELATED -j ACCEPT
	$IPTABLES -I OUTPUT -p icmp -o $WAN -j ACCEPT
	$IPTABLES -I INPUT -p icmp -j ACCEPT
echo "ativado as portas abertas para estabelecer conex�es"
echo "ativado a libera��o das portas principais do servidor $HOSTNAME"
echo "ON .................................................[ OK ]"

#bloquear acesso de sites negados a rede interna
for i in `cat $SITESNEGADOS`; do
	$IPTABLES -t filter -A FORWARD -s $REDE -d $i -j DROP
	$IPTABLES -t filter -A FORWARD -s $i -d $REDE -j DROP
	$IPTABLES -t filter -A INPUT -s $i  -j DROP
	$IPTABLES -t filter -A OUTPUT -d $i -j DROP
done
echo "ativado o bloqueio de envio de pacotes com origem aos sites negados"
echo "ON .................................................[ OK ]"

#Bloqueio ping da morte
echo "0" > /proc/sys/net/ipv4/icmp_echo_ignore_all
$IPTABLES -N PING-MORTE
$IPTABLES -A INPUT -p icmp --icmp-type echo-request -j PING-MORTE
$IPTABLES -A PING-MORTE -m limit --limit 1/s --limit-burst 4 -j RETURN
$IPTABLES -A PING-MORTE -j DROP
echo "ativado o bloqueio a tentativa de ataque do tipo ping da morte"
echo "ON .................................................[ OK ]"

#bloquear ataque do tipo SYN-FLOOD
echo "0" > /proc/sys/net/ipv4/tcp_syncookies
$IPTABLES -N syn-flood
$IPTABLES -A INPUT -i $WAN -p tcp --syn -j syn-flood
$IPTABLES -A syn-flood -m limit --limit 1/s --limit-burst 4 -j RETURN
$IPTABLES -A syn-flood -j DROP
echo "ativado o bloqueio a tentativa de ataque do tipo SYN-FLOOD"
echo "ON .................................................[ OK ]"

#Bloqueio de ataque ssh de for�a bruta
$IPTABLES -N SSH-BRUT-FORCE
$IPTABLES -A INPUT -i $WAN -p tcp --dport 22 -j SSH-BRUT-FORCE
$IPTABLES -A SSH-BRUT-FORCE -m limit --limit 1/s --limit-burst 4 -j RETURN
$IPTABLES -A SSH-BRUT-FORCE -j DROP
echo "ativado o bloqueio a tentativa de ataque do tipo SSH-BRUT-FORCE"
echo "ON .................................................[ OK ]"

#Bloqueio de portas
for i in `cat $PORTSBLO`; do
	$IPTABLES -A INPUT -p tcp -i $WAN --dport $i -j DROP
	$IPTABLES -A INPUT -p udp -i $WAN --dport $i -j DROP
	$IPTABLES -A FORWARD -p tcp --dport $i -j DROP
done

#bloqueio Anti-Spoofings
$IPTABLES -A INPUT -s 10.0.0.0/8 -i $WAN -j DROP
$IPTABLES -A INPUT -s 127.0.0.0/8 -i $WAN -j DROP
$IPTABLES -A INPUT -s 172.16.0.0/12 -i $WAN -j DROP
$IPTABLES -A INPUT -s 192.168.1.0/16 -i $WAN -j DROP
echo "ativado o bloqueio de tentativa de ataque do tipo Anti-spoofings"
echo "ON .................................................[ OK ]"

#Bloqueio de scanners ocultos (Shealt Scan)
$IPTABLES -A FORWARD -p tcp --tcp-flags SYN,ACK, FIN,  -m limit --limit 1/s -j ACCEPT
echo "bloqueado scanners ocultos"
echo "ON .................................................[ OK ]"

#amarrar ip ao mac
for i in `cat $MACLIST`; do
#aqui cada linha do maclist � atribu�da de cada vez

	STATUS=`echo $i | cut -d ';' -f 1`
#o comando echo exibe o conte�do da vari�vel e o pipe "|" repassa a sa�da para outro comando,
# o cut por sua vez reparte cada linha em peda�os onde o delimitador (-d) � o ';' no par�metro 
#-f imprime na tela conte�do da 1� coluna (status), a sa�da deste � enviada para STATUS;

	IPSOURCE=`echo $i | cut -d ';' -f 2`
	MACSOURCE=`echo $i | cut -d ';' -f 3`
	MARK=`echo $IPSOURCE | cut -d '.' -f 4`
# neste caso o IPSOURCE e o MACSOURCE recebem as outras colunas da mesma linha, fa�o uma 
#ressalva para o nome do computador que eu coloquei apenas para a organiza��o do maclist, 
#pois neste do script contar� at� a 3� coluna.

#aqui neste caso o comando if est� dentro do la�o for
#Se status = a ent�o iptables libera a conex�o atrav�s destes comandos constru�dos na tabela filter
if [ $STATUS = "a" ]; then
	$IPTABLES -t filter -A FORWARD -d 0/0 -s $IPSOURCE -m mac --mac-source $MACSOURCE -j ACCEPT
	$IPTABLES -t filter -A FORWARD -d $IPSOURCE -s 0/0 -j ACCEPT
	$IPTABLES -t filter -A INPUT -s $IPSOURCE -d 0/0 -m mac --mac-source $MACSOURCE -j ACCEPT
	$IPTABLES -t filter -A OUTPUT -s $IPSOURCE -d 0/0 -j ACCEPT
	$IPTABLES -t mangle -A PREROUTING -s $IPSOURCE -j MARK --set-mark $MARK

# Se for = b ent�o bloqueia o MAC, ele s� executa este comandos se STATUS n�o for igual a "a".
else #se n�o
	$IPTABLES -t filter -A FORWARD -m mac --mac-source $MACSOURCE -j DROP
	$IPTABLES -t filter -A INPUT -m mac --mac-source $MACSOURCE -j DROP
	$IPTABLES -t filter -A OUTPUT -m mac --mac-source $MACSOURCE -j DROP
fi # fim do se
done # fim do comando la�o for
echo "Ativado a amarra��o do ip ao mac"
echo "ON .................................................[ OK ]"

#proxy transparente
$IPTABLES -t nat -A PREROUTING -i $LAN -p tcp --dport 80 -j REDIRECT --to-port 3128
echo "Proxy Transparente ativado"
echo "ON .................................................[ OK ]"

# ativar o mascaramento
$IPTABLES -t nat -A POSTROUTING -o $WAN -j MASQUERADE

#carrega controlador de banda
/etc/init.d/cbq start #Para debian
echo
echo "==========================================================|"
echo "::TERMINADA A CONFIGURA��O DO FIREWALL NETFILTER ATRAV�S::|"
echo "::                  DO IPTABLES                         ::|"
echo "==========================================================|"
echo "FIREWALL ATIVADO - SISTEMA PREPARADO"
echo "SCRIPT DE FIREWALL CRIADO POR :-) MARCELO MAGNO :-)"
;;

stop)
$IPTABLES -F
$IPTABLES -F INPUT
$IPTABLES -F OUTPUT
$IPTABLES -F FORWARD
$IPTABLES -t mangle -F
$IPTABLES -t nat -F
$IPTABLES -X
$IPTABLES -Z

$IPTABLES -P INPUT ACCEPT
$IPTABLES -P OUTPUT ACCEPT
$IPTABLES -P FORWARD ACCEPT

/etc/init.d/cbq stop #Para debian
echo "FIREWALL DESCARREGADO - SISTEMA LIBERADO"
;;

restart)
$PROGRAMA stop
$PROGRAMA start
;;
*)
echo "Use: $N {start|stop|restart}" >&2
echo -e "\033[01;31mATEN��O";tput sgr0
echo "Voc� n�o colocou nenhum argumento ou algum conhecido, ent�o Por Padr�o ser� dado em 5 segundos um restart no firewall"
sleep 5
$PROGRAMA restart
exit 1
esac
exit 0
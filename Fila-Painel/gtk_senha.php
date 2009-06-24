#!/usr/bin/php
<?php
/*

Copyright 2008, 2009 - Oktiva Comércio e Serviços de Informática Ltda.

Este arquivo é parte do programa FILA - Sistema de Atendimento

O FILA é um software livre; você pode redistribui-lo e/ou modifica-lo
dentro dos termos da Licença Pública Geral GNU como publicada pela
Fundação do Software Livre (FSF); na versão 2 da Licença.

Este programa é distribuido na esperança que possa ser util, mas SEM
NENHUMA GARANTIA; sem uma garantia implicita de ADEQUAÇÂO a qualquer
MERCADO ou APLICAÇÃO EM PARTICULAR. Veja a Licença Pública Geral GNU
para maiores detalhes.

Você deve ter recebido uma cópia da Licença Pública Geral GNU, sob o
título "LICENCA.txt", junto com este programa, se não, escreva para a
Fundação do Software Livre(FSF) Inc., 51 Franklin St, Fifth Floor,
Boston, MA 02110-1301 USA

*/
global $arraytotal,$posicao,$tamanho,$lblsenha,$lblultima,$ultima_p,$ultima_n,$ultima_s;

function toca_tchuru() {
	system('/usr/bin/music123 /home/f13/KDE_Event_2.ogg');
	return false;
}

function lista_senha() {
	global $arraytotal,$posicao,$tamanho,$lblsenha,$lblultima,$ultima_p,$ultima_n,$ultima_s;
	if(sizeof($arraytotal) == 0) {
		$posicao = 0;
		$tamanho = 0;
		$tela = "";
		echo "sizeof: $tamanho\n";
	} else {
		$tela = $arraytotal[$posicao][0]." ".$arraytotal[$posicao][1];
		completa_ultimas($arraytotal[$posicao]);	
		echo "tela: $tela";
		
	}

	if($posicao == $tamanho) {
		completa_array();
		$posicao = 0;
		echo "completando array\n";
	} else {
		$posicao = $posicao+1;
		echo "incrementando posicao\n";
		echo "proxima posicao: $posicao\n";
	}
	$lblsenha->set_label($tela);
	if(trim($tela) != "") {
		Gtk::timeout_add(100, 'toca_tchuru');
	}
	$telaultima = "";	
	if($ultima_p[2] > 0) {
	  $telaultima = $telaultima.$ultima_p[1]." ".$ultima_p[2];
	}
	if($ultima_s[2] > 0) {
	  $telaultima = $telaultima.$ultima_s[1]." ".$ultima_s[2];
	}
	if($ultima_n[2] > 0) {
	  $telaultima = $telaultima.$ultima_n[1]." ".$ultima_n[2];
	}

	$lblultima->set_label($telaultima);
	
	echo "setando label\n\n\n";
	return true;
}


function completa_array(){
	global $arraytotal,$tamanho;
        $linhas = file("/fila-painel/tmp/senhas_chamando.csv");
	$arraytotal = array();
        foreach ($linhas as $linha_num => $linha) {
                $exp = explode(",",$linha);
                $senhas = $exp[0];
                $mesa = $exp[1];

		$arraytotal[] = array($senhas,$mesa);
		$tamanho = (sizeof($arraytotal)-1);
        }
        echo "li o arquivo\n";
        echo "tamanho: $tamanho\n";
	
}

function completa_ultimas($ultima) {
	global $ultima_s,$ultima_p,$ultima_n,$lblultima;
	$cat = substr($ultima[0],0,1);
	$num = substr($ultima[0],1,3);
	if($cat == "N") {
	  if($ultima_n[0] < $num) {
		$ultima_n = array($num,$ultima[0],$ultima[1]);
		echo "gravando N $num\n";
	  }
	} elseif($cat == "P") {
          if($ultima_p[0] < $num) {
                $ultima_p = array($num,$ultima[0],$ultima[1]);
		echo "gravando P $num\n";
          }
	} elseif($cat == "S") {
          if($ultima_s[0] < $num) {
                $ultima_s = array($num,$ultima[0],$ultima[1]);
		echo "gravando S $num\n";
          }
	}	
}


$glade=&new GladeXML('gtk_senha.glade');

$window    = $glade->get_widget("window1");
$titulo    = $glade->get_widget("label1");
$lblsenha  = $glade->get_widget("label2");
$ultima    = $glade->get_widget("label3");
$lblultima = $glade->get_widget("label4");

$window->connect_simple('destroy', array('Gtk','main_quit'));
$window->set_decorated(false);
$window->move(840,0);
$window->modify_bg(Gtk::STATE_NORMAL, GdkColor::parse("#000000"));



$lblsenha->modify_font(new PangoFontDescription("Courier New Bold 72"));
$lblsenha->modify_fg(Gtk::STATE_NORMAL, GdkColor::parse("#380"));

// em producao deixar comentado
$lblsenha->set_label('P002  14');

$titulo->modify_font(new PangoFontDescription("Arial 50"));
$titulo->modify_fg(Gtk::STATE_NORMAL,GdkColor::parse("#380"));
$titulo->set_label('  Senha      Mesa');

$ultima->modify_font(new PangoFontDescription("Arial 50"));
$ultima->modify_fg(Gtk::STATE_NORMAL,GdkColor::parse("#FF4500"));
$ultima->set_label(utf8_decode('  Últimas '));


$lblultima->modify_font(new PangoFontDescription("Courier New Bold 72"));
$lblultima->modify_fg(Gtk::STATE_NORMAL, GdkColor::parse("#FF4500"));
// em producao deixar comentado
$lblultima->set_label("P001  14\nS110  01\nI201  05\nP112  31\nN213  40");



$window->show_all();

// em producao deixar descomentado
//Gtk::timeout_add(2000, 'lista_senha');

Gtk::main();

?>

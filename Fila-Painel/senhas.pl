#!/usr/bin/perl
# Copyright 2008, 2009 - Oktiva Comércio e Serviços de Informática Ltda.
#
# Este arquivo é parte do programa FILA - Sistema de Atendimento
#
# O FILA é um software livre; você pode redistribui-lo e/ou modifica-lo
# dentro dos termos da Licença Pública Geral GNU como publicada pela
# Fundação do Software Livre (FSF); na versão 2 da Licença.
#
# Este programa é distribuido na esperança que possa ser util, mas SEM
# NENHUMA GARANTIA; sem uma garantia implicita de ADEQUAÇÂO a qualquer
# MERCADO ou APLICAÇÃO EM PARTICULAR. Veja a Licença Pública Geral GNU
# para maiores detalhes.
#
# Você deve ter recebido uma cópia da Licença Pública Geral GNU, sob o
# título "LICENCA.txt", junto com este programa, se não, escreva para a
# Fundação do Software Livre(FSF) Inc., 51 Franklin St, Fifth Floor,
use warnings;
use strict;
use Gtk2 '-init';
use Gnome2::Canvas;
use Gtk2::GladeXML;
use Unicode::String qw(utf8 latin1);

my $black = Gtk2::Gdk::Color->new (0x255,0x255,0x255);
my $red = Gtk2::Gdk::Color->new (255x255,0,0);
my $font_courier = Gtk2::Pango::FontDescription->from_string('Courier New Bold 80');
my $font_arial = Gtk2::Pango::FontDescription->from_string('Arial 50');
my (@arraytotal, @ultima, @ultima_s, @exp, @senhas, @mesa, @ultima_p, @ultima_n);
my $senhas;
my %arraytotal;
my $mesa;
my ($posicao, $tamanho, $ultima_p, $ultima_n, $ultima_s, $tela, $telaultima, $num);

my $glade = Gtk2::GladeXML->new('gtk_senha.glade');

my $window    = $glade->get_widget('window1');
my $titulo    = $glade->get_widget('label1');
my $lblsenha  = $glade->get_widget('label2');
my $ultima    = $glade->get_widget('label3');
my $lblultima = $glade->get_widget('label4');

sub construct {

    $window->move(840,0);
    $window->modify_bg('normal', $black);

    $lblsenha->modify_font($font_courier);
    $lblsenha->modify_fg('normal', $red);
    $lblsenha->set_label('P002 14');

    $titulo->modify_font($font_arial);
    $titulo->modify_fg('normal',$red);
    $titulo->set_label('  Senha     Mesa');

    $ultima->modify_font($font_arial);
    $ultima->modify_fg('normal',$red);
    $ultima->set_label(latin1('Ultimas'));

    $lblultima->modify_font($font_courier);
    $lblultima->modify_fg('normal', $red);
    $lblultima->set_label('P001 14 \nS110 01\nI201 05');

    $window->show_all();
}

sub lista_senha {
	unless(@arraytotal) {
		$posicao = 0;
		$tamanho = 0;
		$tela = "";
		print "sizeof: $tamanho\n";
	} else {
			$tela = $arraytotal[$posicao][0]."\n".$arraytotal[$posicao][1];
			completa_ultimas($arraytotal[$posicao]);	
			print "tela: $tela";
	}

	if($posicao == $tamanho) {
		completa_array();
		$posicao = 0;
		print "completando array\n";
	} else {
		$posicao = $posicao+1;
		print "incrementando posicao\n";
		print "proxima posicao: $posicao\n";
	}
	$lblsenha->set_label($tela);
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
	
	print "setando label\n\n\n";
	return 1;
}


sub completa_array {
    unless(open(FILE, "<senhas_chamando.csv")) 
    {
        die $!;
    }
    while (my $linha = <FILE>) {
        print "linha = $linha\n";
        @exp = split(/,/,$linha);
        push(@senhas,$exp[0]);
        push(@mesa,$exp[1]);
        $arraytotal{$exp[0]} = $exp[1];
        print %arraytotal;
    }
}

sub completa_ultimas($ultima) {
	my $cat = substr($ultima[0],0,1);
	my $num = substr($ultima[0],1,3);
	if($cat eq "N") {
	  if($ultima_n[0] < $num) {
		$ultima_n = $num.",".$ultima[0].",".$ultima[1];
		print "gravando N $num\n";
	  }
	} elsif($cat eq "P") {
          if($ultima_p[0] < $num) {
                $ultima_p = $num.",".$ultima[0].",".$ultima[1];
		print "gravando P $num\n";
          }
	} elsif($cat eq "S") {
          if($ultima_s[0] < $num) {
                $ultima_s = $num.",".$ultima[0].",".$ultima[1];
		print "gravando S $num\n";
          }
	}	
}


Glib::Timeout->add(5000, 'lista_senha');

construct();

Gtk2->main();



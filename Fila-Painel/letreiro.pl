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

my $ts ;
my $tempo = 20; #maior é mais lento
my $cor = "red"; #red, green, blue, black, white, etc..
my $tamanho = "80000"; #tamanho da fonte
my $width = 1200; #largura da janela
my $height = 120; #altura da janela
my $altura_texto = 60; #posicao do texto relativa a janela
my $deslocamento = 5; #deslocamento em pixels do texto

if($ARGV[0]){
    open my $source, '<:utf8', $ARGV[0];
    read($source, $ts, -s $source );
    close $source;
}else{
    $ts = "Erro ao abrir o arquivo.";
}

$ts =~ tr[\x0a\x0d][  ]d; #strip newlines

my $window = Gtk2::Window->new();
my $vp = Gtk2::Viewport->new();
my $text = Gtk2::Label->new($ts.' ');
my $fontdesc = Gtk2::Pango::FontDescription->from_string("Sans 70");
$text->modify_font($fontdesc);
$vp->modify_bg($text->state, Gtk2::Gdk::Color->new(0x0000,0x0000,0x0000));
$text->modify_fg($text->state, Gtk2::Gdk::Color->new(0xFFFF,0x0000,0x0000));
$window->add($vp);
$vp->add($text);
$window->signal_connect('destroy'=>\&_closeapp);
$vp->set_size_request($width, $height);
$window->show_all();

my ($wi, $he) = $text->get_size_request();
print $wi,$he,$/;

my $timer = Glib::Timeout->add($tempo, \&timer);
my $posicao = $vp->get_hadjustment->lower();


Gtk2->main();

sub timer {
    sleep 1 if $posicao == $vp->get_hadjustment->lower();
    $posicao += $deslocamento;
    $posicao = $vp->get_hadjustment->lower() if $posicao > $vp->get_hadjustment->upper();
    $vp->get_hadjustment->set_value($posicao);
    return 1;
}

sub _closeapp{
    Gtk2->main_quit();
    return 0;
}

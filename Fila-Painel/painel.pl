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
use strict;
use warnings;
use utf8;
use Gtk2 -init;
use Gtk2::GladeXML;
use Data::Dumper;
use POSIX qw(ceil floor);

use constant {
    INPUT_FILE => '/fila-painel/tmp/senhas_chamando.csv',
    TEMPO_ROTACAO => 4,
    TEMPO_ATENCAO => 6,
    TEMPO_RECHAMADA => 70,
    TEMPO_ULTIMAS => 5,
    TEMPO_TIRAR_ULTIMAS => 180,
   };

my $gladexml = Gtk2::GladeXML->new('gtk_senha.glade');
my ($window, $titulo, $lblsenha, $ultima, $lblultima) =
  map { $gladexml->get_widget($_) }
  qw(window1 label1 label2 label3 label4);

our @chamar_atencao;
our @rotacao;
our %ultimas;
our $status = 'iniciando';
our $error;
our $pagina_ultimas = 0;
our $counter_rotacao = 0;

setup_widgets();

cycle();
Glib::Timeout->add(TEMPO_ULTIMAS * 1000, \&cycle_ultimas);

Gtk2->main();


sub check_input_file {
  open my $file, '<', INPUT_FILE or do { $status = 'erro';
				         $error = 'Não conseguiu abrir arquivo '.$!;
					 return };

  my $time = time;

  my @arquivo = map { chomp; [ split(/,/, $_), $time ] } <$file>;

  my @new =
    grep { my $a = $_;
	   !(grep { $a->[0] eq $_->[0] } @rotacao) } @arquivo;

  push @chamar_atencao, @new;
  push @rotacao, @new;

  push @chamar_atencao,
    grep { (($time - $_->[2]) > TEMPO_RECHAMADA) && ($_->[2] = $time) }
      @rotacao;

  my @old =
    grep { my $a = $_;
	   !grep { $a->[0] eq $_->[0] } @arquivo } @rotacao;

  @rotacao =
    grep { my $a = $_;
	   !grep { $a->[0] eq $_->[0] } @old } @rotacao;

  foreach my $oldie (sort { $a->[2] <=> $b->[2] } @old) {
    my $categoria = substr $oldie->[0], 0, 1;
    $ultimas{$categoria} = $oldie;
  }

  my @categorias = keys %ultimas;
  foreach my $categoria (@categorias) {
    delete $ultimas{$categoria} if
      ((time - $ultimas{$categoria}[2]) > TEMPO_TIRAR_ULTIMAS);
  }

  if (@chamar_atencao) {
    $status = 'atencao';
  } else {
    $status = 'rotacao';
  }
}

sub cycle {
  my $delay;
  if ($status eq 'atencao') {
    $delay = cycle_atencao();
  } elsif ($status eq 'rotacao') {
    $delay = cycle_rotacao();
  } elsif ($status eq 'erro') {
    warn "Erro: $error";
    $delay = 1000;
  }
  check_input_file;

  # como nao sabemos a principio qual e o delay, vamos sempre
  # adicionar de novo o timeout e retornar falso aqui para nao
  # repetir.
  Glib::Timeout->add($delay, \&cycle);
  0;
}

sub cycle_atencao {
  my $refsenha = shift @chamar_atencao;
  my ($senha, $mesa) = @{$refsenha};

  $lblsenha->set_label($senha.'  '.$mesa);

  Glib::Idle->add(\&toca_tchuru);
  return TEMPO_ATENCAO * 1000;
}

sub cycle_rotacao {
  unless (@rotacao) {
    $lblsenha->set_label('');
    return 500;
  }

  my $refsenha = $rotacao[$counter_rotacao++];
  $counter_rotacao = 0 if $counter_rotacao > $#rotacao;

  if ($refsenha) {
    my ($senha, $mesa) = @{$refsenha};
    $lblsenha->set_label($senha.'  '.$mesa);
  }

  return TEMPO_ROTACAO * 1000;
}

sub cycle_ultimas {
  my @categorias = sort keys %ultimas;

  my $paginas = ceil(@categorias / 5);
  return 1 unless $paginas;

  my $porpagina = ceil(@categorias / $paginas);
  $pagina_ultimas = 0 if $pagina_ultimas >= $paginas;

  my $inicio = $porpagina * $pagina_ultimas++;
  my $fim = $inicio + $porpagina - 1;
  my @esta = @categorias[$inicio..$fim];
  my $str = join("\n",(map { $ultimas{$_}[0].'  '.$ultimas{$_}[1] } @esta));

  $lblultima->set_label($str);
  1;
}

sub toca_tchuru {
  system('/usr/bin/music123', '/home/f13/KDE_Event_2.ogg');
  0;
}

sub setup_widgets {
  $window->signal_connect('destroy', sub { Gtk2->main_quit });
  $window->set_decorated(0);
  $window->move(840,0);
  $window->modify_bg($window->state, Gtk2::Gdk::Color->parse("#000000"));

  $lblsenha->modify_font(Gtk2::Pango::FontDescription->from_string("Courier New Bold 72"));
  $lblsenha->modify_fg($lblsenha->state, Gtk2::Gdk::Color->parse("#380"));

  $titulo->modify_font(Gtk2::Pango::FontDescription->from_string("Arial 50"));
  $titulo->modify_fg($titulo->state,Gtk2::Gdk::Color->parse("#380"));
  $titulo->set_label('  Senha      Mesa');

  $ultima->modify_font(Gtk2::Pango::FontDescription->from_string("Arial 50"));
  $ultima->modify_fg($ultima->state,Gtk2::Gdk::Color->parse("#FF4500"));
  $ultima->set_label('  Últimas ');

  $lblultima->modify_font(Gtk2::Pango::FontDescription->from_string("Courier New Bold 72"));
  $lblultima->modify_fg($ultima->state, Gtk2::Gdk::Color->parse("#FF4500"));

  $window->show_all();
}

package Fila::ETL::Controller::Agendamento;
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
use base qw(Catalyst::Controller);

sub agendamento :Chained('/base') :PathPart :CaptureArgs(0) {
    my ($self, $c) = @_;
    my $vt_base = $c->stash->{now}->clone();
    $vt_base->add( hours => 1 );
    $c->stash->{vt_base} = $vt_base;
}

sub agendar :Chained('agendamento') :PathPart :Args(0) {
    my ($self, $c) = @_;

    my $result = $c->model('DB::ActivityLog')->search
      ({ activity_type => '/agendamento/agendar' },
       { order_by => 'vt_base DESC' });

    if (my $last = $result->first) {
      $c->stash->{last_vt_base} = $last->vt_base;
    } else {
      $c->stash->{last_vt_base} = '-Infinity';
    }

    my $agendamentos = $c->model('DBAgendamento::Atendimento')->search
      ({ -and => [{ data => { '>'  => $c->stash->{last_vt_base} }},
		  { data => { '<=' => $c->stash->{vt_base}      }}  ]});


    while (my $agendamento = $agendamentos->next) {
      eval {
	my $categoria = $c->model('Federado')->target
	  ($c, $agendamento->id_local, 'Categoria')->find
	    ({ codigo => 'A' });
	my $estado_espera = $c->model('Federado')->target
	  ($c, $agendamento->id_local, 'TipoEstadoAtendimento')->find
	    ({ nome => 'espera' });
	my $senha = $c->model('Federado')->target
	  ($c, $agendamento->id_local, 'Senha')->find
	    ({ id_categoria => $categoria->id_categoria,
	       codigo => substr($agendamento->senha, 1) });
	my $atendimento = $c->model('Federado')->target
	  ($c, $agendamento->id_local, 'Atendimento')->create
	    ({ id_senha => $senha->id_senha,
	       id_local => $agendamento->id_local,
	       vt_ini => $agendamento->data,
	       vt_fim => 'Infinity',
	       estados =>
	       [{ id_estado => $estado_espera->id_estado,
		  vt_ini => $agendamento->data,
		  vt_fim => 'Infinity' }],
	       categorias =>
	       [{ id_categoria => $categoria->id_categoria,
		  vt_ini => $agendamento->data,
		  vt_fim => 'Infinity' }]});
      };
      if ($@) {
	warn 'Erro ao realizar Agendamento ('.$agendamento->id_atendimento.'): '.$@;
      }
    }

    $c->model('DB::ActivityLog')->create
      ({ activity_type => '/agendamento/agendar',
         vt_base => $c->stash->{vt_base},
         vt_ini => $c->stash->{now} });

}


1;

__END__

=head1 NAME

Fila::ETL::Controller::Agendamento - Realiza o agendamento nos sistemas das praças

=head1 SYNOPSIS

Este controller realiza o agendamento propriamente dito nos sistemas
de cada praça, de acordo com aquilo que está no sistema de agendamento
centralizado.

=cut

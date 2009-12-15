package Fila::Administracao::Controller::Guiches;
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
use parent 'Catalyst::Controller';

sub preload :Chained('/locais/preload') :PathPart('guiche') :CaptureArgs(1) {
    my ($self, $c, $id_guiche) = @_;
    $c->stash->{guiche} = $c->stash->{local}->guiches->find
      ({ id_guiche => $id_guiche });
}

sub encerrar :Chained('preload') :PathPart :Args(0) {
    my ($self, $c) = @_;
    $c->stash->{guiche}->update
      ({ vt_fim => DateTime->now(time_zone => 'local') });
    $c->res->redirect($c->uri_for('/locais/'.$c->stash->{local}->id_local));
}

sub reabrir :Chained('preload') :PathPart :Args(0) {
    my ($self, $c) = @_;
    my $guiche = $c->stash->{guiche}->update
      ({ vt_fim => 'Infinity' });
    $c->res->redirect($c->uri_for('/locais/'.$c->stash->{local}->id_local));
}

sub ver :Chained('preload') :PathPart('') :Args(0) {
    my ($self, $c) = @_;

    unless ($c->req->param('submitted')) {
        $c->req->param($_, $c->stash->{guiche}->get_column($_))
          for qw(identificador jid_opiniometro timeout_chamando timeout_concluido);
    }
}

sub encerrar_categoria :Chained('preload') :PathPart :Args(1) {
    my ($self, $c, $id_categoria) = @_;
    $c->stash->{guiche}->categorias_atuais->find
	({ id_categoria => $id_categoria })->update
	({ vt_fim => DateTime->now(time_zone => 'local') });
    $c->res->redirect($c->uri_for('/locais/'.$c->stash->{local}->id_local.
				  '/guiche/'.$c->stash->{guiche}->id_guiche));
}

sub associar_categoria :Chained('preload') :PathPart :Args(0) {
    my ($self, $c) = @_;
    $c->stash->{guiche}->categorias->create
	({ id_categoria => $c->req->param('id_categoria'),
	   vt_ini => DateTime->now(time_zone => 'local'),
	   vt_fim => 'Infinity' });
    $c->res->redirect($c->uri_for('/locais/'.$c->stash->{local}->id_local.
				  '/guiche/'.$c->stash->{guiche}->id_guiche));
}

sub salvar :Chained('preload') :PathPart :Args(0) {
    my ($self, $c) = @_;
    $c->stash->{guiche}->update
      ({ map { $_ => $c->req->param($_) }
         qw(identificador jid_opiniometro timeout_chamando timeout_concluido) });
    $c->res->redirect($c->uri_for('/locais/'.$c->stash->{local}->id_local));
}

sub criar :Chained('/locais/preload') :PathPart('guiche/criar') :Args(0) {
    my ($self, $c) = @_;
	
	# cria um novo guiche e seta seu estado inicial como 'fechado'
	
    if ($c->req->param('submitted')) {
	   my $estado_fechado = $c->model('DB::TipoEstadoGuiche')->find
          ({ nome => 'fechado' });
	   unless ($estado_fechado) {
           $c->stash->{error} = 'Ocorreu um erro de configuracao do sistema, estado "fechado" de guiche nao encontrado.';
       } else {
	       my $guiche = $c->stash->{local}->guiches->create
	          ({ vt_ini => DateTime->now(time_zone => 'local'),
	             vt_fim => 'Infinity',
	             pular_opiniometro => 0,
	             ( map { $_ => $c->req->param($_) }
	               qw(identificador jid_opiniometro timeout_chamando timeout_concluido) ) });
		   $guiche->estados->create
    	      ({ vt_ini => DateTime->now(time_zone => 'local'),
    	         vt_fim => 'Infinity',
    	         id_estado => $estado_fechado->id_estado });
  
    	    $c->res->redirect($c->uri_for('/locais/'.$c->stash->{local}->id_local));
       }
    }
}

1;

__END__

=head1 NAME

Fila::Administracao::Controller::Guiches - Gerencia os Guichês

=head1 DESCRIPTION

O guichê é a mesa onde o atendente realiza os atendimentos. Esse é o
módulo responsável por gerenciar as informações dos guichês.

=cut


package Fila::Administracao::Controller::ConfiguracaoLimites;
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

sub preload :Chained('/locais/preload') :PathPart('limite') :CaptureArgs(1) {
    my ($self, $c, $id_estado) = @_;
    $c->stash->{limite} = $c->stash->{local}->configuracoes_limite->find
      ({ id_estado => $id_estado,
         vt_fim => 'Infinity' });
}

sub encerrar :Chained('preload') :PathPart :Args(0) {
    my ($self, $c) = @_;
    $c->stash->{limite}->update
      ({ vt_fim => DateTime->now(time_zone => 'local') });
    $c->res->redirect($c->uri_for('/locais/'.$c->stash->{local}->id_local));
}

sub criar :Chained('/locais/preload') :PathPart('limite/criar') :Args(0) {
    my ($self, $c) = @_;
    if ($c->req->param('submitted')) {
        # antes de criar, vamos certificar que as configuracoes
        # anteriores dessa categoria para esse local sejam desativadas.
        $c->stash->{local}->configuracoes_limite->search
          ({ id_estado => $c->req->param('id_estado'),
             vt_fim => 'Infinity' })->update
               ({ vt_fim => DateTime->now(time_zone => 'local')});

        $c->stash->{local}->configuracoes_limite->create
          ({ vt_ini => DateTime->now(time_zone => 'local'),
             vt_fim => 'Infinity',
             ( map { $_ => $c->req->param($_) }
               qw(id_estado segundos) ) });

        $c->res->redirect($c->uri_for('/locais/'.$c->stash->{local}->id_local));
    } else {
        $c->stash->{estados} =
          $c->model('DB::TipoEstadoGuiche')->search({},
                                                    { order_by => 'nome' })
    }
}

1;

__END__

=head1 NAME

Fila::Administracao::Controller::ConfiguracaoLimites - Gere os Limites para Alerta

=head1 DESCRIPTION

Esse módulo define os limites de tempo para cada um dos estados do
guiche. Permitindo que o gerente seja visualmente avisado sobre
anomalias durante o processo de atendimento.

=cut


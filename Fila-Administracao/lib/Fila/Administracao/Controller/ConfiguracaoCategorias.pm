package Fila::Administracao::Controller::ConfiguracaoCategorias;
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

sub preload :Chained('/locais/preload') :PathPart('categoria') :CaptureArgs(1) {
    my ($self, $c, $id_categoria) = @_;
    $c->stash->{configuracao} = $c->stash->{local}->configuracoes_categoria->find
      ({ id_categoria => $id_categoria,
         vt_fim => 'Infinity' });
}

sub encerrar :Chained('preload') :PathPart :Args(0) {
    my ($self, $c) = @_;
    $c->stash->{configuracao}->update
      ({ vt_fim => DateTime->now(time_zone => 'local') });
    $c->res->redirect($c->uri_for('/locais/'.$c->stash->{local}->id_local));
}

sub criar :Chained('/locais/preload') :PathPart('categoria/criar') :Args(0) {
    my ($self, $c) = @_;
    if ($c->req->param('submitted')) {
        # antes de criar, vamos certificar que as configuracoes
        # anteriores dessa categoria para esse local sejam desativadas.
        $c->stash->{local}->configuracoes_categoria->search
          ({ id_categoria => $c->req->param('id_categoria'),
             vt_fim => 'Infinity' })->update
               ({ vt_fim => DateTime->now(time_zone => 'local')});

        $c->stash->{local}->configuracoes_categoria->create
          ({ vt_ini => DateTime->now(time_zone => 'local'),
             vt_fim => 'Infinity',
             ( map { $_ => $c->req->param($_) }
               qw(id_categoria prioridade limite_tempo_espera limite_pessoas_espera ordem) ) });

        # vamos também certificar que existem as senhas para essa
        # categoria nesse local.
        for my $cod (1..999) {
            $c->stash->{local}->senhas->create
              ({ id_categoria => $c->req->param('id_categoria'),
                 codigo => $cod })
                unless $c->stash->{local}->senhas->find
                  ({ id_categoria => $c->req->param('id_categoria'),
                     codigo => $cod });
        }

        $c->res->redirect($c->uri_for('/locais/'.$c->stash->{local}->id_local));
    } else {
        $c->stash->{categorias} =
          $c->model('DB::Categoria')->search({},
                                             { order_by => 'nome' })
    }
}

1;

__END__

=head1 NAME

Fila::Administracao::ConfiguracaoCategorias - Gerencia as configurações das categorias

=head1 DESCRIPTION

A categoria de atendimento tem a configuração das suas prioridades
definidas de acordo com cada local. Esse é o módulo que implementa a
gestão dessas informações.

=cut


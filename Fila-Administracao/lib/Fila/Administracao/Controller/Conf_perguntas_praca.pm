package Fila::Administracao::Controller::Conf_perguntas_praca;
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

sub preload :Chained('/locais/preload') :PathPart('conf_perguntas_praca') :CaptureArgs(1) {
    my ($self, $c) = @_;
}

sub criar :Chained('/locais/preload') :PathPart('conf_perguntas_praca/criar') :Args(0) {
    my ($self, $c) = @_;
    if ($c->req->param('submitted')) {
        # antes de criar, vamos certificar que as configuracoes
        # anteriores dessa categoria para esse local sejam desativadas.
        $c->stash->{local}->configuracoes_perguntas_praca->search
          ({ vt_fim => 'Infinity' })->update
               ({ vt_fim => DateTime->now(time_zone => 'local')});

        $c->stash->{local}->configuracoes_perguntas_praca->create
          ({ vt_ini => DateTime->now(time_zone => 'local'),
             vt_fim => 'Infinity',
             ( map { $_ => $c->req->param($_) }
               qw(pergunta1 pergunta2 pergunta3 pergunta4 pergunta5 ) ) });

        $c->res->redirect($c->uri_for('/locais/'.$c->stash->{local}->id_local));
    } else {
	    $c->stash->{perguntas} = $c->model('DB::PerguntaAvaliacaoPraca')->search({});
    }
}

1;


__END__

=head1 NAME

Fila::Administracao::Controller::Conf_perguntas_praca - Define
configuração das perguntas do opiniometro da praca

=head1 DESCRIPTION

Este módulo implementa o suporte à configuração de quais são as
perguntas que estao nesse momento associadas ao opiniometro geral da
praça de atendimento.

=cut


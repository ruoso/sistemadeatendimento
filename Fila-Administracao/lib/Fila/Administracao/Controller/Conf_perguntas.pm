package Fila::Administracao::Controller::Conf_perguntas;
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

sub preload :Chained('/locais/preload') :PathPart('conf_perguntas') :CaptureArgs(1) {
    my ($self, $c) = @_;
}

sub criar :Chained('/locais/preload') :PathPart('conf_perguntas/criar') :Args(0) {
    my ($self, $c) = @_;
    if ($c->req->param('submitted')) {
        # antes de criar, vamos certificar que as configuracoes
        # anteriores dessa categoria para esse local sejam desativadas.
        $c->stash->{local}->configuracoes_perguntas->search
          ({ vt_fim => 'Infinity' })->update
               ({ vt_fim => DateTime->now(time_zone => 'local')});

        $c->stash->{local}->configuracoes_perguntas->create
          ({ vt_ini => DateTime->now(time_zone => 'local'),
             vt_fim => 'Infinity',
             ( map { $_ => $c->req->param($_) }
               qw(pergunta1 pergunta2 pergunta3 pergunta4 pergunta5 ) ) });

        $c->res->redirect($c->uri_for('/locais/'.$c->stash->{local}->id_local));
    } else {
	    $c->stash->{perguntas} = $c->model('DB::PerguntaAvaliacao')->search({});
    }
}

1;

__END__

=head1 NAME

Fila::Administracao::Conf_perguntas - Configuração das perguntas

=head1 DESCRIPTION

Este é o módulo que implementa a configuração das perguntas que são
exibidas no opiniômetro de cada mesa. Essas são as perguntas ao qual o
cliente da praça de atendimentos responde no final de um atendimento.

=cut


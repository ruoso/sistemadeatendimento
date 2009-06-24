package Fila::Administracao::Controller::Root;
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
use DateTime;
use parent 'Catalyst::Controller';

__PACKAGE__->config->{namespace} = '';

sub auto :Private {
    my ($self, $c) = @_;
    $c->stash->{now} = DateTime->now(time_zone => 'local');
}

sub index : Path Args(0) {}

sub default : Path {
    my ( $self, $c ) = @_;
    $c->response->body( 'Page not found' );
    $c->response->status(404);
}

sub end : ActionClass('RenderView') {}

1;

__END__

=head1 NAME

Fila::Administracao::Controller::Root - Implementa a raiz da navegação

=head1 DESCRIPTION

A aplicação de administração é responsável por gerir algumas
informações padrões para a aplicação inteira, como a definição do
time_zone padrão bem como a definição da ação default que usa o view
para renderizar a saída.

=cut


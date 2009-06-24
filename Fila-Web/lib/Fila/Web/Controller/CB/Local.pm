package Fila::Web::Controller::CB::Local;
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
use base 'Catalyst::Controller';

#recebe os eventos do navegador e os redireciona para filawebapp.

sub abrir : Local {
    my ($self, $c) = @_;

    $c->model('SOAP')->transport
        ->addrs([$c->session->{user_jid}.'/cb/gerente']);

    my $req = $c->model('SOAP::Gerente')->abrir_local
     ({ callback_request =>
        { param =>
          [ map {( name => $_,
                   value => $c->req->param($_) )}
                keys %{$c->req->params} ]}});
}

sub fechar : Local {
    my ($self, $c) = @_;

    $c->model('SOAP')->transport
        ->addrs([$c->session->{user_jid}.'/cb/gerente']);

    my $req = $c->model('SOAP::Gerente')->fechar_local
     ({ callback_request =>
        { param =>
          [ map {( name => $_,
                   value => $c->req->param($_) )}
                keys %{$c->req->params} ]}});
}

sub fechar_local_force : Local {
    my ($self, $c) = @_;

    $c->model('SOAP')->transport
        ->addrs([$c->session->{user_jid}.'/cb/gerente']);

    my $req = $c->model('SOAP::Gerente')->fechar_local_force
     ({ callback_request =>
        { param =>
          [ map {( name => $_,
                   value => $c->req->param($_) )}
                keys %{$c->req->params} ]}});
}


sub encerrar_senhas : Local {
    my ($self, $c) = @_;

    $c->model('SOAP')->transport
        ->addrs([$c->session->{user_jid}.'/cb/gerente']);

    my $req = $c->model('SOAP::Gerente')->encerrar_senhas
     ({ callback_request =>
        { param =>
          [ map {( name => $_,
                   value => $c->req->param($_) )}
                keys %{$c->req->params} ]}});
}

sub fechar_todos : Local {
    my ($self, $c) = @_;

    $c->model('SOAP')->transport
        ->addrs([$c->session->{user_jid}.'/cb/gerente']);

    my $req = $c->model('SOAP::Gerente')->fechar_todos
     ({ callback_request =>
        { param =>
          [ { name => '',
              value => '' } ]}});


}

1;

__END__

=head1 NAME

Local - Callbacks para o gerente

=head1 DESCRIPTION

As requisições http são traduzidas para mensagens SOAP+XMPP

=cut


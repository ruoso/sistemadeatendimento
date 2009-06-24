package Fila::Web::Controller::CB::Gerente;
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

sub enviar_chat : Local {
    my ($self, $c) = @_;

    $c->model('SOAP')->transport
        ->addrs([$c->session->{user_jid}.'/cb/gerente']);

    my $texto = $c->req->param('txtTexto');

    my $req = $c->model('SOAP::Gerente')->enviar_chat
     ({ callback_request => 
        { param =>
          [ { name => $c->req->param('select_chat'),
              value => $texto } ]}});

}

sub encerrar_atendimento : Local {
    my ($self, $c, $id) = @_;

    $c->model('SOAP')->transport
        ->addrs([$c->session->{user_jid}.'/cb/gerente']);


    my $req = $c->model('SOAP::Gerente')->encerrar_atendimento
     ({ callback_request => 
        { param =>
          [ { name => 'id_atendimento',
              value => $id } ]}});

}

sub devolver_senha : Local {
    my ($self, $c, $id) = @_;

    $c->model('SOAP')->transport
        ->addrs([$c->session->{user_jid}.'/cb/gerente']);

    my $req = $c->model('SOAP::Gerente')->devolver_senha
     ({ callback_request =>
        { param =>
          [ { name => 'id_guiche',
              value => $id } ]}});

}


sub fechar_guiche : Local {
    my ($self, $c, $id) = @_;

    $c->model('SOAP')->transport
        ->addrs([$c->session->{user_jid}.'/cb/gerente']);


    my $req = $c->model('SOAP::Gerente')->fechar_guiche
     ({ callback_request => 
        { param =>
          [ { name => 'id_guiche',
              value => $id } ]}});

}

sub concluir_atendimento : Local {
    my ($self, $c, $id) = @_;

    $c->model('SOAP')->transport
        ->addrs([$c->session->{user_jid}.'/cb/gerente']);


    my $req = $c->model('SOAP::Gerente')->concluir_atendimento
     ({ callback_request => 
        { param =>
          [ { name => 'id_guiche',
              value => $id } ]}});

}

sub pular_opiniometro : Local {
    my ($self, $c, $valor,$id) = @_;

    $c->model('SOAP')->transport
        ->addrs([$c->session->{user_jid}.'/cb/gerente']);


    my $req = $c->model('SOAP::Gerente')->pular_opiniometro
     ({ callback_request => 
        { param =>
          [ { name => $id,
              value => $valor } ]}});

}

sub listar_encaminhamentos : Local {
    my ($self, $c) = @_;

    $c->model('SOAP')->transport
        ->addrs([$c->session->{user_jid}.'/cb/gerente']);

    my $req = $c->model('SOAP::Gerente')->listar_encaminhamentos
     ({ callback_request => 
        { param =>
          [ { name => '',
              value => '' } ]}});

}
#minha modificação
sub associar_gerente : Local{
	my ($self, $c, $id) = @_;

    $c->model('SOAP')->transport
        ->addrs([$c->session->{user_jid}.'/cb/gerente']);

    my $req = $c->model('SOAP::Gerente')->associar_gerente
     ({ callback_request => 
      { param =>
        [ { name => 'id_funcionario',
            value => $id } ]}});
	
}

sub passar_gerencia : Local{
	my ($self, $c) = @_;

   $c->model('SOAP')->transport
       ->addrs([$c->session->{user_jid}.'/cb/gerente']);
	
   my $req = $c->model('SOAP::Gerente')->passar_gerencia
    ({ callback_request => 
     { param =>
       [ { name => '',
           value => '' } ]}});
	
}

1;
__END__

=head1 NAME

Gerente - Callbacks para o gerente

=head1 DESCRIPTION

As requisições http são traduzidas para mensagens SOAP+XMPP

=cut


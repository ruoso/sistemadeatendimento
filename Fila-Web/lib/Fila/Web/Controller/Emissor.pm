package Fila::Web::Controller::Emissor;
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
use Digest::MD5;
use base 'Catalyst::Controller';

sub solicitar_senha : Local {
	my ($self, $c, $id_categoria) = @_;
    
    $c->model('SOAP')->transport
        ->addrs([$c->session->{user_jid}.'/cb/emissor']);
    my $req = $c->model('SOAP::Emissor')->solicitar_senha
        ({ callback_request =>
            { param =>
                [ { name => 'id_categoria',
                    value => $id_categoria } ] } } );



}

sub sair: Local {
    my ($self, $c) = @_;

    $c->model('SOAP')->transport
        ->addrs([$c->session->{user_jid}.'/cb/emissor']);
    my $req = $c->model('SOAP::Emissor')->sair
     ({ callback_request => { }});
}

1;

__END__

=head1 NAME

Emissor - Callbacks para o emissor de senha manual

=head1 DESCRIPTION

Traduz requisições HTTP em requisições SOAP+XMPP

=cut


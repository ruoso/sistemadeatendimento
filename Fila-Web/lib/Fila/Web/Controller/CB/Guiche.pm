package Fila::Web::Controller::CB::Guiche;
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
    my ($self, $c, $id_guiche) = @_;
    
    $c->model('SOAP')->transport
        ->addrs([$c->session->{user_jid}.'/cb/guiche']);
    
    my $req = $c->model('SOAP::Guiche')->abrir_guiche
     ({ callback_request =>
        { param =>
          [ { name => 'id_guiche',
              value => $id_guiche  } ]}});

}

1;

__END__

=head1 NAME

Guiche - Callback para a abertura do guiche

=head1 DESCRIPTION

Traduz a requisição http para requisição SOAP+XMPP

=cut


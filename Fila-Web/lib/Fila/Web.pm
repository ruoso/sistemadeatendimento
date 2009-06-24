package Fila::Web;
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

use Catalyst::Runtime '5.70';

use Catalyst qw/Unicode ConfigLoader Static::Simple Session
      Session::Store::FastMmap Session::State::Cookie/;

our $VERSION = '0.01';

__PACKAGE__->config( name => 'Fila::Web' );

__PACKAGE__->setup;

use EV;
use AnyEvent;
use Net::XMPP2::Connection;


sub connect_xmpp {
    warn "Starting Connection.";

    $::connection = Net::XMPP2::Connection->new
      ( username => 'apache',
        password => 'password',
        domain => 'gestao.fila.vhost',
        resource => 'Fila::Web',
        whitespace_ping_interval => 2,
        override_host => 'localhost',
        blocking_write => 1);

    Fila::Web::Model::SOAP->config->{transport}
        ->connection($::connection);

    my $die_on_unloop = 0;
    my $once_connected = 0;

    $::connection->reg_cb
      ( stream_ready => sub {
            $::connection->send_presence('available', sub {});
            EV::unloop;
        },

        bind_error => sub {
            $die_on_unloop = 1;
            EV::unloop;
        },

        iq_auth_error => sub {
            $die_on_unloop = 1;
            EV::unloop;
        },

        sasl_error => sub {
            $die_on_unloop = 1;
            EV::unloop;
        },

        disconnect => sub {
            if ($once_connected) {
                warn 'Disconnected!.';
                $die_on_unloop = 1;
		exit;
            } else {
                warn 'Disconnected during Setup!';
                sleep 1;
                $die_on_unloop = 1;
                EV::unloop;
            }
        },

        stream_error => sub {
            if ($once_connected) {
                warn 'Stream Error! Will try to reconnect.';
                $die_on_unloop = 1;
                EV::unloop;
            } else {
                warn 'Stream Error during Setup!';
                sleep 1;
                $die_on_unloop = 1;
                EV::unloop;
            }
        });

    $::connection->connect() || die 'Could not connect to Jabber server';

    EV::loop;

    if ($die_on_unloop) {
        warn 'Conection failed. Re-starting';
	exit;
    } else {
        warn 'Connection established.';
        $once_connected = 1;
    }
}

connect_xmpp();
1;

__END__

=head1 NAME

Web - Aplicação de callback

=head1 DESCRIPTION

Essa aplicação é responsável por receber as solicitações do navegador
e encaminhar para o usuário em questão via XMPP para que a ação seja
efetivamente processada.

=cut


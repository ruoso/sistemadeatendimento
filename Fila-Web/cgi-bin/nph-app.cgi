#!/usr/bin/perl
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

use EV;
use AnyEvent;
use lib '/usr/share/fila/Fila-Web/lib';

use CGI '-nph';

my $query = CGI->new();
print $query->header(-type => 'text/html',
                     -charset => 'utf-8',
                     -nph => 1);

STDOUT->autoflush(1);

print '<HTML><HEAD><TITLE>Sistema de Atendimento</TITLE></HEAD><BODY><P id="p_carregando_inicial">Carregando...</P></BODY></HTML>';

{   package Fila::WebApp;

    use strict;
    use warnings;

    use Catalyst::Runtime '5.70';
    use Net::XMPP2::Connection;

    use Catalyst qw/-Debug Unicode Static::Simple Prototype/;
    our $VERSION = '0.01';

    my $app = __PACKAGE__;

	my $user_jid;
	my $domain;
    if ($query->param('agents')) {
    	$::major_mode = 'agents';
	    $user_jid = $query->param('usuario').'@agents.fila.vhost'; #emissor@agents.fila.vhost
	    $domain = 'agents.fila.vhost'; #dominio agents.fila.vhost
    } else { 
	    $user_jid = $query->param('usuario').'@people.fila.vhost'; #emissor@agents.fila.vhost
	    $domain = 'people.fila.vhost';
    }
    $app->config
      ('home' => '/usr/share/fila/Fila-Web/',
       'name' => 'Fila::WebApp',
       'Engine::XMPP2' => { username => $query->param('usuario'),
                             domain => $domain,
                             override_host => 'localhost',
                             password => $query->param('senha') });

    $::user_guiche = $query->param('guiche');
    $::user_jid = $user_jid;

    $ENV{CATALYST_ENGINE} = 'XMPP2';
    $app->setup;

    {
        no warnings;
        # Forçar o uso do EV no lugar do Event.
        *Catalyst::Engine::XMPP2::loop = *EV::loop;
    }

    # neste ponto já temos uma aplicação configurada, e já podemos
    # usá-la para montar a tela, não precisamos fazer coisas em CGI ;)
    # vamos conectar para autenticar.

    $::connection = Net::XMPP2::Connection->new
      (%{$app->config->{'Engine::XMPP2'}},
       resource => 'Main Connection');

    {
        # render the base page
        my $req = HTTP::Request->new(GET => '/render/base');
        my $res;
        $app->handle_request($req, \$res);
    }


    $::connection->reg_cb
      (connection => sub {
           my $req = HTTP::Request->new(GET => '/render/connected');
           my $res;
           $app->handle_request($req, \$res);
       },

       bind_error => sub {
           my $req = HTTP::Request->new(GET => '/render/error');
           my $res;
           $app->handle_request($req, \$res);
           EV::unloop(EV::UNLOOP_ALL);
       },

       iq_auth_error => sub {
           my $req = HTTP::Request->new(GET => '/render/error');
           my $res;
           $app->handle_request($req, \$res);
           EV::unloop(EV::UNLOOP_ALL);
       },

       sasl_error => sub {
           my $req = HTTP::Request->new(GET => '/render/error');
           my $res;
           $app->handle_request($req, \$res);
           EV::unloop(EV::UNLOOP_ALL);
       },

       disconnect => sub {
           my $req = HTTP::Request->new(GET => '/render/disconnected');
           my $res;
           $app->handle_request($req, \$res);
           EV::unloop(EV::UNLOOP_ALL);
       },

       stream_error => sub {
           my $req = HTTP::Request->new(GET => '/render/error');
           my $res;
           $app->handle_request($req, \$res);
           EV::unloop(EV::UNLOOP_ALL);
       },

       stream_ready => sub {
           $::connection->send_presence('available', sub {});

           {
               # notify that we've authenticated.
               my $req = HTTP::Request->new(GET => '/render/authenticated');
               my $res;
               $app->handle_request($req, \$res);
           }

           eval {
               Fila::WebApp->run();
           };
           if ($@) {
               my $req = HTTP::Request->new(GET => '/render/error');
               my $res;
               $app->handle_request($req, \$res);
               EV::unloop(EV::UNLOOP_ALL);
           }
       });

    unless ($::connection->connect) {
        my $req = HTTP::Request->new(GET => '/render/error');
        my $res;
        $app->handle_request($req, \$res);
    } else {

        my $w = EV::timer 10, 10, sub {
            print '<!-- keepalive -->';
        };

        EV::loop;

    }
}
1;

package Fila::Painel;
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
use Catalyst qw/-Debug ConfigLoader Static::Simple/;

our $VERSION = '0.01';

__PACKAGE__->setup;

our $output;
{
    $output = __PACKAGE__->config->{output}
      or die 'Arquivo de saida nao configuradas.';
}


# Inicializar uma conexão principal de controle que ira fazer a
# inicializacao

$::connection = Net::XMPP2::Connection->new
  (%{Fila::Painel->config->{'Engine::XMPP2'}},
   resource => 'Main Connection');

$::connection->reg_cb
  (bind_error => sub {
       warn 'Error binding to resource';
       EV::unloop(EV::UNLOOP_ALL);
   },

   iq_auth_error => sub {
       warn 'Authentication error';
       EV::unloop(EV::UNLOOP_ALL);
   },

   sasl_error => sub {
       warn 'Authentication error';
       EV::unloop(EV::UNLOOP_ALL);
   },

   disconnect => sub {
       warn 'Disconnecting.';
       EV::unloop(EV::UNLOOP_ALL);
   },

   stream_error => sub {
       warn 'Connection error.';
       EV::unloop(EV::UNLOOP_ALL);
   },

   stream_ready => sub {
       $::connection->send_presence('available', sub {});

       eval {
           Fila::Painel->run();
       };
       if ($@) {
           warn 'Error running application: '.$@;
           EV::unloop(EV::UNLOOP_ALL);
       }
   });

unless ($::connection->connect) {
    die 'Cannot connect to server';
} else {
    EV::loop;
}


1;

__END__

=head1 NAME

Fila::Painel - Recepção da informação para Sinalização

=head1 SYNOPSIS

  # dentro do diretório Fila-Painel
  ./script/fila_painel_app.pl

=head1 DESCRIPTION

Este é o módulo da aplicação do Fila-Painel. Ele é também responsável
por gerir a conexão principal da aplicação.

=cut


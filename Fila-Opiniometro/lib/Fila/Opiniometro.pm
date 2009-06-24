package Fila::Opiniometro;
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
use Catalyst::Runtime '5.70';
use Catalyst qw/-Debug ConfigLoader Static::Simple/;

our $VERSION = '0.01';

warn 'Setting up application';
__PACKAGE__->setup;

if ($::username) {
	__PACKAGE__->config->{'Engine::XMPP2'}{username} = $::username;
}

# variavel para receber username
our $porta_opiniometro;
our $perguntas;
our $timeout;
{
    my $portas = __PACKAGE__->config->{portas};

    die 'Porta do dispositivo nao configurada' unless
      $porta_opiniometro = $portas->{opiniometro};

    $perguntas = __PACKAGE__->config->{perguntas}
      or die 'Categorias nao configuradas.';

    $timeout = __PACKAGE__->config->{timeout} || 5;
}


# Inicializar uma conexão principal de controle que ira fazer a
# inicializacao

$::connection = Net::XMPP2::Connection->new
  (%{Fila::Opiniometro->config->{'Engine::XMPP2'}},
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

       warn 'Setting up connection...';
       Fila::Opiniometro->model('SOAP')->transport->connection($::connection);
       Fila::Opiniometro->model('SOAP')->transport->addrs(['motor@gestao.fila.vhost/ws/gestao/opiniometro']);

       if ($::praca && $::praca == 1) {
	       warn 'Iniciando Opiniometro..';
	       Fila::Opiniometro->model('Device')->iniciar;
       } else {
	       warn 'Opiniometro sempre inicia desligado, e espera por eventos';
	       Fila::Opiniometro->model('Device')->encerrar;
	   }
       eval {
           Fila::Opiniometro->run();
       };
       if ($@) {
           warn 'Error running application: '.$@;
           EV::unloop(EV::UNLOOP_ALL);
       }
   });

unless ($::connection->connect) {
    die 'Cannot connect to server';
} else {
    warn 'Connecting...';
    EV::loop;
}


1;

__END__

=head1 NAME

Opiniometro - Aplicação para comunicação com o dispositivo opiniômetro

=head1 SYNOPSIS

  # dentro do diretório Fila-Opiniometro
  ./script/fila_opiniometro_app.pl

=head1 DESCRIPTION

Este é o módulo de aplicação que comunica-se com o dispositivo
opiniômetro para registrar a avaliação dos usuários sobre a praça.

=cut


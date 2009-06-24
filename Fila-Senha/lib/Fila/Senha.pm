package Fila::Senha;
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
use Net::XMPP2::Connection;

our $VERSION = '0.01';

__PACKAGE__->setup;

our $porta_impressora;
our $porta_emissor;
our $categorias;

{
    my $portas = __PACKAGE__->config->{portas};
    die 'Porta da impressora nao configurada' unless
      $porta_impressora = $portas->{impressora};

    die 'Porta do emissor nao configurada' unless
      $porta_emissor = $portas->{emissor};

    $categorias = __PACKAGE__->config->{categorias}
      or die 'Categorias nao configuradas.';

}


# Inicializar uma conexão principal de controle que ira fazer a
# inicializacao

$::connection = Net::XMPP2::Connection->new
  (%{Fila::Senha->config->{'Engine::XMPP2'}},
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

       Fila::Senha->model('SOAP')->transport->connection($::connection);
       Fila::Senha->model('SOAP')->transport->addrs(['motor@gestao.fila.vhost/ws/gestao/senha']);

       our $dados_local = Fila::Senha->model('SOAP::Senha')
         ->dados_local({ local => {} });

       if ($dados_local->{Fault} &&
           $dados_local->{Fault}{faultstring} =~ /Permissao Negada/) {
           warn 'Local está fechado. Vai esperar uma notificacao.';
           Fila::Senha->model('Emissor')->bloquear;
       } elsif ($dados_local->{Fault}) {
           warn 'Erro ao obter os dados do local: '.$dados_local->{Fault}{faultstring};
           EV::unloop(EV::UNLOOP_ALL());
       } else {
           warn 'Abrindo para senhas';
           Fila::Senha->model('Emissor')->abrir;
       }

       eval {
           Fila::Senha->run();
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

Fila::Senha - Aplicação de comunicação com o emissor de senha e a impressora.

=head1 SYNOPSIS

  # dentro do diretorio Fila-Senha
  ./script/fila_senha_app.pl

=head1 DESCRIPTION

Essa aplicação é responsável por comunicar-se tanto com o dispositivo
emissor de senha que notifica quando algum dos seus botões são
pressionados, quanto com a impressora que recebe o texto para ser
impresso com os dados da senha.

=cut


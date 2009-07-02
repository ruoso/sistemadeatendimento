package Fila::Servico::Controller::WS::Scheduler;
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
use Net::XMPP2::Util 'bare_jid';
use DateTime;
use DateTime::Format::Pg;
use DateTime::Format::XSD;
use Carp qw(croak);
use base
  'Fila::Servico::Controller',
  'Catalyst::Controller::SOAP',
  'Catalyst::Controller::DBIC::Transaction';

__PACKAGE__->config->{wsdl} =
  { wsdl => '/usr/share/fila/Fila-Servico/schemas/FilaServico.wsdl',
    schema => '/usr/share/fila/Fila-Servico/schemas/fila-servico.xsd',
    wsdlservice => 'FilaServico' };

sub auto :Private {
  my ($self, $c, $query) = @_;
  if ($c->req->header('XMPP_Stanza') eq 'presence') {
    return 0;
  } else {
    return 1;
  }
}

# todas essas operações são read-only, então não precisamos fazer
# nenhuma checagem de autenticação.
sub escalonar_senha :WSDLPort('Scheduler') :DBICTransaction('DB') :MI {
  my ($self, $c, $query) = @_;

  my $id_local = $query->{local}{id_local};
  $c->stash->{local} = $c->model('DB::Local')->find({ id_local => $id_local });
  $c->stash->{gerente} = $c->stash->{local}->gerente_atual->first;
  $c->stash->{funcionario} = $c->stash->{gerente}->funcionario;
  $c->forward('/ws/gestao/local/escalonar_senha');

  $c->stash->{soap}->compile_return(undef);
}

sub refresh_gerente :WSDLPort('Scheduler') :DBICTransaction('DB') :MI {
  my ($self, $c, $query) = @_;

  my $id_local = $query->{local}{id_local};
  $c->stash->{local} = $c->model('DB::Local')->find({ id_local => $id_local });
  $c->stash->{gerente} = $c->stash->{local}->gerente_atual->first;
  $c->stash->{funcionario} = $c->stash->{gerente}->funcionario;
  $c->forward('/ws/gestao/local/refresh_gerente');

  $c->stash->{soap}->compile_return(undef);
}

sub refresh_painel :WSDLPort('Scheduler') :DBICTransaction('DB') :MI {
  my ($self, $c, $query) = @_;

  my $id_local = $query->{local}{id_local};
  $c->stash->{local} = $c->model('DB::Local')->find({ id_local => $id_local });
  $c->stash->{gerente} = $c->stash->{local}->gerente_atual->first;
  $c->stash->{funcionario} = $c->stash->{gerente}->funcionario;
  $c->forward('/ws/gestao/local/refresh_painel');

  $c->stash->{soap}->compile_return(undef);
}

sub refresh_guiche :WSDLPort('Scheduler') :DBICTransaction('DB') :MI {
  my ($self, $c, $query) = @_;

  my $id_guiche = $query->{guiche}{id_guiche};
  $c->stash->{guiche} = $c->model('DB::Guiche')->find({ id_guiche => $id_guiche });
  $c->stash->{atendente} = $c->stash->{guiche}->atendente_atual->first;
  $c->stash->{funcionario} = $c->stash->{atendente}->funcionario;
  $c->stash->{local} = $c->stash->{guiche}->local;
  $c->stash->{gerente} = $c->stash->{local}->gerente_atual->first;
  $c->forward('/ws/gestao/atendente/refresh_atendente');

  $c->stash->{soap}->compile_return(undef);
}

1;

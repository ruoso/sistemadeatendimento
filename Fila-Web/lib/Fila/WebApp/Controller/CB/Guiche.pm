package Fila::WebApp::Controller::CB::Guiche;
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
use base 'Catalyst::Controller::SOAP';

__PACKAGE__->config->{wsdl} =
  {wsdl => Fila::WebApp->path_to('schemas/FilaWeb.wsdl')};


sub abrir_guiche : WSDLPort('FilaWebGuicheCallback') {
    my ($self, $c, $query) = @_;

    my %params = map { $_->{name} => $_->{value} }
      @{$query->{callback_request}{param}};

    $c->model('SOAP')->transport->addrs(['motor@gestao.fila.vhost/ws/gestao/guiche']);
    $c->model('SOAP::Gestao::Guiche')
      ->abrir_guiche({ guiche => \%params });

    $c->forward('/render/atendente');
    $c->forward($c->view());
}

sub abrir_user_guiche : Private {
    my ($self, $c, $query) = @_;

    my %params = (identificador => $::user_guiche);
    $::user_guiche = undef;

    $c->model('SOAP')->transport->addrs(['motor@gestao.fila.vhost/ws/gestao/guiche']);
    $c->model('SOAP::Gestao::Guiche')
      ->abrir_guiche({ guiche => \%params });

    $c->forward('/render/atendente');
    $c->forward($c->view());
}


1;

__END__

=head1 NAME

Guichê - Lógica de interface do guiche

=head1 DESCRIPTION

Este módulo possibilita a listagem inicial de guichês para que o
usuário possa escolher um guichê para abrir, bem como o processamento
dessa solicitação.

=cut


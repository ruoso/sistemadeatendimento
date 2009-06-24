package Fila::Opiniometro::Controller::Callback;
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
  {wsdl => Fila::Opiniometro->path_to('schemas/FilaOpiniometro.wsdl')};

sub iniciar_opiniometro :WSDLPort('FilaOpiniometroCallback') {
    my ($self, $c) = @_;
    $c->model('Device')->iniciar;
}

sub encerrar_opiniometro :WSDLPort('FilaOpiniometroCallback') {
    my ($self, $c) = @_;
    $c->model('Device')->encerrar;
}


1;

__END__

=head1 NAME

Callback - Recebe notificacao para encerrar/iniciar aparelho

=head1 DESCRIPTION

As avaliações só podem ser realizadas com a praça aberta, por isso o
opiniometro precisa receber mensagens do serviço para a
disponibilização e o encerramento do opiniometro.

=cut


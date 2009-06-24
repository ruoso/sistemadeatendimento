package Fila::Senha::Controller::Callback;
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
  {wsdl => Fila::Senha->path_to('schemas/FilaSenha.wsdl')};

sub local_aberto :WSDLPort('FilaSenhaCallback') {
    my ($self, $c) = @_;
    $c->model('Emissor')->abrir;
}

sub senhas_encerradas :WSDLPort('FilaSenhaCallback') {
    my ($self, $c) = @_;
    $c->model('Emissor')->bloquear;
}


1;

__END__

=head1 NAME

Fila::Senha::Controller::Callback - Serviço SOAP para ativar e
desativar o emissor.

=head1 DESCRIPTION

Esse é o Controller que implementa o serviço descrito no wsdl
'schemas/FilasSenha.wsdl'. Esse serviço é chamado pelo Fila-Servico no
momento em que o Local é aberto, fechado ou tem as senhas encerradas.

=cut


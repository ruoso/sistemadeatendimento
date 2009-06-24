package Fila::Painel::Controller::Callback;
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
  {wsdl => Fila::Painel->path_to('schemas/FilaPainel.wsdl')};

sub senhas_chamando :WSDLPort('FilaPainelCallback') {
    my ($self, $c, $dados) = @_;
    my @senhas = map { [ $_->{senha}, $_->{guiche} ] }
      @{$dados->{senhas_chamando}{senha}};
    $c->model('Output')->salvar(\@senhas);
}


1;

__END__

=head1 NAME

Fila::Painel::Controller::Callback - Recebe a lista das senhas sendo
chamadas

=head1 DESCRIPTION

Este controller é o responsável pela recepção da mensagem SOAP
estabelecida pelo Port FilaPainelCallback. Este callback fica
disponível para o Fila-Servico comunicar ao painel que a lista de
senhas chamando foi alterada.

=cut


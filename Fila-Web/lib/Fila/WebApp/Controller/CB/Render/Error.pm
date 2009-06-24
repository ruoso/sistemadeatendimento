package Fila::WebApp::Controller::CB::Render::Error;
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
use XML::Compile::SOAP;
use base 'Catalyst::Controller::SOAP';

__PACKAGE__->config->{wsdl} =
  { wsdl => Fila::WebApp->path_to('schemas/FilaWebApp.wsdl'),
    schema =>
    [ Fila::WebApp->path_to('schemas/fila-servico.xsd'),
      Fila::WebApp->path_to('schemas/soap-envelope.xsd') ]};


sub render_error :WSDLPort('render_error') {
    my ($self, $c, $dados) = @_;

    $c->stash->{error_message} = $dados->{Fault}{faultstring};
    $c->stash->{template} = 'render/error_message.tt';
    $c->forward($c->view());
}


1;

__END__

=head1 NAME

Error - Renderiza pop-up de erro

=head1 DESCRIPTION

Esse módulo implementa a renderização de um popup de erro na tela do
usuário quando algum erro acontece.

=cut


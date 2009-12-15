package Fila::WebApp::Controller::CB::Render::Gerente;
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
  { wsdl => Fila::WebApp->path_to('schemas/FilaWebApp.wsdl'),
    schema => Fila::WebApp->path_to('schemas/fila-servico.xsd') };


sub render_gerente :WSDLPort('render_gerente') {
    my ($self, $c, $dados) = @_;

    $c->stash->{status_guiches} = $dados;
    $c->stash->{status_local} = $dados;
    $c->stash->{lista_encaminhamentos} = $dados;
    $c->stash->{template} = 'render/refresh_guiches.tt';
    $c->forward($c->view());
}

sub render_guiche_gerente :WSDLPort('render_guiche_gerente') {
    my ($self, $c, $dados) = @_;
    $c->stash->{guiche} = $dados->{guiche};
    $c->stash->{template} = 'render/guiche_gerente.tt';
    $c->forward($c->view());
}

1;

__END__

=head1 NAME

Gerente - Renderização da tela de Gerente

=head1 DESCRIPTION

Esse módulo é responsável pela renderização inicial da tela de
gerente.

=cut


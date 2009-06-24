package Fila::WebApp::Controller::CB::Render::Atendente;
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


sub render_atendente :WSDLPort('render_atendente') {
    my ($self, $c, $dados) = @_;

    $c->stash->{status_guiche} = $dados;

    if ($dados->{guiche}{estado} eq 'fechado') {
        $c->stash->{template} = 'cb/atendente/fechar_guiche.tt';
        $c->forward($c->view());
        $::connection->disconnect();
    } else {
        $c->stash->{template} = 'cb/atendente/refresh.tt';
        $c->forward($c->view());
    }
}


1;

__END__

=head1 NAME

Atendente - Renderização da tela de atendente

=head1 DESCRIPTION

Esse é o módulo responsável pela renderização inicial da tela de atendente.

=cut


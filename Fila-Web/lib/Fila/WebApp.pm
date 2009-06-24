package Fila::WebApp;
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

use Catalyst::Runtime '5.70';

use Catalyst qw/Unicode ConfigLoader Static::Simple Prototype/;

our $VERSION = '0.01';

__PACKAGE__->config( name => 'Fila::WebApp' );

{
    local %ENV;
    $ENV{CATALYST_ENGINE} = 'XMPP2';
    __PACKAGE__->setup;
};


__END__

=head1 NAME

WebApp - Aplicação nph

=head1 DESCRIPTION

Essa é a aplicação responsável por enviar informações para o navegador
e receber informações pelo XMPP.

=cut


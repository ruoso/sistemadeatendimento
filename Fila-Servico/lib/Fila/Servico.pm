package Fila::Servico;
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

use Catalyst qw/-Debug ConfigLoader Static::Simple/;

our $VERSION = '0.01';

__PACKAGE__->config( name => 'Fila::Servico' );

__PACKAGE__->setup;


1;

__END__

=head1 NAME

Servico - Módulo que implementa a aplicação de regras de negócio.

=head1 SYNOPSIS

  # dentro do diretorio Fila-Servico
  ./script/fila_servico_server.pl

=head1 DESCRIPTION

Esta é a aplicação que implementa todas as lógicas efetivas do sistema
de atendimento. Ela é acessada utilizando SOAP+XMPP.

=cut


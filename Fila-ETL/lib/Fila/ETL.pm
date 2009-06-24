package Fila::ETL;
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

our $VERSION = '0.01';

use Catalyst::Runtime '5.70';
use Catalyst qw( -Debug ConfigLoader );

__PACKAGE__->config( name => 'Fila::ETL',
		     'Plugin::ConfigLoader' => { file => 'fila_etl.yaml' }
    );
__PACKAGE__->setup;

1;

__END__

=head1 NAME

Fila::ETL - Aplicação de ETL

=head1 DESCRIPTION

Esta aplicação é usada para fazer o processo de ETL dos bancos de
dados transacionais do sistema de atendimento para o banco de dados
dimensional, que irá proporcionar a possibilidade de gerar as
estatísticas desejadas do sistema.

=cut


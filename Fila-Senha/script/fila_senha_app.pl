#!/usr/bin/perl
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

$ENV{CATALYST_ENGINE} = 'XMPP2';

use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use FindBin;
use lib "$FindBin::Bin/../lib";

use EV;
use AnyEvent;
use Net::XMPP2::Connection;
use Catalyst::Engine::XMPP2;
{
    no warnings;
    *Catalyst::Engine::XMPP2::loop = *EV::loop;
}

my $debug             = 0;
my $help              = 0;

my @argv = @ARGV;

GetOptions(
    'debug|d'             => \$debug,
    'help|?'              => \$help,
);

pod2usage(1) if $help;

if ( $debug ) {
    $ENV{CATALYST_DEBUG} = 1;
}

require Fila::Senha;

Fila::Senha->run();

1;

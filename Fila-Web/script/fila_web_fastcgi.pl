#!/usr/bin/perl -w
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

BEGIN { $ENV{CATALYST_ENGINE} ||= 'FastCGI' }

use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Fila::Web;

my $help = 0;
my ( $listen, $nproc, $pidfile, $manager, $detach, $keep_stderr );
 
GetOptions(
    'help|?'      => \$help,
    'listen|l=s'  => \$listen,
    'nproc|n=i'   => \$nproc,
    'pidfile|p=s' => \$pidfile,
    'manager|M=s' => \$manager,
    'daemon|d'    => \$detach,
    'keeperr|e'   => \$keep_stderr,
);

pod2usage(1) if $help;

Fila::Web->run( 
    $listen, 
    {   nproc   => $nproc,
        pidfile => $pidfile, 
        manager => $manager,
        detach  => $detach,
	keep_stderr => $keep_stderr,
    }
);

1;


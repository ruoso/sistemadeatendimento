package Fila::Painel::Model::Output;
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
use IO::Handle;
use Text::CSV_PP;
use base 'Catalyst::Model';

my $csv = Text::CSV_PP->new;

sub salvar {
    my ($self, $senhas) = @_;
    open my $output, '>', $Fila::Painel::output
      or die $!;

    for (@$senhas) {
        $csv->print($output, $_);
        print {$output} "\n";
    }
    close $output;
}

1;

__END__

=head1 NAME

Fila::Painel::Model::Output - Salva a lista de senhas em um arquivo csv

=head1 DESCRIPTION

Este Model salva a lista de senhas sendo chamadas em um arquivo csv
cujo nome é definido na configuração do sistema.

=cut


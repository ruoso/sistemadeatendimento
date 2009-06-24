package Fila::ETL::Model::Federado;
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
use base 'Catalyst::Model';

__PACKAGE__->mk_accessors('federacao');

sub target {
    my ($self, $c, $id, $class) = @_;
    return $c->model($self->federacao->{$id}.'::'.$class);
}

sub storage {
    my ($self, $c, $id) = @_;
    return $c->model($self->federacao->{$id})->schema->storage;
}

sub doeach {
    my ($self, $c, $code) = @_;
    foreach my $id (keys %{$self->federacao}) {
	$code->($id);
    }
}

1;

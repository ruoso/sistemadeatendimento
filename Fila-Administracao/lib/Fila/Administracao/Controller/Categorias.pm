package Fila::Administracao::Controller::Categorias;
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
use parent 'Catalyst::Controller';

sub index :Path('') :Args(0) {
    my ( $self, $c ) = @_;
    $c->stash->{categorias} = $c->model('DB::Categoria')->search
      ({},
       { order_by => 'nome' });
}

sub preload :Chained :PathPart('categorias') :CaptureArgs(1) {
    my ($self, $c, $id_categoria) = @_;
    $c->stash->{categoria} = $c->model('DB::Categoria')->find
      ({ id_categoria => $id_categoria });
}

sub ver :Chained('preload') :PathPart('') :Args(0) {
    my ($self, $c) = @_;

    unless ($c->req->param('submitted')) {
        $c->req->param($_,$c->stash->{categoria}->get_column($_))
          for qw(nome codigo)
    }
}

sub salvar :Chained('preload') :PathPart :Args(0) {
    my ($self, $c) = @_;
    if ($c->req->param('submitted')) {
        $c->stash->{categoria}->update
          ({ ( map { $_ => $c->req->param($_) }
               qw(nome codigo) ) });
        $c->res->redirect($c->uri_for('/categorias/'));
    }
}

sub criar :Local :Args(0) {
    my ($self, $c) = @_;
    if ($c->req->param('submitted')) {
        my $cat = $c->model('DB::Categoria')->create
          ({ ( map { $_ => $c->req->param($_) }
               qw(nome codigo) ) });
        $c->res->redirect($c->uri_for('/categorias/'));
    }
}

1;

__END__

=head1 NAME

Fila::Administracao::Controller::Categorias - Categorias de Atendimento

=head1 DESCRIPTION

Esse é o módulo que implementa a definição das categorias de
atendimento no sistema. Essa informação é usada conjuntamente com a
informação das configurações das categorias para gerir o atendimento.

=cut


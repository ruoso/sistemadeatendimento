package Fila::Administracao::Controller::Classes;
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
    my ($self, $c) = @_;
    $c->stash->{classes} = $c->model('DB::ClasseServico')->search
      ({},
       { order_by => 'nome' });
}

sub preload :Chained :PathPart('classes') :CaptureArgs(1) {
    my ($self, $c, $id_classe) = @_;
    $c->stash->{classes} = $c->model('DB::ClasseServico')->find
      ({ id_classe => $id_classe });
}


sub salvar :Chained('preload') :PathPart :Args(0) {
    my ($self, $c) = @_;
    $c->stash->{classes}->update
      ({ map { $_ => $c->req->param($_) }
         qw(nome ) });
    $c->res->redirect($c->uri_for('/classes'));
}

sub ver :Chained('preload') :PathPart('') :Args(0) {
    my ($self, $c) = @_;

    unless ($c->req->param('submitted')) {
        $c->req->param($_,$c->stash->{classes}->get_column($_))
          for qw(id_classe nome)
    }

}

sub criar :Local :Args(0) {
    my ($self, $c) = @_;

    $c->stash->{classes} = $c->model('DB::ClasseServico')->search({});

    if ($c->req->param('submitted')) {
        $c->stash->{classes}->create
          ({ ( map { $_ => $c->req->param($_) }
               qw(nome) ) });
        $c->res->redirect($c->uri_for('/classes'));
    }
}


1;

__END__

=head1 NAME

Fila::Administracao::Controller::Classes - Gerencia as classes de
serviço

=head1 DESCRIPTION

Gerencia as classes de serviços no sistema.

=cut


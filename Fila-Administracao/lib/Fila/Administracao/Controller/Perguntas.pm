package Fila::Administracao::Controller::Perguntas;
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
    $c->stash->{perguntas} = $c->model('DB::PerguntaAvaliacao')->search
      ({},
       { order_by => 'pergunta' });
}

sub preload :Chained :PathPart('perguntas') :CaptureArgs(1) {
    my ($self, $c, $id_pergunta) = @_;
    $c->stash->{perguntas} = $c->model('DB::PerguntaAvaliacao')->find
      ({ id_pergunta => $id_pergunta });
}

sub encerrar  :Chained('preload') :PathPart :Args(0) {
    my ($self, $c) = @_;

    $c->stash->{perguntas}->update(
       {  
        vt_fim => DateTime->now(time_zone => 'local') 
       });
    $c->res->redirect($c->uri_for('/perguntas'));
}

sub reabrir :Chained('preload') :PathPart :Args(0) {
    my ($self, $c) = @_;

    $c->stash->{perguntas}->update(
       {  
        vt_fim => 'infinity' 
       });
    $c->res->redirect($c->uri_for('/perguntas'));
}

sub salvar :Chained('preload') :PathPart :Args(0) {
    my ($self, $c) = @_;
    $c->stash->{perguntas}->update
      ({ map { $_ => $c->req->param($_) }
         qw(pergunta ) });
    $c->res->redirect($c->uri_for('/perguntas'));
}

sub ver :Chained('preload') :PathPart('') :Args(0) {
    my ($self, $c) = @_;

    unless ($c->req->param('submitted')) {
        $c->req->param($_,$c->stash->{perguntas}->get_column($_))
          for qw(id_pergunta pergunta )
    }

}

sub criar :Local :Args(0) {
    my ($self, $c) = @_;

    $c->stash->{perguntas} = $c->model('DB::PerguntaAvaliacao')->search({});

    if ($c->req->param('submitted')) {
        $c->stash->{perguntas}->create
          ({ vt_ini => DateTime->now(time_zone => 'local'),
             vt_fim => 'Infinity',
             ( map { $_ => $c->req->param($_) }
               qw(pergunta ) ) });
        $c->res->redirect($c->uri_for('/perguntas'));
    }
}


1;

__END__

=head1 NAME

Fila::Administracao::Controller::Perguntas - Gerencia as perguntas
para o opiniometro

=head1 DESCRIPTION

Este módulo implementa a interface de gerencia das perguntas do
opiniometro.

=cut


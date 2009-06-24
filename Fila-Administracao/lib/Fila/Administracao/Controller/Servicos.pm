package Fila::Administracao::Controller::Servicos;
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
    $c->stash->{servicos} = $c->model('DB::Servico')->search
      ({},
       { order_by => 'nome' });
}

sub preload :Chained :PathPart('servicos') :CaptureArgs(1) {
    my ($self, $c, $id_servico) = @_;
    $c->stash->{servicos} = $c->model('DB::Servico')->find
      ({ id_servico => $id_servico });
}


sub encerrar  :Chained('preload') :PathPart :Args(0) {
    my ($self, $c) = @_;

    $c->stash->{servicos}->update(
       {  
        vt_fim => DateTime->now(time_zone => 'local') 
       });
    $c->res->redirect($c->uri_for('/servicos'));
}

sub reabrir :Chained('preload') :PathPart :Args(0) {
    my ($self, $c) = @_;

    $c->stash->{servicos}->update(
       {  
        vt_fim => 'infinity' 
       });
    $c->res->redirect($c->uri_for('/servicos'));
}

sub salvar :Chained('preload') :PathPart :Args(0) {
    my ($self, $c) = @_;
    $c->stash->{servicos}->update
      ({ map { $_ => $c->req->param($_) }
         qw(nome id_classe ) });
    $c->res->redirect($c->uri_for('/servicos'));
}

sub ver :Chained('preload') :PathPart('') :Args(0) {
    my ($self, $c) = @_;

    unless ($c->req->param('submitted')) {
        $c->req->param($_,$c->stash->{servicos}->get_column($_))
          for qw(id_servico nome id_classe)
    }

    $c->stash->{classes} = $c->model('DB::ClasseServico')->search
      ({},{ order_by => 'id_classe' });

}

sub criar :Local :Args(0) {
    my ($self, $c) = @_;

    $c->stash->{servicos} = $c->model('DB::Servico')->search({});

    if ($c->req->param('submitted')) {
        $c->stash->{servicos}->create
          ({ vt_ini => DateTime->now(time_zone => 'local'),
             vt_fim => 'Infinity',
             ( map { $_ => $c->req->param($_) }
               qw(nome id_classe) ) });
        $c->res->redirect($c->uri_for('/servicos'));
    }
}


1;

__END__

=head1 NAME

Fila::Administraca::Controller::Servicos - Gerencia os serviços

=head1 DESCRIPTION

Este módulo implementa o controller para a gerencia dos serviços da
praca.

=cut


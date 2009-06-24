package Fila::Administracao::Controller::Locais;
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
    $c->stash->{locais} = $c->model('DB::Local')->search
      ({},
       { order_by => 'nome' });
}

sub preload :Chained :PathPart('locais') :CaptureArgs(1) {
    my ($self, $c, $id_local) = @_;
    $c->stash->{local} = $c->model('DB::Local')->find
      ({ id_local => $id_local });
}

sub encerrar :Chained('preload') :PathPart :Args(0) {
    my ($self, $c) = @_;
    $c->stash->{local}->update
      ({ vt_fim => DateTime->now(time_zone => 'local') });
    $c->res->redirect($c->uri_for('/locais'));
}

sub reabrir :Chained('preload') :PathPart :Args(0) {
    my ($self, $c) = @_;
    $c->stash->{local}->update
      ({ vt_fim => 'Infinity' });
    $c->res->redirect($c->uri_for('/locais'));
}

sub salvar :Chained('preload') :PathPart :Args(0) {
    my ($self, $c) = @_;
    $c->stash->{local}->update
      ({ map { $_ => $c->req->param($_) }
         qw(nome jid_senhas jid_painel jid_opiniometro) });
    $c->res->redirect($c->uri_for('/locais'));
}

sub ver :Chained('preload') :PathPart('') :Args(0) {
    my ($self, $c) = @_;

    unless ($c->req->param('submitted')) {
        $c->req->param($_,$c->stash->{local}->get_column($_))
          for qw(nome jid_senhas jid_painel jid_opiniometro)
    }

    $c->stash->{guiches} = $c->stash->{local}->guiches->search
      ({},{ order_by => 'identificador' });

    $c->stash->{configuracoes} = $c->stash->{local}->configuracoes_categoria->search
      ({},{ prefetch => 'categoria', order_by => [ 'me.vt_ini', 'categoria.nome' ] });

    $c->stash->{limites} = $c->stash->{local}->configuracoes_limite->search
      ({},{ prefetch => 'estado', order_by => [ 'me.vt_ini', 'estado.nome' ] });

    $c->stash->{conf_perguntas} = $c->stash->{local}->configuracoes_perguntas->search({});

    $c->stash->{conf_perguntas_praca} = $c->stash->{local}->configuracoes_perguntas_praca->search({});

}

sub criar :Local :Args(0) {
    my ($self, $c) = @_;
    if ($c->req->param('submitted')) {
        my $local = $c->model('DB::Local')->create
          ({ vt_ini => DateTime->now(time_zone => 'local'),
             vt_fim => 'Infinity',
             ( map { $_ => $c->req->param($_) }
               qw(nome jid_senhas jid_painel jid_opiniometro) ) });
        $c->res->redirect($c->uri_for('/locais/'.$local->id_local));
    }
}

1;

__END__

=head1 NAME

Fila::Administracao::Locais - Controller para a gestão dos locais

=head1 DESCRIPTION

É através desse módulo que são geridas as informações sobre as praças
de atendimento.

=cut


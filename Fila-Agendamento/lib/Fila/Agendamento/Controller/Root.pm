package Fila::Agendamento::Controller::Root;
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
use Business::BR::Ids qw( test_id canon_id );
use parent 'Catalyst::Controller';

__PACKAGE__->config->{namespace} = '';

sub index : Path Args(0) {
    my ($self, $c) = @_;
    # No primeiro passo vai mostrar o formulário para preencher os
    # dados pessoais e para escolher o local.
    $c->stash->{local} = $c->model('DB::Local')->search;
}


my %names =
  ( nome => 'nome',
    tipopessoa => 'pessoa f&iacute;sica ou jur&iacute;dica',
    cnpjf => 'CPF/CNPJ',
    id_local => 'pra&ccedil;a de atendimento',
    email => 'endere&ccedil;o de email' );

sub passo0 : Local Args(0) {
    my ($self, $c) = @_;
    # guardar os dados na sessao, e redirecionar para a escolha do local
    # data e hora.
    my @missing;
    for (qw(nome tipopessoa cnpjf id_local email)) {
        push @missing, $_ unless $c->req->param($_);
        $c->session->{$_} = $c->req->param($_);
        $c->stash->{$_} = $c->req->param($_);
    }

    if ($c->req->param('tipopessoa') eq 'F' && test_id('cpf', $c->req->param('cnpjf'))) {
        $c->session->{cnpjf} = canon_id('cpf',$c->req->param('cnpjf'));
    } elsif ($c->req->param('tipopessoa') eq 'J' && test_id('cnpj', $c->req->param('cnpjf'))) {
        $c->session->{cnpjf} = canon_id('cnpj',$c->req->param('cnpjf'));
    } else {
        push @missing, 'cnpjf';
    }

    if (@missing) {
        $c->stash->{error} =
          'Todos os campos s&atilde;o obrigat&oacute;rios: '.
            (join ', ', map { $names{$_} } @missing);
        $c->stash->{template} = 'index.tt';
        $c->forward('/index');
    } else {
        $c->res->redirect($c->uri_for('/'.$c->req->param('id_local').'/passo1'));
    }
}

sub preload :Chained :PathPart('') :CaptureArgs(1) {
    my ($self, $c, $id_local) = @_;
    $c->stash->{local} =
      $c->model('DB::Local')->find({ id_local => $id_local });
}

sub passo1 :Chained('preload') :Args(0) {
    my ($self, $c) = @_;
    $c->stash->{error} = $c->flash->{error};
}

sub passo2 :Chained('preload') :Args(2) {
    my ($self, $c, $date, $time) = @_;

    # vamos então criar o atendimento
    my ($ano, $mes, $dia) = split /-/, $date;
    my ($hora, $minuto) = split /:/, $time;
    my $dt = DateTime->new
      ( year => $ano,
        month => $mes,
        day => $dia,
        hour => $hora,
        minute => $minuto,
        time_zone => 'local' );
    my $senha = 'A'.$hora.(int($minuto / 15));

    my $dt_day_ini = $dt->clone();
    $dt_day_ini->set
      ( hour => 0,
        minute => 0,
        second => 0 );

    my $dt_day_fim = $dt->clone();
    $dt_day_fim->set
      ( hour => 23,
        minute => 59,
        second => 59 );

    $c->model('DB')->schema->txn_do
      (sub {
           my $at =
             $c->stash->{local}->atendimentos->find({ data => $dt });
           my $at2 =
             $c->stash->{local}->atendimentos->search
               ({ cnpjf => $c->session->{cnpjf},
                  -and => [ { data => { '>=' => $dt_day_ini } },
                            { data => { '<=' => $dt_day_fim } } ] })->first;
           if ($at) {
               $c->flash->{error} = '<P>Agendamento n&atilde;o realizado, hor&aacute;rio n&atilde;o dispon&iacute;vel.</P>';
               $c->res->redirect($c->uri_for('/'.$c->stash->{local}->id_local.'/passo1'));
           } if ($at2) {
               $c->flash->{error} =
                 '<P>Voc&ecirc; j&aacute; tinha um atendimento para esse dia, verifique as informa&ccedil;&otilde;es abaixo.</P>';
               $c->session->{id_atendimento} = $at2->id_atendimento;
               $c->res->redirect($c->uri_for('/atendimento/'));
           } else {
               $at = $c->stash->{local}->atendimentos->create
                 ({ ( map { $_ => $c->session->{$_} }
                      qw(nome tipopessoa cnpjf email)),
                    data => $dt,
                    senha => $senha });
               $c->session->{id_atendimento} = $at->id_atendimento;
               $c->res->redirect($c->uri_for('/atendimento/'));
           }
       });

}

sub atendimento :Local :Args(0) {
    my ($self, $c) = @_;
    my $id_atendimento = $c->session->{id_atendimento};
    $c->stash->{error} = $c->flash->{error};
    $c->stash->{atendimento} =
      $c->model('DB::Atendimento')->find
        ({ id_atendimento => $id_atendimento },
         { prefetch => 'local' });

    $c->stash->{email} =
      { to => $c->stash->{atendimento}->email,
        subject => 'Informações do seu agendamento',
        template => 'email_atendimento.tt' };
    $c->forward($c->view('Email'));
    $c->forward($c->view('TT'));
}

sub end :ActionClass('RenderView') {}

1;

__END__

=head1 NAME

Root - Controller principal do Agendamento

=head1 DESCRIPTION

Considerando a simplicidade do sistema de agendamento, toda a lógica
de interface é implementada nesse módulo.

=cut


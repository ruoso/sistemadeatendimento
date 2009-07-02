package Fila::Servico::Controller;
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
use UNIVERSAL 'isa';
use Sub::Name 'subname';
use Net::XMPP2::Util 'bare_jid';
use base 'Catalyst::Controller::SOAP';

my $tempcounter = 0;
# implements some tricks that won't be published to avoid the
# proliferation (as requested by #catalyst people)

sub _parse_MI_attr {
    no strict 'refs';
    my $classname = 'Fila::Servico::Action::TempMI'.($tempcounter++);
    @{$classname.'::ISA'} = qw(Fila::Servico::Action::MI);
    ( ActionClass => $classname );
}

sub create_action {
    my ($self, %args) = @_;

    if (exists $args{attributes}{ActionClass} &&
        ref $args{attributes}{ActionClass} eq 'ARRAY') {
        my @ActionClasses = @{$args{attributes}{ActionClass}};
        my ($mi) = grep { $_->isa('Fila::Servico::Action::MI') } @ActionClasses;
        if ($mi) {
            @ActionClasses = grep { !$_->isa('Fila::Servico::Action::MI') } @ActionClasses;
            $args{attributes}{ActionClass} = [$mi, @ActionClasses];
        }
    }

    $self->SUPER::create_action(%args);
}

sub end : Private {
  my $self = shift;
  my ($c) = @_;
  if ($c->stash->{soap} &&
      $c->stash->{soap}->fault &&
      $c->req->header('XMPP_Stanza') eq 'message') {

    # enviar o fault para renderização do erro.
    my $fault = $c->stash->{soap}->fault;
    my $from = bare_jid($c->req->header('XMPP_Stanza_from'));
    $c->model('SOAP')->transport->connection($c->engine->connection($c));
    $c->model('SOAP')->transport->addrs([$from.'/cb/render/error']);

    $c->model('SOAP::CB::Error')->render_error({ Fault => { faultcode => $fault->{code},
                                                            faultstring => $fault->{reason}.' - '.$fault->{detail} } });
    $c->error(0);
    return 0;
  } else {

    if ($c->stash->{refresh_gerente}) {
      $c->model('SOAP')->transport->connection($c->engine->connection($c));
      $c->model('SOAP')->transport->addrs(['motor@gestao.fila.vhost/ws/scheduler']);
      $c->model('SOAP::Scheduler')->refresh_gerente({ local => { id_local => $c->stash->{local}->id_local } });
    }

    if ($c->stash->{escalonar_senha}) {
      $c->model('SOAP')->transport->connection($c->engine->connection($c));
      $c->model('SOAP')->transport->addrs(['motor@gestao.fila.vhost/ws/scheduler']);
      $c->model('SOAP::Scheduler')->escalonar_senha({ local => { id_local => $c->stash->{local}->id_local } });
    }

    if ($c->stash->{refresh_painel}) {
      $c->model('SOAP')->transport->connection($c->engine->connection($c));
      $c->model('SOAP')->transport->addrs(['motor@gestao.fila.vhost/ws/scheduler']);
      $c->model('SOAP::Scheduler')->refresh_painel({ local => { id_local => $c->stash->{local}->id_local } });
    }

    if ($c->stash->{refresh_guiche}) {
      for my $id_guiche (@{$c->stash->{refresh_guiche}}) {
        $c->model('SOAP')->transport->connection($c->engine->connection($c));
        $c->model('SOAP')->transport->addrs(['motor@gestao.fila.vhost/ws/scheduler']);
        $c->model('SOAP::Scheduler')->refresh_guiche({ guiche => { id_guiche => $id_guiche } });
      }
    }

    return $self->SUPER::end(@_);
  }
}

{   package Fila::Servico::Action::MI;
    use base 'Catalyst::Action';
    sub new {
        my $self = shift;
        my ( $args ) = @_;
        if (exists $args->{attributes}{ActionClass} &&
            ref $args->{attributes}{ActionClass} eq 'ARRAY') {
            my @isa;

            my @others = grep { $_ ne $self }
              @{$args->{attributes}{ActionClass}};
            no strict 'refs';

            foreach my $other (@others) {
                unless ( Class::Inspector->loaded($other) ) {
                    require Class::Inspector->filename($other);
                }
            }

            push @isa, @others;

            @{$self.'::ISA'} = @isa;
        }
        $self->SUPER::new(@_);
    }
}

1;

__END__


=head1 NAME

Controller - Superclasse dos controllers do Fila-Servico

=head1 DESCRIPTION

Este módulo implementa características comuns a todos os controllers
da aplicação fila-serviço, incluindo o attributo de métodos "MI", que
permite a uma ação de controller descender de mais de um tipo de ação,
o que no caso do Fila-Serviço, é importante para que a ação seja ao
mesmo tempo visível como uma ação SOAP, e ao mesmo tempo encapsule a
criação de uma transação para toda a ação.

=cut


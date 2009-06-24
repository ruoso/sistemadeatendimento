package Fila::WebApp::Controller::Root;
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
use DateTime::Format::XSD;
use base 'Catalyst::Controller';

__PACKAGE__->config->{namespace} = '';

sub auto : Private {
    my ($self, $c) = @_;
    $c->stash->{dtf} = DTFormatter->new;
    return 0 if $c->req->header('XMPP_Stanza') &&
      $c->req->header('XMPP_Stanza') eq 'presence';
    return 1;
}

sub end : Private {
    my ($self, $c) = @_;
    do {
        $c->log->debug('No output being sent for action.');
        return 1;
    } if $c->stash->{no_output};
    $c->forward($c->view());
}

{   package DTFormatter;
    sub new { bless {}, 'DTFormatter' };
    sub f {
        my ($self, $dt) = @_;
        if ($dt && ref($dt)) {
            return $dt->set_time_zone('local')->strftime("%H:%M:%S");
        } elsif ($dt) {
            return DateTime::Format::XSD->parse_datetime($dt)->set_time_zone('local')->strftime("%H:%M:%S");
        } else {
            return ''
        }

    }
}
1;

__END__

=head1 NAME

Root - Controller raiz do WebApp

=head1 DESCRIPTION

Este controller define algumas características comuns a toda a aplicação.

=cut


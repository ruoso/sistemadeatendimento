package Fila::Web::Controller::Root;
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
use Digest::MD5;
use base 'Catalyst::Controller';

__PACKAGE__->config->{namespace} = '';

sub index : Private {
    my ($self, $c) = @_;
    $c->session->{user_jid} = '';
    $c->forward($c->view);
}

sub emissor : Local {
    my ($self, $c) = @_;
    $c->session->{user_jid} = '';
    $c->forward($c->view);
}

sub authenticated : Local {
    my ($self, $c) = @_;
    
    my $jid = $c->req->param('user_jid');
    my $s = $c->req->param('s');
    
    if (Digest::MD5::md5_hex($jid.'senha de controle interno do sistema')
        eq $s) {
        $c->session->{user_jid} = $c->req->param('user_jid');
        $c->res->body('<!-- ok -->');
    } else {
        $c->res->status(404);
        $c->res->body('Usuario invalido');
    }
}

sub solicitar_senha : Local {
	my ($self, $c, $id_categoria) = @_;
	
    $c->model('SOAP')->transport->addrs(['motor@gestao.fila.vhost/ws/gestao/senha']);	
    my $atendimento = $c->model('SOAP::Gestao::Senha')->solicitar_senha(
    	{ atendimento => { 
    		id_categoria => $id_categoria 
    		} 
    	}
    	);
	
	$c->stash->{atendimento} = $atendimento;
	
	$c->forward('/render/emissor.tt');
}

sub end : Private {
    $::connection->drain() if $::connection;
}


1;

__END__

=head1 NAME

Root - Características gerais da aplicação

=head1 DESCRIPTION

Esse módulo implementa algumas ações gerais para a aplicação de callback.

=cut


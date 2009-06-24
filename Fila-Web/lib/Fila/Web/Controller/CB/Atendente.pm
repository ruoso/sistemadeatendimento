package Fila::Web::Controller::CB::Atendente;
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
use base 'Catalyst::Controller';

#recebe os eventos do navegador e os redireciona para filawebapp.

sub fechar_guiche : Local {
    my ($self, $c) = @_;

    $c->model('SOAP')->transport
        ->addrs([$c->session->{user_jid}.'/cb/atendente']);
    my $req = $c->model('SOAP::Atendente')->fechar_guiche
     ({ callback_request =>
        { param =>
          [ map {( name => $_,
                   value => $c->req->param($_) )}
                keys %{$c->req->params} ]}});
}

sub enviar_chat : Local {
    my ($self, $c) = @_;
	#não pode deixar o name vazio, tem que colocar ele com o nome do gerente dda vez será que pode
	my $too = $c->req->param('chatTo');
    my $texto = $c->req->param('txtTexto');

    $c->model('SOAP')->transport
        ->addrs([$c->session->{user_jid}.'/cb/atendente']);
    my $req = $c->model('SOAP::Atendente')->enviar_chat
     ({ callback_request => 
        { param =>
          [ { name => $too,
              value => $texto } ]}});

}

sub listar_guiches_encaminhar : Local {
    my ($self, $c) = @_;

    $c->model('SOAP')->transport
        ->addrs([$c->session->{user_jid}.'/cb/atendente']);

    my $req = $c->model('SOAP::Atendente')->listar_guiches_encaminhar
     ({ callback_request =>
        { param =>
          [  ] }});
}

sub encaminhar_atendimento : Local {
    my ($self, $c) = @_;

    my $id_guiche  = $c->req->param('mesaDestino');
    my $motivo  = $c->req->param('motivoEnc');

    $c->model('SOAP')->transport
        ->addrs([$c->session->{user_jid}.'/cb/atendente']);

    my $req = $c->model('SOAP::Atendente')->encaminhar_atendimento
     ({ callback_request =>
        { param =>
          [ { name => $motivo,
              value => $id_guiche } ]}});
}

sub devolver_senha : Local {
    my ($self, $c) = @_;

    $c->model('SOAP')->transport
        ->addrs([$c->session->{user_jid}.'/cb/atendente']);
    my $req = $c->model('SOAP::Atendente')->devolver_senha
     ({ callback_request => 
        { param =>
          [ { name => '',
              value => '' } ]}});
}

sub iniciar_atendimento : Local {
    my ($self, $c) = @_;

    $c->model('SOAP')->transport
        ->addrs([$c->session->{user_jid}.'/cb/atendente']);
    my $req = $c->model('SOAP::Atendente')->iniciar_atendimento
     ({ callback_request => 
        { param =>
          [ { name => '',
              value => '' } ]}});
}

sub atender_no_show : Local {
    my ($self, $c, $id) = @_;

    $c->model('SOAP')->transport
        ->addrs([$c->session->{user_jid}.'/cb/atendente']);
    my $req = $c->model('SOAP::Atendente')->atender_no_show
     ({ callback_request => 
        { param =>
          [ { name => 'id_atendimento',
              value => $id } ]}});
}

sub concluir_atendimento : Local {
    my ($self, $c) = @_;

    $c->model('SOAP')->transport
        ->addrs([$c->session->{user_jid}.'/cb/atendente']);
    my $req = $c->model('SOAP::Atendente')->concluir_atendimento
     ({ callback_request => 
        { param =>
          [ { name => '',
              value => '' } ]}});
}

sub disponivel : Local {
    my ($self, $c) = @_;

    $c->model('SOAP')->transport->addrs([$c->session->{user_jid}.'/cb/atendente']);
    my $req = $c->model('SOAP::Atendente')->disponivel
     ({ callback_request => 
        { param =>
          [ { name => '',
              value => '' } ]}});

}

sub listar_no_show : Local {
    my ($self, $c) = @_;

    $c->model('SOAP')->transport
        ->addrs([$c->session->{user_jid}.'/cb/atendente']);
    my $req = $c->model('SOAP::Atendente')->listar_no_show
     ({ callback_request => 
        { param =>
          [ { name => '',
              value => '' } ]}});

}

sub registrar_no_show : Local {
    my ($self, $c) = @_;

    $c->model('SOAP')->transport
        ->addrs([$c->session->{user_jid}.'/cb/atendente']);
    my $req = $c->model('SOAP::Atendente')->registrar_no_show
     ({ callback_request => 
        { param =>
          [ { name => '',
              value => '' } ]}});

}

sub iniciar_pausa : Local {
    my ($self, $c) = @_;

    $c->model('SOAP')->transport
        ->addrs([$c->session->{user_jid}.'/cb/atendente']);
    my $req = $c->model('SOAP::Atendente')->iniciar_pausa
     ({ callback_request => 
        { param =>
          [ { name => '',
              value => '' } ]}});
    

}

sub setar_motivo_pausa : Local {
    my ($self, $c) = @_;

    my $motivo = $c->req->param('txtMotivo');


    $c->model('SOAP')->transport
        ->addrs([$c->session->{user_jid}.'/cb/atendente']);
    my $req = $c->model('SOAP::Atendente')->setar_motivo_pausa
     ({ callback_request => 
        { param => 
          [ { name => 'pausa_motivo',
              value => $motivo } ]}});
    

}

sub iniciar_servico_interno : Local {
    my ($self, $c, $id_servico) = @_;

    $c->model('SOAP')->transport
        ->addrs([$c->session->{user_jid}.'/cb/atendente']);
    my $req = $c->model('SOAP::Atendente')->iniciar_servico_interno
     ({ callback_request => 
        { param =>
          [ { name => 'id_servico',
              value => $id_servico } ]}});

} 

sub listar_servicos : Local {
   my ($self, $c) = @_;

    $c->model('SOAP')->transport
        ->addrs([$c->session->{user_jid}.'/cb/atendente']);
   my $req = $c->model('SOAP::Atendente')->listar_servicos
     ({ callback_request => 
        { param =>
          [ { name => '',
              value => '' } ]}});

}

sub listar_servicos_atendimento : Local {
   my ($self, $c) = @_;

    $c->model('SOAP')->transport
        ->addrs([$c->session->{user_jid}.'/cb/atendente']);
   my $req = $c->model('SOAP::Atendente')->listar_servicos_atendimento
     ({ callback_request => 
        { param =>
          [ { name => '',
              value => '' } ]}});

}

sub fechar_servico_interno : Local {
   my ($self, $c) = @_;

    $c->model('SOAP')->transport
        ->addrs([$c->session->{user_jid}.'/cb/atendente']);
   my $req = $c->model('SOAP::Atendente')->fechar_servico_interno
     ({ callback_request => 
        { param =>
          [ { name => '',
              value => '' } ]}});

}

sub setar_info_interno : Local {
    my ($self, $c) = @_;

    my $informacoes = $c->req->param('txtInformacoes');

    $c->model('SOAP')->transport
        ->addrs([$c->session->{user_jid}.'/cb/atendente']);
    my $req = $c->model('SOAP::Atendente')->setar_info_interno
     ({ callback_request => 
        { param => 
          [ { name => 'informacoes',
              value => $informacoes } ]}});
    

}
sub iniciar_servico_atendimento : Local {
    my ($self, $c, $id_servico) = @_;

    $c->model('SOAP')->transport
        ->addrs([$c->session->{user_jid}.'/cb/atendente']);
    my $req = $c->model('SOAP::Atendente')->iniciar_servico_atendimento
     ({ callback_request => 
        { param =>
          [ { name => 'id_servico',
              value => $id_servico } ]}});

} 

sub fechar_servico_atendimento : Local {
   my ($self, $c, $id_servico) = @_;

    $c->model('SOAP')->transport
        ->addrs([$c->session->{user_jid}.'/cb/atendente']);
   my $req = $c->model('SOAP::Atendente')->fechar_servico_atendimento
     ({ callback_request => 
        { param =>
          [ { name => 'id_servico',
              value => $id_servico } ]}});

}
sub setar_info_atendimento : Local {
    my ($self, $c) = @_;

    my $informacoes = $c->req->param('txtInformacoes');
    my $servico = $c->req->param('id_servico');

    $c->model('SOAP')->transport
        ->addrs([$c->session->{user_jid}.'/cb/atendente']);
    my $req = $c->model('SOAP::Atendente')->setar_info_atendimento
     ({ callback_request => 
        { param => 
          [ { name => $servico,
              value => $informacoes } ]}});
    

}

sub retornar_pausa : Local {
    my ($self, $c) = @_;
    
    $c->model('SOAP')->transport
        ->addrs([$c->session->{user_jid}.'/cb/atendente']);
    my $req = $c->model('SOAP::Atendente')->retornar_pausa
        ({ callback_request =>
            { param =>
                [ { name => '',
                    value => '' } ] } } );

}

sub mudar_senha : Local {
    my ($self, $c) = @_;
    my $novasenha = $c->req->param('nova_senha');
    my $senhaatual = $c->req->param('senha_atual');
    my $confsenha = $c->req->param('confirmar_senha');
    my $jid = $c->req->param('jid');
    
    unless(($confsenha eq $novasenha) || ($confsenha) || ($novasenha) ){
    	$c->stash->{error_message} = 'Senhas não conferem ou não foram informadas';
	    $c->stash->{mudar_senha} = 'Senhas não conferem ou não foram informadas';
	    return $c->forward('/render/error_message');
	}
    
    $c->model('SOAP')->transport->addrs([$jid]);
    
    my $req = $c->model('SOAP::Atendente')->mudar_senha
        ({ callback_request =>
            { param =>
                [ { name => $novasenha,
                    value => $senhaatual } ] }	 } );

}


1;

__END__

=head1 NAME

Atendente - Callback do atendente

=head1 DESCRIPTION

Traduz requisições http para mensagens SOAP+XMPP

=cut


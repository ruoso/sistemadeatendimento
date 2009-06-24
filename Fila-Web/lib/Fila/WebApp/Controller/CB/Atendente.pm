package Fila::WebApp::Controller::CB::Atendente;
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
use Encode;
use base 'Catalyst::Controller::SOAP';

__PACKAGE__->config->{wsdl} =
  {wsdl => Fila::WebApp->path_to('schemas/FilaWeb.wsdl')};

sub registrar_no_show : WSDLPort('FilaWebAtendenteCallback') {
    my ($self, $c) = @_;

    $c->model('SOAP')->transport->addrs(['motor@gestao.fila.vhost/ws/gestao/atendente']);
    my $registrar_no_show = $c->model('SOAP::Gestao::Atendente')
          ->registrar_no_show({ atendimento => {} });

}

sub listar_no_show : WSDLPort('FilaWebAtendenteCallback') {
    my ($self, $c) = @_;

    $c->model('SOAP')->transport->addrs(['motor@gestao.fila.vhost/ws/gestao/atendente']);
    my $lista_no_show = $c->model('SOAP::Gestao::Atendente')
          ->listar_no_show({ atendimento => {} });

    if ($lista_no_show->{Fault}) {
        $c->stash->{error_message} = $lista_no_show->{Fault}{faultstring};
        return $c->forward('/render/error_message');
    }

    $c->model('SOAP')->transport->addrs(['motor@gestao.fila.vhost/ws/gestao/atendente']);
    $c->stash->{status_guiche} = $c->model('SOAP::Gestao::Atendente')
          ->status_guiche({ guiche => {} });

    $c->stash->{lista_no_show} = $lista_no_show;

    $c->stash->{template} = 'cb/atendente/refresh.tt';
    $c->forward($c->view());
}

sub listar_guiches_encaminhar : WSDLPort('FilaWebAtendenteCallback') {
    my ($self, $c) = @_;

    $c->model('SOAP')->transport->addrs(['motor@gestao.fila.vhost/ws/gestao/guiche']);
    my $lista_guiches = $c->model('SOAP::Gestao::Guiche')
      ->listar_guiches({ local => {} });

    if ($lista_guiches->{Fault}) {
        $c->stash->{error_message} = $lista_guiches->{Fault}{faultstring};
        return $c->forward('/render/error_message');
    }

    $c->model('SOAP')->transport->addrs(['motor@gestao.fila.vhost/ws/gestao/atendente']);
    $c->stash->{status_guiche} = $c->model('SOAP::Gestao::Atendente')
          ->status_guiche({ guiche => {} });

    $c->stash->{lista_guiches_encaminhar} = $lista_guiches;

    $c->stash->{template} = 'cb/atendente/refresh.tt';
    $c->forward($c->view());

}

sub encaminhar_atendimento : WSDLPort('FilaWebAtendenteCallback') {
    my ($self, $c,$query) = @_;

    my $id_guiche = $query->{callback_request}{param}[0]{value};
    my $motivo = $query->{callback_request}{param}[0]{name};
    
    $c->model('SOAP')->transport->addrs(['motor@gestao.fila.vhost/ws/gestao/atendente']);
    my $encaminhar_atendimento = $c->model('SOAP::Gestao::Atendente')
          ->encaminhar_atendimento({ guiche => { id_guiche => $id_guiche, pausa_motivo => $motivo } });
}

sub atender_no_show : WSDLPort('FilaWebAtendenteCallback') {
    my ($self, $c,$query) = @_;

    my %params = map { $_->{name} => $_->{value} } @{$query->{callback_request}{param}};
    $c->model('SOAP')->transport->addrs(['motor@gestao.fila.vhost/ws/gestao/atendente']);
    my $iniciar_atendimento = $c->model('SOAP::Gestao::Atendente')
          ->atender_no_show({ atendimento => \%params });
}

sub fechar_guiche : WSDLPort('FilaWebAtendenteCallback') {

    #fechar_guiche irá disparar o mesmo evento no motor do sistema.

    my ($self, $c, $query) = @_;

    $c->model('SOAP')->transport->addrs(['motor@gestao.fila.vhost/ws/gestao/atendente']);
    my $fechar_guiche = $c->model('SOAP::Gestao::Atendente')
          ->fechar_guiche({ guiche => {} });

}

sub devolver_senha : WSDLPort('FilaWebAtendenteCallback') {
    my ($self, $c) = @_;

    $c->model('SOAP')->transport->addrs(['motor@gestao.fila.vhost/ws/gestao/atendente']);
    my $iniciar_atendimento = $c->model('SOAP::Gestao::Atendente')
          ->devolver_senha({ atendimento => {} });
}

sub iniciar_atendimento : WSDLPort('FilaWebAtendenteCallback') {
    my ($self, $c) = @_;

    $c->model('SOAP')->transport->addrs(['motor@gestao.fila.vhost/ws/gestao/atendente']);
    my $iniciar_atendimento = $c->model('SOAP::Gestao::Atendente')
          ->iniciar_atendimento({ atendimento => {} });
}

sub concluir_atendimento : WSDLPort('FilaWebAtendenteCallback'){
    my ($self, $c) = @_;

    $c->model('SOAP')->transport->addrs(['motor@gestao.fila.vhost/ws/gestao/atendente']);
    my $concluir_atendimento = $c->model('SOAP::Gestao::Atendente')
          ->concluir_atendimento({ atendimento => {} });
}

sub disponivel : WSDLPort('FilaWebAtendenteCallback'){
    my ($self, $c) = @_;

    $c->model('SOAP')->transport->addrs(['motor@gestao.fila.vhost/ws/gestao/atendente']);
    my $concluir_atendimento = $c->model('SOAP::Gestao::Atendente')
          ->disponivel({ guiche => {} });
}

sub setar_motivo_pausa :  WSDLPort('FilaWebAtendenteCallback') {
    my ($self, $c, $query) = @_;

    my $motivo = $query->{callback_request}{param}[0]{value};
    $c->model('SOAP')->transport->addrs(['motor@gestao.fila.vhost/ws/gestao/atendente']);
    my $setar_motivo_pausa = $c->model('SOAP::Gestao::Atendente')
          ->setar_motivo_pausa({ guiche => { pausa_motivo => $motivo } });

}

sub setar_info_interno :  WSDLPort('FilaWebAtendenteCallback') {
    my ($self, $c, $query) = @_;

    my $informacoes = $query->{callback_request}{param}[0]{value};
    $c->model('SOAP')->transport->addrs(['motor@gestao.fila.vhost/ws/gestao/atendente']);
    my $setar_info_interno = $c->model('SOAP::Gestao::Atendente')
          ->setar_info_interno({ servico => { informacoes => $informacoes } });
}

sub enviar_chat :  WSDLPort('FilaWebAtendenteCallback') {
    my ($self, $c, $query) = @_;
    #Enviar agora como pacote XMPP2

    #tem que procurar entre os funcionários quem eh gerente no momento, acho que essa busca deve ser feita no fila/web.
    my $too = $query->{callback_request}{param}[0]{name};
    $too .= '/cb/gerente/receber_chat';
    #my $too = 'gerente@people.fila.vhost/cb/gerente/receber_chat';
    my $texto = $query->{callback_request}{param}[0]{value};

    $c->stash->{texto} = $texto;

    $c->engine->send_message($c, $too, 'chat',
        sub {
            my $writer = shift;
            $writer->startTag('Body');
            $writer->characters($texto);
            $writer->endTag('Body');
        });
    $c->stash->{now} = DateTime->now(time_zone => 'local')->strftime('%H:%M');

    $c->stash->{template} = 'cb/atendente/enviar_chat.tt';
    $c->forward($c->view());
}

sub receber_chat : Local {
    my ($self, $c) = @_;
    #Recebido pacote de chat do gerente

    my $texto = $c->req->body . '';
    $c->stash->{now} = DateTime->now(time_zone => 'local')->strftime('%H:%M');

    return unless $texto =~ s/(^\<body\>|\<\/body\>$)//gi;

    $c->stash->{texto} = $texto;
    $c->stash->{template} = 'cb/atendente/receber_chat.tt';
    $c->forward($c->view());
}

sub iniciar_pausa :  WSDLPort('FilaWebAtendenteCallback') {

    my ($self, $c) = @_;

    $c->model('SOAP')->transport->addrs(['motor@gestao.fila.vhost/ws/gestao/atendente']);
    my $iniciar_pausa = $c->model('SOAP::Gestao::Atendente')
          ->iniciar_pausa({ guiche => {} });


}

sub iniciar_servico_interno :  WSDLPort('FilaWebAtendenteCallback') {

    my ($self, $c, $query) = @_;

    my $id_servico = $query->{callback_request}{param}[0]{value};

    $c->model('SOAP')->transport->addrs(['motor@gestao.fila.vhost/ws/gestao/atendente']);
    my $iniciar_servico_interno = $c->model('SOAP::Gestao::Atendente')
          ->iniciar_servico_interno({ servico => { id_servico => $id_servico }  });

}

sub listar_servicos : WSDLPort('FilaWebAtendenteCallback') {
    my ($self, $c) = @_;

    $c->model('SOAP')->transport->addrs(['motor@gestao.fila.vhost/ws/gestao/atendente']);
    my $listar_servicos = $c->model('SOAP::Gestao::Atendente')
          ->listar_servicos({ servico => {} });

    if ($listar_servicos->{Fault}) {
        $c->stash->{error_message} = $listar_servicos->{Fault}{faultstring};
        return $c->forward('/render/error_message');
    }


    $c->model('SOAP')->transport->addrs(['motor@gestao.fila.vhost/ws/gestao/atendente']);
    $c->stash->{status_guiche} = $c->model('SOAP::Gestao::Atendente')
          ->status_guiche({ guiche => {} });

    $c->stash->{lista_servicos} = $listar_servicos;

    $c->stash->{template} = 'cb/atendente/refresh.tt';
    $c->forward($c->view());


}

sub listar_servicos_atendimento : WSDLPort('FilaWebAtendenteCallback') {
    my ($self, $c) = @_;

    $c->model('SOAP')->transport->addrs(['motor@gestao.fila.vhost/ws/gestao/atendente']);
    my $listar_servicos_atendimento = $c->model('SOAP::Gestao::Atendente')
          ->listar_servicos_atendimento({ servico => {} });

    if ($listar_servicos_atendimento->{Fault}) {
        $c->stash->{error_message} = $listar_servicos_atendimento->{Fault}{faultstring};
        return $c->forward('/render/error_message');
    }


    $c->model('SOAP')->transport->addrs(['motor@gestao.fila.vhost/ws/gestao/atendente']);
    $c->stash->{status_guiche} = $c->model('SOAP::Gestao::Atendente')
          ->status_guiche({ guiche => {} });

    $c->stash->{lista_servicos_atendimento} = $listar_servicos_atendimento;

    $c->stash->{template} = 'cb/atendente/refresh.tt';
    $c->forward($c->view());


}

sub fechar_servico_interno : WSDLPort('FilaWebAtendenteCallback') {
    my ($self, $c) = @_;

    $c->model('SOAP')->transport->addrs(['motor@gestao.fila.vhost/ws/gestao/atendente']);
    my $fechar_servico_interno = $c->model('SOAP::Gestao::Atendente')
          ->fechar_servico_interno({ servico => {} });

}

sub iniciar_servico_atendimento :  WSDLPort('FilaWebAtendenteCallback') {

    my ($self, $c, $query) = @_;

    my $id_servico = $query->{callback_request}{param}[0]{value};

    $c->model('SOAP')->transport->addrs(['motor@gestao.fila.vhost/ws/gestao/atendente']);
    my $iniciar_servico_atendimento = $c->model('SOAP::Gestao::Atendente')
          ->iniciar_servico_atendimento({ servico => { id_servico => $id_servico }  });

}

sub fechar_servico_atendimento : WSDLPort('FilaWebAtendenteCallback') {
    my ($self, $c, $query) = @_;

    my $id_servico = $query->{callback_request}{param}[0]{value};

    $c->model('SOAP')->transport->addrs(['motor@gestao.fila.vhost/ws/gestao/atendente']);
    my $fechar_servico_atendimento = $c->model('SOAP::Gestao::Atendente')
          ->fechar_servico_atendimento({ servico => { id_servico => $id_servico } });

}
sub setar_info_atendimento :  WSDLPort('FilaWebAtendenteCallback') {
    my ($self, $c, $query) = @_;

    my $informacoes = $query->{callback_request}{param}[0]{value};
    my $servico = $query->{callback_request}{param}[0]{name};
    
    $c->model('SOAP')->transport->addrs(['motor@gestao.fila.vhost/ws/gestao/atendente']);
    my $setar_info_atendimento = $c->model('SOAP::Gestao::Atendente')
          ->setar_info_atendimento({ servico => { informacoes => $informacoes, id_servico => $servico } });
}

sub retornar_pausa : WSDLPort('FilaWebAtendenteCallback') {
    my ($self, $c) = @_;
    
    $c->model('SOAP')->transport->addrs(['motor@gestao.fila.vhost/ws/gestao/atendente']);
    my $retornar_pausa = $c->model('SOAP::Gestao::Atendente')
        ->retornar_pausa({ guiche => {} });
        
}

sub mudar_senha : WSDLPort('FilaWebAtendenteCallback') {
    my ($self, $c, $query) = @_;
    
    my $senhaatual = $query->{callback_request}{param}[0]{value};
    my $novasenha = $query->{callback_request}{param}[0]{name};
    
    $c->model('SOAP')->transport->addrs(['motor@gestao.fila.vhost/ws/gestao/atendente']);
    my $mudar_senha = $c->model('SOAP::Gestao::Atendente')
        ->mudar_senha({ guiche => { senha => $senhaatual, estado => $novasenha } });
    
    if ($mudar_senha->{guiche}{senha} eq 'Senha alterada com sucesso') {
    	$c->stash->{error_message} = $mudar_senha->{guiche}{senha};
    	#reload no atendente
	    return $c->forward('/render/aviso');
    } else { 
	    $c->stash->{error_message} = $mudar_senha->{Fault}{faultstring};
	    return $c->forward('/render/error_message');
    }
    
        
}


1;

__END__

=head1 NAME

Atendente - Lógica de interface do atendente

=head1 DESCRIPTION

Esse é o módulo que recebe os callbacks de acordo com a interação
tanto com o usuário quanto com os outros componentes do sistema no
contexto do atendente.

=cut


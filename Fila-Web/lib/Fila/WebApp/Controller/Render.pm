package Fila::WebApp::Controller::Render;
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
use EV;
use base 'Catalyst::Controller';

# usamos o Regex dispatch para não gerar um endpoint
# no XMPP.
sub base : Regex('^render/base$') {}
sub error : Regex('^render/error$') {
    my ($self, $c) = @_;
    $c->stash->{template} = 'render/error_message.tt';
    $c->forward($c->view());
}

sub disconnected : Regex('^render/disconnected$') {
    my ($self, $c) = @_;
    $c->stash->{template} = 'render/disconnected.tt';
    #$c->forward($c->view());
        $c->view()->process($c);

}
sub error_message : Private {
    my ($self, $c) = @_;
    $c->stash->{template} = 'render/error_message.tt';
    $c->forward($c->view());
}

sub fechar : Private {
    my ($self, $c) = @_;
    $c->stash->{template} = 'render/fechar.tt';
    $c->forward($c->view());
}

sub aviso : Private {
    my ($self, $c) = @_;
    $c->stash->{template} = 'render/aviso.tt';
    $c->forward($c->view());
}

sub escolher_guiche : Private {
    
    #escolher_guiche renderiza uma página que lista os guichês disponíveis
    #para serem abertos pelo atendente.
    
    my ($self, $c) = @_;

    $c->model('SOAP')->transport->addrs(['motor@gestao.fila.vhost/ws/gestao/guiche']);
    my $lista_guiches= $c->model('SOAP::Gestao::Guiche')
          ->listar_guiches({ local => {} });
          
    if ($lista_guiches->{Fault}) {
        $c->forward('/render/error_message');
        EV::unloop(EV::UNLOOP_ALL);
    } else {
        $c->stash->{lista_guiches} = $lista_guiches;
        $c->stash->{template} = 'render/escolher_guiche.tt';
    }

}

sub authenticated : Regex('^render/authenticated$') {
    my ($self, $c) = @_;

    # desenhamos logo o template do authenticated...
    $c->stash->{user_jid} = $::user_jid;
    $c->stash->{'s'} = Digest::MD5::md5_hex($::user_jid.'senha de controle interno do sistema');
    $c->forward($c->view());

    $c->model('SOAP')->transport->connection($::connection);

    my $mode = 'gerente';
    if ($::major_mode eq 'agents') {
      $mode = 'emissor';
      return $c->forward('/render/'.$mode);
    }

    $c->model('SOAP')->transport->addrs(['motor@gestao.fila.vhost/ws/gestao/local']);
    my $dados_local = $c->model('SOAP::Gestao::Local')
        ->dados_local({ local => {} });

    if ($dados_local->{Fault} &&
        $dados_local->{Fault}{faultstring} =~ /Permissao Negada/) {
        $c->model('SOAP')->transport->addrs(['motor@gestao.fila.vhost/ws/gestao/guiche']);
        $dados_local = $c->model('SOAP::Gestao::Guiche')
          ->dados_local({ local => {} });
        $mode = 'atendente'; 
    } elsif ($dados_local->{Fault}) {
        $c->stash->{error_message} = $dados_local->{Fault}{faultstring};
        return $c->forward('/render/error_message');
    }

	
    if ($dados_local->{Fault} &&
        $dados_local->{Fault}{faultstring} =~ /Permissao Negada/) {
        $c->stash->{error_message} = $dados_local->{Fault}{faultstring};
        return $c->forward('/render/error_message');
        EV::unloop(EV::UNLOOP_ALL);
    } elsif ($dados_local->{Fault}) {
        $c->stash->{error_message} = $dados_local->{Fault}{faultstring};
        return $c->forward('/render/error_message');
    } else {
        $c->stash->{dados_local} = $dados_local;
        $c->forward('/render/'.$mode);
    }

    
}

sub emissor : Private {
	my ($self, $c) = @_;

    $c->stash->{template} = 'render/emissor.tt';
    $c->model('SOAP')->transport->addrs(['motor@gestao.fila.vhost/ws/gestao/senha']);
    my $dados_local = $c->model('SOAP::Gestao::Senha')
        ->dados_local({ local => {} });

    if ($dados_local->{Fault} &&
        $dados_local->{Fault}{faultstring} =~ /Permissao Negada/) {
        $c->stash->{status_local} = 'Local está fechado. Vai esperar uma notificacao.';
    } elsif ($dados_local->{Fault}) {
        $c->stash->{status_local} = 'Erro ao obter os dados do local: '.$dados_local->{Fault}{faultstring};
    } else {
        $c->stash->{status_local} = 'Abrindo para senhas';
	    $c->model('SOAP')->transport->addrs(['motor@gestao.fila.vhost/ws/gestao/senha']);	
	    my $categorias = $c->model('SOAP::Gestao::Senha')->listar_categorias({ local => {} });
		if ($categorias->{Fault}) {
	        $c->stash->{error_message} = $categorias->{Fault}{faultstring};
	        return $c->forward('/render/error_message');
	    } else {
			$c->stash->{categorias} = $categorias;
			$c->forward('/render/emissor.tt');
	    }
    }
}

sub atendente : Private {
    my ($self, $c) = @_;

    $c->stash->{template} = 'render/atendente.tt';
    $c->model('SOAP')->transport->addrs(['motor@gestao.fila.vhost/ws/gestao/atendente']);
    my $status_guiche = $c->model('SOAP::Gestao::Atendente')
          ->status_guiche({ guiche => {} });

    if ($status_guiche->{Fault} &&
        $status_guiche->{Fault}{faultstring} =~ /Permissao Negada/)  {
        if ($::user_guiche) {
            $c->forward('/cb/guiche/abrir_user_guiche');
        } else {
            $c->forward('/render/escolher_guiche');
        }
    } else {
        $status_guiche->{guiche}{identificador} =~ s/\s+$//;
        if ($::user_guiche &&
            $status_guiche->{guiche}{identificador} ne $::user_guiche) {

            $c->stash->{error_message} = 'ATENÇÃO: Você está associado à mesa '.
              $status_guiche->{guiche}{identificador}.' mas está agora na mesa '.
              $::user_guiche.'. Você precisa fechar a mesa e entrar novamente '.
              'no sistema para corrigir.';
            $c->forward('/render/error_message');

        }

        $c->stash->{template} = 'render/atendente.tt';
        $c->stash->{status_guiche} = $status_guiche;
    }

}

sub gerente : Private {
    my ($self, $c) = @_;
    #PEGANDO INFORMACOES SOBRE OS GUICHÊS
    $c->stash->{template} = 'render/gerente.tt';
    $c->model('SOAP')->transport->addrs(['motor@gestao.fila.vhost/ws/gestao/local']);
    my $status_guiches = $c->model('SOAP::Gestao::Local')
          ->status_guiches({ local => {} });
          
    if ($status_guiches->{Fault}) {
        $c->stash->{error_message} = $status_guiches->{Fault}{faultstring};
        return $c->forward('/render/error_message');
        EV::unloop(EV::UNLOOP_ALL);
    } else {
        $c->stash->{status_guiches} = $status_guiches;
    }
    
    #PEGANDO INFORMACOES SOBRE DADOS_STATUS_LOCAL
    $c->model('SOAP')->transport->addrs(['motor@gestao.fila.vhost/ws/gestao/local']);
    my $status_local = $c->model('SOAP::Gestao::Local')
          ->status_local({ local => {} });
          
    if ($status_local->{Fault}) {
        $c->stash->{error_message} = $status_local->{Fault}{faultstring};
        return $c->forward('/render/error_message');
        EV::unloop(EV::UNLOOP_ALL);
    } else {
        $c->stash->{status_local} = $status_local;
    }

    #PEGANDO INFORMACOES SOBRE encaminhamentos
    $c->model('SOAP')->transport->addrs(['motor@gestao.fila.vhost/ws/gestao/local']);
    my $lista_encaminhamentos = $c->model('SOAP::Gestao::Local')
          ->listar_encaminhamentos({ encaminhamento => {} });
          
    if ($lista_encaminhamentos->{Fault}) {
        $c->stash->{error_message} = $lista_encaminhamentos->{Fault}{faultstring};
        return $c->forward('/render/error_message');
        EV::unloop(EV::UNLOOP_ALL);
    } else {
        $c->stash->{lista_encaminhamentos} = $lista_encaminhamentos;
    }

    use Data::Dumper;
    warn Data::Dumper->Dump([ $c->stash ]);

}

sub refresh_guiches : Private {
    
    #refresh_guiches é utilizado para atualizar o status dos guiches
    #na interface do gerente sem sobrescrever as informações já renderizadas na tela.
    
    my ($self, $c) = @_;
    #PEGANDO INFORMACOES SOBRE OS GUICHÊS
    $c->stash->{template} = 'render/refresh_guiches.tt';
    $c->model('SOAP')->transport->addrs(['motor@gestao.fila.vhost/ws/gestao/local']);
    my $status_guiches = $c->model('SOAP::Gestao::Local')
          ->status_guiches({ local => {} });
          
    if ($status_guiches->{Fault}) {
        $c->stash->{error_message} = $status_guiches->{Fault}{faultstring};
        return $c->forward('/render/error_message');
        EV::unloop(EV::UNLOOP_ALL);
    } else {
        $c->stash->{status_guiches} = $status_guiches;
    }

    #PEGANDO INFORMACOES SOBRE encaminhamentos
    $c->model('SOAP')->transport->addrs(['motor@gestao.fila.vhost/ws/gestao/local']);
    my $lista_encaminhamentos = $c->model('SOAP::Gestao::Local')
          ->listar_encaminhamentos({ encaminhamento => {} });
          
    if ($lista_encaminhamentos->{Fault}) {
        $c->stash->{error_message} = $lista_encaminhamentos->{Fault}{faultstring};
        return $c->forward('/render/error_message');
        EV::unloop(EV::UNLOOP_ALL);
    } else {
        $c->stash->{lista_encaminhamentos} = $lista_encaminhamentos;
    }
}


1;

__END__

=head1 NAME

Render - Renderizações gerais

=head1 DESCRIPTION

Esse módulo é responsável por renderizações gerais no sistema. É ele
que coordena também a abertura inicial do sistema.

=cut


package Fila::WebApp::Controller::CB::Gerente;
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
use DateTime;
use Net::XMPP2::Util 'bare_jid';
use base 'Catalyst::Controller::SOAP';

__PACKAGE__->config->{wsdl} =
  {wsdl => Fila::WebApp->path_to('schemas/FilaWeb.wsdl')};
 
sub abrir_local : WSDLPort('FilaWebGerenteCallback') {
    my ($self, $c, $query) = @_;

    $c->model('SOAP')->transport->addrs(['motor@gestao.fila.vhost/ws/gestao/local']);
    my $dados_local = $c->model('SOAP::Gestao::Local')
          ->abrir_local({ local => {} });

}

sub fechar_local : WSDLPort('FilaWebGerenteCallback') {
    my ($self, $c, $query) = @_;

    $c->model('SOAP')->transport->addrs(['motor@gestao.fila.vhost/ws/gestao/local']);
    my $fechar_local = $c->model('SOAP::Gestao::Local')
          ->fechar_local({ local => {} });
}

sub fechar_local_force : WSDLPort('FilaWebGerenteCallback') {
    my ($self, $c, $query) = @_;

    $c->model('SOAP')->transport->addrs(['motor@gestao.fila.vhost/ws/gestao/local']);
    my $fechar_local = $c->model('SOAP::Gestao::Local')
          ->fechar_local_force({ local => {} });
}


sub encerrar_senhas :WSDLPort('FilaWebGerenteCallback') {
  my ($self, $c, $query) = @_;

    $c->model('SOAP')->transport->addrs(['motor@gestao.fila.vhost/ws/gestao/local']);
    my $encerrar_senhas = $c->model('SOAP::Gestao::Local')
          ->encerrar_senhas({ local => {} });
}

sub enviar_chat :WSDLPort('FilaWebGerenteCallback') {
    my ($self, $c, $query) = @_;

    #Enviar agora como pacote XMPP2
   
    my $too = $query->{callback_request}{param}[0]{name};
    my $texto = $query->{callback_request}{param}[0]{value};
    $c->stash->{now} = DateTime->now(time_zone => 'local')->strftime('%H:%M');

    #checar se é para envio de broadcast
    if ($too eq 'TODOS') {
        #enviar para todos os destinatarios.
        #buscar no motor todos os usuarios ativos 
        $c->model('SOAP')->transport->addrs(['motor@gestao.fila.vhost/ws/gestao/local']);
        my $status_guiches = $c->model('SOAP::Gestao::Local')->status_guiches
            ({ local => {} });
        
        my $guiche;
        if ($status_guiches) {
            #loop passando por todos os guiches
            #while (my $guiche = $status_guiches->{lista_guiches}{guiche}->next) {
            foreach $guiche (@{$status_guiches->{lista_guiches}{guiche}}) {
                if ($guiche->{estado} ne 'fechado') {
                    $too = $guiche->{jid};
                    $too = $too . "/cb/atendente/receber_chat";
                    $c->stash->{texto} = $texto;
                    $c->engine->send_message($c, $too, 'chat',
                        sub {
                            my $writer = shift;
                            $writer->startTag('Body');
                            $writer->characters($texto);
                            $writer->endTag('Body');
                        });
                }
            }
            $c->stash->{nome} = 'todos';
        }
        
    } else {
        $too = $too . "/cb/atendente/receber_chat";
        $c->stash->{texto} = $texto;
        $c->engine->send_message($c, $too, 'chat',
            sub {
                my $writer = shift;
                $writer->startTag('Body');
                $writer->characters($texto);
                $writer->endTag('Body');
            });

        #busca no motor pela funcao dados_funcionario para retornar o nome do funcionario
        #enviando o jid como parametro da consulta.
        $c->model('SOAP')->transport->addrs(['motor@gestao.fila.vhost/ws/gestao/local']);
        my $dados_funcionario = $c->model('SOAP::Gestao::Local')->dados_funcionario
            ({ funcionario => { jid => bare_jid $too }  });


        if ($dados_funcionario->{Fault}) {
            $c->stash->{error_message} = $dados_funcionario->{Fault}{faultstring};
            return $c->forward('/render/error_message');
        } else {
            $c->stash->{nome} = $dados_funcionario->{funcionario}{nome};
        }
    }

    $c->stash->{template} = 'cb/gerente/enviar_chat.tt';
    $c->forward($c->view());
}

sub receber_chat :Local {
    my ($self, $c) = @_;
    #Recebido pacote de chat dos atendentes

    my $from = $c->req->header('XMPP_Stanza_from');
    $from = bare_jid $from;
    my $texto = $c->req->body;

    #remove a tag <body> que é contida dentro do envelope SOAP.
    return unless $texto =~ s/(^\<body\>|\<\/body\>$)//gi;


    $c->stash->{now} = DateTime->now(time_zone => 'local')->strftime('%H:%M');

    $c->model('SOAP')->transport->addrs(['motor@gestao.fila.vhost/ws/gestao/local']);
    my $dados_funcionario = $c->model('SOAP::Gestao::Local')->dados_funcionario
        ({ funcionario => { jid => $from }  });

    if ($dados_funcionario->{Fault}) {
        $c->stash->{error_message} = $dados_funcionario->{Fault}{faultstring};
        return $c->forward('/render/error_message');
    } else {
        $c->stash->{nome} = $dados_funcionario->{funcionario}{nome};
    }

    $c->stash->{texto} = $texto;
    $c->stash->{remetente} = $from;
    $c->stash->{template} = 'cb/gerente/receber_chat.tt';
    $c->forward($c->view());
}

sub encerrar_atendimento :WSDLPort('FilaWebGerenteCallback') {
    my ($self, $c, $query) = @_;

    my %params = map { $_->{name} => $_->{value} }
                         @{$query->{callback_request}{param}};

    $c->model('SOAP')->transport->addrs(['motor@gestao.fila.vhost/ws/gestao/local']);
    $c->model('SOAP::Gestao::Local')->encerrar_atendimento
      ({ atendimento => { %params }  });

}

sub devolver_senha :WSDLPort('FilaWebGerenteCallback') {
    my ($self, $c, $query) = @_;

    my %params = map { $_->{name} => $_->{value} }
                         @{$query->{callback_request}{param}};

    $c->model('SOAP')->transport->addrs(['motor@gestao.fila.vhost/ws/gestao/local']);
    $c->model('SOAP::Gestao::Local')->devolver_senha
      ({ guiche => { %params }  });

}

sub fechar_guiche :WSDLPort('FilaWebGerenteCallback') {
    my ($self, $c, $query) = @_;

    #pegando id do guiche pelo parametro do callback_request passado pelo filaweb
    my ($id_guiche) = map { $_->{value} }
                      grep { $_->{name} eq 'id_guiche' }
                      @{$query->{callback_request}{param}};

    $c->model('SOAP')->transport->addrs(['motor@gestao.fila.vhost/ws/gestao/local']);
    my $fechar_guiche = $c->model('SOAP::Gestao::Local')
          ->fechar_guiche({ guiche => { id_guiche => $id_guiche } });
}

sub fechar_todos :WSDLPort('FilaWebGerenteCallback') {
    my ($self, $c) = @_;

    $c->model('SOAP')->transport->addrs(['motor@gestao.fila.vhost/ws/gestao/local']);
    my $fechar_todos = $c->model('SOAP::Gestao::Local')
          ->fechar_todos({ guiche => {} });
}

sub concluir_atendimento :WSDLPort('FilaWebGerenteCallback') {
    my ($self, $c, $query) = @_;

    #pegando id do guiche pelo parametro do callback_request passado pelo filaweb
    my ($id_guiche) = map { $_->{value} }
                      grep { $_->{name} eq 'id_guiche' }
                      @{$query->{callback_request}{param}};

    $c->model('SOAP')->transport->addrs(['motor@gestao.fila.vhost/ws/gestao/local']);
    my $fechar_guiche = $c->model('SOAP::Gestao::Local')
          ->concluir_atendimento({ guiche => { id_guiche => $id_guiche } });

}

sub pular_opiniometro :WSDLPort('FilaWebGerenteCallback') {
    my ($self, $c, $query) = @_;

    #pegando id do guiche pelo parametro do callback_request passado pelo filaweb
    my $id_guiche = $query->{callback_request}{param}[0]{name};
    my $valor = $query->{callback_request}{param}[0]{value};

    $c->model('SOAP')->transport->addrs(['motor@gestao.fila.vhost/ws/gestao/local']);
    my $pular_opiniometro = $c->model('SOAP::Gestao::Local')
          ->pular_opiniometro({ 
               guiche => { 
                   id_guiche => $id_guiche ,
                   pular_opiniometro => $valor
                   }
               });

}

sub listar_encaminhamentos :WSDLPort('FilaWebGerenteCallback') {
    my ($self, $c, $query) = @_;

    $c->model('SOAP')->transport->addrs(['motor@gestao.fila.vhost/ws/gestao/local']);
    my $listar_encaminhamentos = $c->model('SOAP::Gestao::Local')
          ->listar_encaminhamentos({ encaminhamento => {} });
          

}

#minha modificação
sub associar_gerente :WSDLPort('FilaWebGerenteCallback') {
    my ($self, $c, $query) = @_;

    #pegando id do funcionario pelo parametro do callback_request passado pelo filaweb
    my ($id_funcionario) = map { $_->{value} }
					       grep { $_->{name} eq 'id_funcionario' }
   					       @{$query->{callback_request}{param}};
 
    $c->model('SOAP')->transport->addrs(['motor@gestao.fila.vhost/ws/gestao/local']);
    my $dados_funcionario = $c->model('SOAP::Gestao::Local')
          ->associar_gerente({ funcionario => { id_funcionario => $id_funcionario } });
          
    if ($dados_funcionario->{Fault}) {
        $c->stash->{error_message} = $dados_funcionario->{Fault}{faultstring};
        return $c->forward('/render/error_message');
    } else {
        $::connection->disconnect();
    }

}

sub passar_gerencia :WSDLPort('FilaWebGerenteCallback') {
    my ($self, $c) = @_;

    $c->model('SOAP')->transport->addrs(['motor@gestao.fila.vhost/ws/gestao/local']);
    my $lista_funcionarios = $c->model('SOAP::Gestao::Local')
          ->listar_funcionarios({ lista_funcionarios => {} });

	warn $lista_funcionarios;

    if ($lista_funcionarios->{Fault}) {
        $c->stash->{error_message} = $lista_funcionarios->{Fault}{faultstring};
        return $c->forward('/render/error_message');
    }

    $c->stash->{lista_funcionarios} = $lista_funcionarios->{lista_funcionarios};
    
    $c->stash->{template} = 'cb/gerente/passar_gerencia.tt';
    $c->forward($c->view());

}

1;

__END__

=head1 NAME

Gerente - Lógica de interface do gerente

=head1 DESCRIPTION

Esse é o módulo que recebe os callbacks de acordo com a interação
tanto com o usuário quanto com os outros componentes do sistema no
contexto do gerente.

=cut


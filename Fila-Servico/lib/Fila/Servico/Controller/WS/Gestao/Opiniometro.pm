package Fila::Servico::Controller::WS::Gestao::Opiniometro;
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
use Net::XMPP2::Util qw(bare_jid);
use DateTime;
use DateTime::Format::Pg;
use DateTime::Format::XSD;
use base
  'Fila::Servico::Controller',
  'Catalyst::Controller::SOAP',
  'Catalyst::Controller::DBIC::Transaction';

__PACKAGE__->config->{wsdl} =
  {wsdl => '/usr/share/fila/Fila-Servico/schemas/FilaServico.wsdl',
   schema => '/usr/share/fila/Fila-Servico/schemas/fila-servico.xsd'};

sub auto : Private {
    my ($self, $c) = @_;

    return 0 if $c->req->header('XMPP_Stanza') eq 'presence';

    my $from = $c->req->header('XMPP_Stanza_from');
    $from = bare_jid $from;

    # A gestao de senhas é o serviço utilizado pelo emissor de senhas
    my $now = $c->stash->{now};
    my $guiche = $c->model('DB::Guiche')->find
      ({ 'me.jid_opiniometro' => $from,
         'me.vt_ini' => { '<=' => $now },
         'me.vt_fim' => { '>' => $now },
         'estado.nome' => 'avaliacao' },
       { prefetch => ['atendimento_atual', 'local', { 'estado_atual' => 'estado' }]});

    if ($guiche) {
        $c->stash->{guiche} = $guiche;
        $c->stash->{local} = $guiche->local;
        $c->stash->{atendimento} = $guiche->atendimento_atual->first->atendimento;
        unless ($c->stash->{atendimento}) {
            $c->stash->{soap}->fault
              ({code => 'Server',
                reason => 'Permissao Negada',
                detail => 'Nao encontrou atendimento associado a esse guiche'});
            return 0;
        }
    } else {
    
    	my $local = $c->model('DB::Local')->find
    		({ 'me.jid_opiniometro' => $from,
    		   'me.vt_ini' => { '<=', $now },
    		   'me.vt_fim' => { '>', $now } });
    		
    	if ($local) {
    		$c->stash->{local} = $local;
    	} else {
            $c->action->prepare_soap_helper($self, $c);
            $c->stash->{soap}->fault
              ({code => 'Server',
                reason => 'Permissao Negada',
                detail => 'Não é o opiniometro autorizado ou guiche nao esta em avaliacao'});
            return 0;
        }
    }
}

sub registrar_avaliacao :WSDLPort('GestaoOpiniometro') :DBICTransaction('DB') :MI {
    my ($self, $c, $query) = @_;

    my $now = $c->stash->{now};
    my $estado_atual = $c->stash->{atendimento}->estado_atual->search({},{prefetch => 'estado'})->first;
    unless ($estado_atual && $estado_atual->estado->nome eq 'avaliacao') {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Permissao Negada',
             detail => 'Atendimento nao esta em avaliacao' });
    }

    my $estado_at_encerrado = $c->model('DB::TipoEstadoAtendimento')->find({ nome => 'encerrado' });
    unless ($estado_at_encerrado) {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Nao encontrou estado "encerrado"',
             detail => 'Ocorreu um erro de configuracao no sistema' });
    }

    my $estado_gu_concluido = $c->model('DB::TipoEstadoGuiche')->find({ nome => 'concluido' });
    unless ($estado_gu_concluido) {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Nao encontrou estado "concluido"',
             detail => 'Ocorreu um erro de configuracao no sistema' });
    }

    $estado_atual->update({ vt_fim => $now });
    $c->stash->{atendimento}->estados->create
      ({ vt_ini => $now,
         vt_fim => 'Infinity',
         id_estado => $estado_at_encerrado->id_estado });
    $c->stash->{atendimento}->update({ vt_fim => $now });

    my $ordem_perguntas = $c->stash->{local}->configuracoes_perguntas->find
      ({ 'me.vt_ini' => { '<=' => $now } ,
    	 'me.vt_fim' => { '>' => $now }});
    	 
   	unless ($ordem_perguntas) {
   		die $c->stash->{soap}->fault(
   			{ code => 'Server' ,
   			  reason => 'Nao encontrou ordem das perguntas do opiniometro',
   			  detail => 'Ocorreu um erro ao buscar a ordem das perguntas do opiniometro.' }
   		);
   	}

	my %perguntas = map { $_ => $ordem_perguntas->get_column("pergunta$_") } 1..5;
    foreach my $resposta (@{$query->{avaliacao_atendimento}{resposta}}) {
        $c->stash->{atendimento}->respostas_avaliacao->create
          ({ vt_fac => $now,
             id_pergunta => $perguntas{$resposta->{id_pergunta}},
             resposta => $resposta->{resposta} });
    }

    $c->stash->{atendimento}->guiche_atual->first->update({ vt_fim => $now });

    $c->stash->{guiche}->estado_atual->first->update({ vt_fim => $now });
    $c->stash->{guiche}->estados->create
      ({ vt_ini => $now,
         vt_fim => 'Infinity',
         id_estado => $estado_gu_concluido->id_estado });

    $c->stash->{refresh_gerente} = 1;
    $c->stash->{refresh_guiche} ||= [];
    push @{$c->stash->{refresh_guiche}}, $c->stash->{guiche}->id_guiche;
}

sub registrar_avaliacao_praca :WSDLPort('GestaoOpiniometro') :DBICTransaction('DB') :MI {
    my ($self, $c, $query) = @_;

    my $now = $c->stash->{now};

    my $ordem_perguntas = $c->stash->{local}->configuracoes_perguntas_praca->find
      ({ 'me.vt_ini' => { '<=' => $now } ,
    	 'me.vt_fim' => { '>' => $now }});

  	unless ($ordem_perguntas) {
   		die $c->stash->{soap}->fault(
   			{ code => 'Server' ,
   			  reason => 'Nao encontrou ordem das perguntas do opiniometro',
   			  detail => 'Ocorreu um erro ao buscar a ordem das perguntas do opiniometro.' }
   		);
   	}

	my %perguntas = map { $_ => $ordem_perguntas->get_column("pergunta$_") } 1..5;

    foreach my $resposta (@{$query->{avaliacao_atendimento}{resposta}}) {
        $c->stash->{local}->respostas_avaliacao->create
          ({ vt_fac => $now,
             id_pergunta => $perguntas{$resposta->{id_pergunta}},
             resposta => $resposta->{resposta} });
    }


}

1;

__END__

=head1 NAME

Opiniometro - Funcionalidades para o opiniometro

=head1 DESCRIPTION

Este é o módulo que disponibiliza os serviços para o Fila-Opiniometro.

=cut


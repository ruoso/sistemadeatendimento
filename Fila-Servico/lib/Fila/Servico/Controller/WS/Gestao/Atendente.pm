package Fila::Servico::Controller::WS::Gestao::Atendente;
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
use Net::XMPP2::Util 'bare_jid';
use DateTime;
use DateTime::Format::Pg;
use DateTime::Format::XSD;
use Digest::MD5 qw(md5_hex md5_base64);
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

    # GestaoAtendente exige que seja um atendente de um guiche, o que
    # significa que o guichê vai estar aberto.
    my $now = $c->stash->{now};
    my $funcionario = $c->model('DB::Funcionario')->search
      ({ jid => $from,
         'atendentes.vt_ini' => { '<=' => $now },
         'atendentes.vt_fim' => { '>' => $now },
         'guiche.vt_ini' => { '<=' => $now },
         'guiche.vt_fim' => { '>' => $now },
         'local.vt_ini' => { '<=' => $now },
         'local.vt_fim' => { '>' => $now }},
       { prefetch => { 'atendentes' => { 'guiche' => 'local' }}})->first();

    if ($funcionario) {
        $c->stash->{funcionario} = $funcionario;
        $c->stash->{atendente} = $funcionario->atendentes->first;
        $c->stash->{guiche} = $c->stash->{atendente}->guiche;
        $c->stash->{local} = $c->stash->{guiche}->local;
        $c->stash->{gerente} = $c->stash->{local}->gerente_atual->first;
    } else {
        $c->action->prepare_soap_helper($self, $c);
        $c->stash->{soap}->fault
          ({code => 'Server',
            reason => 'Permissao Negada',
            detail => 'Funcionario precisa ser atendente para acessar'});
        return 0;
    }
}

sub refresh_atendente :Private {
    my ($self, $c) = @_;
    # esse método é chamado por outras ações que precisam fazer um
    # callback para o atendente do guiche. As informações todas são
    # enviadas, para que possa ser apresentada a tela.

    my $old = $c->stash->{soap}->compile_return();

    my $guiche = $self->status_guiche($c, {});

    my $atendente = $c->stash->{guiche}->atendente_atual->first;

    if ($atendente) {
        $c->model('SOAP')->transport->connection($c->engine->connection($c));
        $c->model('SOAP')->transport->addrs([$atendente->funcionario->jid.'/cb/render/atendente']);
        $c->model('SOAP::CB::Atendente')->render_atendente({ %$guiche });
    } elsif ($c->stash->{atendente}) {
        $c->model('SOAP')->transport->connection($c->engine->connection($c));
        $c->model('SOAP')->transport->addrs([$c->stash->{atendente}->funcionario->jid.'/cb/render/atendente']);
        $c->model('SOAP::CB::Atendente')->render_atendente({ %$guiche });
    }

    $c->stash->{soap}->compile_return($old);
}


sub status_guiche :WSDLPort('GestaoAtendente') :DBICTransaction('DB') :MI {

    #status_guiche retorna todos os dados pertinentes aos guiches.

    my ($self, $c) = @_;

    my $now = $c->stash->{now};

    my $guiches = $c->stash->{local}->guiches->search
      ({ 'me.id_guiche' => $c->stash->{guiche}->id_guiche },
       { 'join'   => [{ 'estado_atual' => 'estado' },
                      'pausa_atual',
                      { 'atendimento_atual' => { 'atendimento' =>
                                            [ { 'senha' => 'categoria' },
                                              { 'estado_atual' => 'estado' },
                                              'agendamento' ]}},
                      { 'atendente_atual' => 'funcionario' }],
         'select' => [ 'me.id_guiche',
                       'me.identificador',
                       'funcionario.id_funcionario',
                       'funcionario.nome',
                       'funcionario.jid',
                       'estado.nome',
                       'estado_atual.vt_ini',
                       'categoria.codigo',
                       'senha.codigo',
                       'estado_2.nome',
                       'estado_atual_2.vt_ini',
                       'pausa_atual.motivo',
                       'agendamento.nome',
                       'agendamento.tipopessoa',
                       'agendamento.cnpjf',
                       'agendamento.email',
                       'me.timeout_chamando',
                       'me.timeout_concluido' ],
         'as'     => [ 'id_guiche',
                       'identificador',
                       'id_funcionario',
                       'funcionario',
                       'jid',
                       'estado',
                       'estado_desde',
                       'codigo_categoria',
                       'codigo_senha',
                       'estado_atendimento',
                       'estado_atendimento_desde',
                       'pausa_motivo',
                       'agendamento_nome',
                       'agendamento_tipopessoa',
                       'agendamento_cnpjf',
                       'agendamento_email',
                       'timeout_chamando',
                       'timeout_concluido' ]});

    #pega o estado do guiche, se for interno entao seleciona do servicoguiche, senao do servicoatendimento
    my $estado_guiche = $c->stash->{guiche}->estados->search
      ({ vt_ini => { '<=', $now },
         vt_fim => { '>', $now }},
       { prefetch =>  'estado' })->first;
    unless ($estado_guiche) {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Nao encontrou estado do guiche',
             detail => 'Ocorreu um erro de configuracao no sistema.' });
    }

    my $interno;
    # se estiver 'interno' pega os servicos de {guiche}->servico_atual
    if ($estado_guiche->estado->nome eq 'interno') {
        my $servicos_internos = $c->stash->{guiche}->servico_atual->search(
                { },
                {   
                    'join' =>
                    [
                        'servico'
                    ],
                    'select' => 
                    [   'me.id_servico', 
                        'servico.id_classe', 
                        'servico.nome', 
                        'me.informacoes'  ], 
                    'as' => 
                    [   'id_servico', 
                        'id_classe', 
                        'nome', 
                        'informacoes' ]
                },
           );

        my $servico;
        while ($servico = $servicos_internos->next) {
            push @{$interno}, 
                {
                  ( map { $_ => $servico->get_column($_) }
                  qw/ id_servico id_classe nome informacoes / ),
                }
        } 
    }
    # se estiver 'atendimento' pega os servicos de {guiche}->atendimento_atual->atendimento->servico_atual
    if ($estado_guiche->estado->nome eq 'atendimento') {
        #pegar atendimento atual do guiche_atendimento
        my $atend_guiche = $c->stash->{guiche}->atendimento_atual->find({});
        unless ($atend_guiche) {
            die $c->stash->{soap}->fault
              ({ code => 'Server',
                 reason => 'Nao encontrou atendimento associado.',
                 detail => 'Nao existia atendimento associado ao guiche.' });
        }

        #pegar atendimento atual do atendimento
        my $atendimento = $atend_guiche->atendimento;
        unless ($atendimento) {
            die $c->stash->{soap}->fault
              ({ code => 'Server',
                 reason => 'Nao encontrou atendimento associado.',
                 detail => 'Nao existia atendimento associado ao guiche.' });
        }

        my $servicos_internos = $atendimento->servico_atual->search(
                { },
                {   
                    'join' =>
                    [
                        'servico'
                    ],
                    'select' => 
                    [   'me.id_servico', 
                        'servico.id_classe', 
                        'servico.nome', 
                        'me.informacoes'  ], 
                    'as' => 
                    [   'id_servico', 
                        'id_classe', 
                        'nome', 
                        'informacoes' ]
                },
           );

        my $servico;
        while ($servico = $servicos_internos->next) {
            push @{$interno}, 
                {
                  ( map { $_ => $servico->get_column($_) }
                  qw/ id_servico id_classe nome informacoes / ),
                }
        }
    }

    my $guiche = $guiches->next;
    my $agendamento;
    if ($guiche->get_column('agendamento_nome')) {
        $agendamento =
          { map { $_ => $guiche->get_column('agendamento_'.$_) }
            qw(nome tipopessoa cnpjf email) };
    }
    $c->stash->{soap}->compile_return(
        { guiche =>
          { ( map { $_ => $guiche->get_column($_) }
              qw( id_guiche identificador estado estado_atendimento
                  funcionario id_funcionario jid pausa_motivo
                  timeout_chamando timeout_concluido) ),
            ( map { $guiche->get_column($_) ?
                      ($_ => DateTime::Format::XSD->format_datetime
                       (DateTime::Format::Pg->parse_datetime
                        ($guiche->get_column($_)))) : () }
              qw/ estado_desde estado_atendimento_desde / ),
            id_local => $c->stash->{local}->id_local,
            senha => $guiche->get_column('codigo_senha') ?
            ( sprintf('%s%03d', ( map { $guiche->get_column($_) || '' }
                                  qw( codigo_categoria codigo_senha ) )) ) : '',
            servicos => { servico => $interno },
            agendamento => $agendamento } } );
}

sub registrar_no_show :WSDLPort('GestaoAtendente') :DBICTransaction('DB') :MI {
    my ($self, $c, $query) = @_;

    my $now = $c->stash->{now};
    my $estado_guiche = $c->stash->{guiche}->estados->search
      ({ vt_ini => { '<=', $now },
         vt_fim => { '>', $now }},
       { prefetch =>  'estado' })->first;
    unless ($estado_guiche && $estado_guiche->estado->nome eq 'chamando') {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Estado invalido',
             detail => 'Guiche precisa estar "chamando" para registrar no-show' });
    }

    my $estado_no_show = $c->model('DB::TipoEstadoAtendimento')->find
      ({ nome => 'no_show' });
    unless ($estado_no_show) {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Nao encontrou estado "no_show"',
             detail => 'Ocorreu um erro de configuracao no sistema.' });
    }

    my $estado_concluido = $c->model('DB::TipoEstadoGuiche')->find
      ({ nome => 'concluido' });
    unless ($estado_concluido) {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Nao encontrou estado "concluido"',
             detail => 'Ocorreu um erro de configuracao no sistema.' });
    }

    my $atend_guiche = $c->stash->{guiche}->atendimento_atual->find({});
    unless ($atend_guiche) {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Nao encontrou atendimento associado.',
             detail => 'Nao existia atendimento associado ao guiche.' });
    }

    my $atendimento = $atend_guiche->atendimento;
    unless ($atendimento) {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Nao encontrou atendimento associado.',
             detail => 'Nao existia atendimento associado ao guiche.' });
    }

    my $estado_atendimento = $atendimento->estados->find
      ({ vt_ini => { '<=', $now },
         vt_fim => { '>', $now } },
       { prefetch => 'estado' });
    unless ($estado_atendimento && $estado_atendimento->estado->nome eq 'chamando') {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Estado invalido',
             detail => 'Atendimento precisa estar "chamando" para registrar no-show' });
    }

    $atend_guiche->update
      ({ vt_fim => $now });

    $estado_atendimento->update
      ({ vt_fim => $now });

    $atendimento->estados->create
      ({ vt_ini => $now,
         vt_fim => 'Infinity',
         id_estado => $estado_no_show->id_estado });

    $estado_guiche->update
      ({ vt_fim => $now });

    $c->stash->{guiche}->estados->create
      ({ vt_ini => $now,
         vt_fim => 'Infinity',
         id_estado => $estado_concluido->id_estado });

    $c->stash->{refresh_gerente} = 1;
    $c->stash->{refresh_guiche} ||= [];
    push @{$c->stash->{refresh_guiche}}, $c->stash->{guiche}->id_guiche;
}

sub listar_no_show :WSDLPort('GestaoAtendente') :DBICTransaction('DB') :MI {
    #lista todos os atendimentos no_show
    my($self, $c) = @_;

    #Procurar todos os atendimentos no_show
    my $list = $c->stash->{local}->atendimentos_atuais->search 
        ({ 'estado.nome' => 'no_show' },
         { prefetch => [ { 'senha' => 'categoria' }, { 'estado_atual' => 'estado' }]});   

    my $retorno = [];
    while (my $atendimento = $list->next) {
        my $senha = $atendimento->senha;
        push @{$retorno},
            {( map { $_ => $atendimento->$_() }
              qw/ id_atendimento id_local id_senha / ),
             estado => 'no_show',
             senha => sprintf('%s%03d',$senha->categoria->codigo, $senha->codigo)}
    }

    $c->stash->{soap}->compile_return
    ({ lista_atendimentos =>
         { atendimento => $retorno }});

}

sub atender_no_show :WSDLPort('GestaoAtendente') :DBICTransaction('DB') :MI {
    my ($self, $c, $query) = @_;

    my $now = $c->stash->{now};
    my $estado_guiche = $c->stash->{guiche}->estado_atual->search
      ({ },
       { prefetch => 'estado' })->first;

    my $estado_atendendo_at = $c->model('DB::TipoEstadoAtendimento')->find
      ({ nome => 'atendimento' });
    unless ($estado_atendendo_at) {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Nao encontrou estado "atendimento"',
             detail => 'Ocorreu um erro de configuracao no sistema.' });
    }

    my $estado_atendendo_gu = $c->model('DB::TipoEstadoGuiche')->find
      ({ nome => 'atendimento' });
    unless ($estado_atendendo_gu) {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Nao encontrou estado "atendimento"',
             detail => 'Ocorreu um erro de configuracao no sistema.' });
    }

    my $atendimento = $c->model('DB::Atendimento')->find
        ($query->{atendimento});
    unless ($atendimento) {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Nao encontrou atendimento associado.',
             detail => 'Nao existia atendimento associado ao guiche.' });
    }

    my $estado_atendimento = $atendimento->estado_atual->find
      ({  },
       { prefetch => 'estado' });
    unless ($estado_atendimento && $estado_atendimento->estado->nome eq 'no_show') {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Estado invalido',
             detail => 'Atendimento precisa estar "chamando" para iniciar atendimento' });
    }

    $estado_atendimento->update
      ({ vt_fim => $now });

    $atendimento->estados->create
      ({ vt_ini => $now,
         vt_fim => 'Infinity',
         id_estado => $estado_atendendo_at->id_estado });

    $estado_guiche->update
      ({ vt_fim => $now });

    $c->stash->{guiche}->atendimentos->create
      ({ vt_ini => $now,
         vt_fim => 'Infinity',
         id_atendimento => $atendimento->id_atendimento });

    $c->stash->{guiche}->estados->create
      ({ vt_ini => $now,
         vt_fim => 'Infinity',
         id_estado => $estado_atendendo_gu->id_estado });

    $c->stash->{refresh_gerente} = 1;
    $c->stash->{refresh_guiche} ||= [];
    push @{$c->stash->{refresh_guiche}}, $c->stash->{guiche}->id_guiche;
}

sub iniciar_atendimento :WSDLPort('GestaoAtendente') :DBICTransaction('DB') :MI {
    my ($self, $c, $query) = @_;

    my $now = $c->stash->{now};
    my $estado_guiche = $c->stash->{guiche}->estado_atual->search
      ({ },
       { prefetch => 'estado' })->first;
    unless ($estado_guiche && $estado_guiche->estado->nome eq 'chamando') {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Estado invalido',
             detail => 'Guiche precisa estar "chamando" para iniciar atendimento' });
    }

    my $estado_atendendo_at = $c->model('DB::TipoEstadoAtendimento')->find
      ({ nome => 'atendimento' });
    unless ($estado_atendendo_at) {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Nao encontrou estado "atendimento"',
             detail => 'Ocorreu um erro de configuracao no sistema.' });
    }

    my $estado_atendendo_gu = $c->model('DB::TipoEstadoGuiche')->find
      ({ nome => 'atendimento' });
    unless ($estado_atendendo_gu) {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Nao encontrou estado "atendimento"',
             detail => 'Ocorreu um erro de configuracao no sistema.' });
    }

    my $atendimento = $c->stash->{guiche}->atendimento_atual->find({});
    unless ($atendimento) {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Nao encontrou atendimento associado.',
             detail => 'Nao existia atendimento associado ao guiche.' });
    }

    my $estado_atendimento = $atendimento->atendimento->estado_atual->find
      ({  },
       { prefetch => 'estado' });
    unless ($estado_atendimento && $estado_atendimento->estado->nome eq 'chamando') {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Estado invalido',
             detail => 'Atendimento precisa estar "chamando" para iniciar atendimento' });
    }

    $estado_atendimento->update
      ({ vt_fim => $now });

    $atendimento->atendimento->estados->create
      ({ vt_ini => $now,
         vt_fim => 'Infinity',
         id_estado => $estado_atendendo_at->id_estado });

    $estado_guiche->update
      ({ vt_fim => $now });

    $c->stash->{guiche}->estados->create
      ({ vt_ini => $now,
         vt_fim => 'Infinity',
         id_estado => $estado_atendendo_gu->id_estado });


    $c->stash->{refresh_painel} = 1;
    $c->stash->{refresh_gerente} = 1;
    $c->stash->{refresh_guiche} ||= [];
    push @{$c->stash->{refresh_guiche}}, $c->stash->{guiche}->id_guiche;
}

sub devolver_senha :WSDLPort('GestaoAtendente') :DBICTransaction('DB') :MI {
    my ($self, $c, $query) = @_;

    my $now = $c->stash->{now};
    my $estado_guiche = $c->stash->{guiche}->estado_atual->search
      ({ },
       { prefetch => 'estado' })->first;
    unless ($estado_guiche && $estado_guiche->estado->nome eq 'chamando') {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Estado invalido',
             detail => 'Guiche precisa estar "chamando" para devolver senha' });
    }

    my $estado_concluido_gu = $c->model('DB::TipoEstadoGuiche')->find
      ({ nome => 'concluido' });
    unless ($estado_concluido_gu) {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Nao encontrou estado "concluido"',
             detail => 'Ocorreu um erro de configuracao no sistema.' });
    }

    my $atendimento = $c->stash->{guiche}->atendimento_atual->find({});
    unless ($atendimento) {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Nao encontrou atendimento associado.',
             detail => 'Nao existia atendimento associado ao guiche.' });
    }

    my $estado_atendimento = $atendimento->atendimento->estado_atual->find
      ({  },
       { prefetch => 'estado' });
    unless ($estado_atendimento && $estado_atendimento->estado->nome eq 'chamando') {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Estado invalido',
             detail => 'Atendimento precisa estar "chamando" para devolver senha' });
    }

    $estado_atendimento->delete;

    my $estado_anterior = $atendimento->atendimento->estados->search
      ({ },
       { order_by => 'vt_fim DESC',
         rows => 1 });

    unless ($estado_anterior) {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Estado invalido',
             detail => 'Não conseguiu encontrar estado anterior para devolver o atendimento' });
    }

    $estado_anterior->update
      ({ vt_fim => 'Infinity' });

    $estado_guiche->update
      ({ vt_fim => $now });

    $c->stash->{guiche}->estados->create
      ({ vt_ini => $now,
         vt_fim => 'Infinity',
         id_estado => $estado_concluido_gu->id_estado });

    # desassociar do guiche.
    $atendimento->update
      ({ vt_fim => $now });

    $c->stash->{refresh_painel} = 1;
    $c->stash->{refresh_gerente} = 1;
    $c->stash->{refresh_guiche} ||= [];
    push @{$c->stash->{refresh_guiche}}, $c->stash->{guiche}->id_guiche;
}

sub concluir_atendimento :WSDLPort('GestaoAtendente') :DBICTransaction('DB') :MI {
    my ($self, $c, $query) = @_;

    my $now = $c->stash->{now};
    my $estado_guiche = $c->stash->{guiche}->estado_atual->search
      ({ },
       { prefetch => 'estado' })->first;
    unless ($estado_guiche && $estado_guiche->estado->nome eq 'atendimento') {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Estado invalido',
             detail => 'Guiche precisa estar "atendimento" para concluir atendimento' });
    }

    my $estado_avaliacao = $c->model('DB::TipoEstadoAtendimento')->find
      ({ nome => 'avaliacao' });
    unless ($estado_avaliacao) {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Nao encontrou estado "avaliacao"',
             detail => 'Ocorreu um erro de configuracao no sistema.' });
    }

    my $estado_guiche_avaliacao = $c->model('DB::TipoEstadoGuiche')->find
      ({ nome => 'avaliacao' });
    unless ($estado_guiche_avaliacao) {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Nao encontrou estado "avaliacao"',
             detail => 'Ocorreu um erro de configuracao no sistema.' });
    }

    my $atendimento = $c->stash->{guiche}->atendimento_atual->find;
    
    unless ($atendimento) {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Nao encontrou atendimento associado.',
             detail => 'Nao existia atendimento associado ao guiche.' });
    }

    my $estado_atendimento = $atendimento->atendimento->estado_atual->find
      ({  },
       { prefetch => 'estado' });
    unless ($estado_atendimento && $estado_atendimento->estado->nome eq 'atendimento') {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Estado invalido',
             detail => 'Atendimento precisa estar "atendimento" para concluir atendimento' });
    }
    
    #checa se existem servicos abertos.
    my $servico_atual = $atendimento->atendimento->servico_atual->find;

    if ($servico_atual) {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Existem serviços abertos.',
             detail => 'Nao e possivel concluir atendimento com servicos em andamento.' });
    }

    $estado_atendimento->update
      ({ vt_fim => $now });

    $atendimento->atendimento->estados->create
      ({ vt_ini => $now,
         vt_fim => 'Infinity',
         id_estado => $estado_avaliacao->id_estado });

    $estado_guiche->update
      ({ vt_fim => $now });

    $c->stash->{guiche}->estados->create
      ({ vt_ini => $now,
         vt_fim => 'Infinity',
         id_estado => $estado_guiche_avaliacao->id_estado });

    my $guiche = $c->stash->{guiche};
    
    if ($guiche && $guiche->pular_opiniometro == 0) {
        $c->model('SOAP')->transport->connection($c->engine->connection($c));
        $c->model('SOAP')->transport->addrs([$c->stash->{guiche}->jid_opiniometro . '/callback']);
        $c->model('SOAP::Opiniometro')
              ->iniciar_opiniometro({ refresh_request => '' });
    } else {
        #encerra atendimento
        my $estado_atual = $atendimento->atendimento->estado_atual->search
          ({},{ prefetch => 'estado' })->first;
        if ($estado_atual->estado->nome ne 'avaliacao') {
            die $c->stash->{soap}->fault
              ({ code => 'Server',
                 reason => 'Atendimento em estado invalido',
                 detail => 'O atendimento precisa estar em "avaliacao" para ser encerrado' });
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

        $atendimento->atendimento->estados->create
          ({ vt_ini => $now,
             vt_fim => 'Infinity',
             id_estado => $estado_at_encerrado->id_estado });
        $atendimento->atendimento->update({ vt_fim => $now });

        $atendimento->atendimento->guiche_atual->first->update({ vt_fim => $now });

        $guiche->estado_atual->first->update({ vt_fim => $now });
        $guiche->estados->create
          ({ vt_ini => $now,
             vt_fim => 'Infinity',
             id_estado => $estado_gu_concluido->id_estado });

        $c->model('SOAP')->transport->connection($c->engine->connection($c));

        $c->model('SOAP')->transport->addrs([$guiche->jid_opiniometro . '/callback/']);
        $c->model('SOAP::Opiniometro')
              ->encerrar_opiniometro({ refresh_request => '' });

        $c->stash->{refresh_guiche} ||= [];
        push @{$c->stash->{refresh_guiche}}, $guiche->id_guiche;
    }

    $c->stash->{refresh_painel} = 1;
    $c->stash->{refresh_gerente} = 1;
    $c->stash->{refresh_guiche} ||= [];
    push @{$c->stash->{refresh_guiche}}, $c->stash->{guiche}->id_guiche;
}

sub encaminhar_atendimento :WSDLPort('GestaoAtendente') :DBICTransaction('DB') :MI {
    my ($self, $c, $query) = @_;

    my $now = $c->stash->{now};

    my $guiche_origem = $c->model('DB::Guiche')->find
      ( id_guiche => $c->stash->{guiche}->id_guiche );

    my $motivo = $query->{encaminhamento}{informacoes};
    unless ($motivo) {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Motivo Invalido',
             detail => 'E necessário um motivo para o encaminhamento.' });
    }

    my $atendimento = $c->stash->{guiche}->atendimento_atual->first;

    unless ($atendimento) {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Atendimento Invalido',
             detail => 'Nao conseguiu encontrar atendimento.' });
    }

    my $estado_concluido_gu = $c->model('DB::TipoEstadoGuiche')->find
      ({ nome => 'concluido' });
    unless ($estado_concluido_gu) {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Nao encontrou estado "concluido"',
             detail => 'Ocorreu um erro de configuracao no sistema.' });
    }
    my $estado_encaminhado = $c->model('DB::TipoEstadoAtendimento')->find
      ({ nome => 'encaminhado' });
    unless ($estado_encaminhado) {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Nao encontrou estado "encaminhado"',
             detail => 'Ocorreu um erro de configuracao no sistema.' });
    }

    $atendimento->atendimento->estado_atual->update
      ({ vt_fim => $now });

    $atendimento->atendimento->estado_atual->create
      ({ vt_ini => $now,
         vt_fim => 'Infinity',
         id_estado => $estado_encaminhado->id_estado });

    if ($query->{encaminhamento}{id_guiche}) {
      my $outro_guiche = $c->model('DB::Guiche')
        ->find({ id_guiche => $query->{encaminhamento}{id_guiche} })
          or die $c->stash->{soap}->fault
            ({ code => 'Server',
               reason => 'Nao encontrou guiche',
               detail => 'O guiche informado não existe.' });

      $outro_guiche->encaminhamentos->create
        ({ vt_ini => $now,
           vt_fim => 'Infinity',
           id_atendimento => $atendimento->id_atendimento,
           id_guiche_origem => $guiche_origem->id_guiche,
           informacoes => $motivo });
    } elsif ($query->{encaminhamento}{id_categoria}) {
      $c->stash->{local}->encaminhamentos_categoria->create
        ({ id_categoria => $query->{encaminhamento}{id_categoria},
           vt_ini => $now,
           vt_fim => 'Infinity',
           id_atendimento => $atendimento->id_atendimento,
           id_guiche_origem => $guiche_origem->id_guiche,
           informacoes => $motivo });

    } else {
      die $c->stash->{soap}->fault
        ({ code => 'Client',
           reason => 'Faltou parâmetros',
           detail => 'É preciso indicar ou um guiche ou uma categoria' });
    }

    $c->stash->{guiche}->estado_atual->first->update
      ({ vt_fim => $now });

    $c->stash->{guiche}->estados->create
      ({ vt_ini => $now,
         vt_fim => 'Infinity',
         id_estado => $estado_concluido_gu->id_estado });

    $atendimento->update
       ({ vt_fim => $now });

    $c->stash->{escalonar_senha} = 1;
    $c->stash->{refresh_guiche} ||= [];
    push @{$c->stash->{refresh_guiche}}, $c->stash->{guiche}->id_guiche;
}

sub iniciar_pausa :WSDLPort('GestaoAtendente') :DBICTransaction('DB') :MI {
    my ($self, $c) = @_;

    my $now = $c->stash->{now};

    #pegando estado atual do guiche
    my $estado_guiche = $c->stash->{guiche}->estado_atual->search
      ({ },
       { prefetch => 'estado' })->first;
    #guiche tem que estar concluido ou disponivel para iniciar pausa
    unless ($estado_guiche && (($estado_guiche->estado->nome eq 'concluido') || ($estado_guiche->estado->nome eq 'disponivel') )) {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Estado invalido',
             detail => 'Guiche deve estar "concluido" ou "disponivel" para iniciar uma pausa.' });
    }

    #pegando estado pausa
    my $estado_pausa = $c->model('DB::TipoEstadoGuiche')->find
      ({ nome => 'pausa' });
    unless ($estado_pausa) {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Nao encontrou estado "pausa"',
             detail => 'Ocorreu um erro de configuracao no sistema.' });
    }

    #fechando estado anterior do guiche
    $estado_guiche->update
      ({ vt_fim => $now });

    #criando estado pausa para o guiche
    $c->stash->{guiche}->estados->create
      ({ vt_ini => $now,
         vt_fim => 'Infinity',
         id_estado => $estado_pausa->id_estado });

    #criando objeto pausa 
    $c->stash->{guiche}->pausas->create
      ({ vt_ini => $now,
         vt_fim => 'Infinity',
         id_funcionario =>  $c->stash->{guiche}->atendente_atual->first->id_funcionario,
         motivo => '' });


    $c->stash->{refresh_gerente} = 1;
    $c->stash->{refresh_guiche} ||= [];
    push @{$c->stash->{refresh_guiche}}, $c->stash->{guiche}->id_guiche;
}

sub setar_motivo_pausa : WSDLPort('GestaoAtendente') :DBICTransaction('DB') :MI {
    my ($self, $c, $query) = @_;

    my $pausa_motivo = $query->{guiche}{pausa_motivo};

    #unless ($pausa_motivo) {
    #    die $c->stash->{soap}->fault
    #      ({ code => 'Server',
    #         reason => 'Nao encontrou um motivo de pausa associado.',
    #         detail => 'Nao existia motivo da pausa associado ao guiche.' });
    #}

    my $pausa_atual = $c->stash->{guiche}->pausa_atual->first;

    unless ($pausa_atual) {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Nao encontrou uma pausa associada.',
             detail => 'Nao existia pausa associada ao guiche.' });
    }

    $pausa_atual->update
    ({ motivo => $pausa_motivo });

    $c->stash->{refresh_gerente} = 1;
    $c->stash->{refresh_guiche} ||= [];
    push @{$c->stash->{refresh_guiche}}, $c->stash->{guiche}->id_guiche;
}

sub fechar_servico_interno: WSDLPort('GestaoAtendente') :DBICTransaction('DB') :MI {
    my ($self, $c) = @_;

    my $now = $c->stash->{now};
    my $estado_guiche = $c->stash->{guiche}->estado_atual->search
      ({ },
       { prefetch => 'estado' })->first;
    unless ($estado_guiche && $estado_guiche->estado->nome eq 'interno') {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Estado invalido',
             detail => 'Guiche deve estar "interno" para fechar servico interno' });
    }

    #fechar objeto servicoguiche
    if($estado_guiche->estado->nome eq 'interno'){
        my $interno = $c->stash->{guiche}->servico_atual->first;
        if ($interno) {
            $interno->update
             ({vt_fim => $now});
        }
    }

    my $estado_concluido = $c->model('DB::TipoEstadoGuiche')->find
      ({ nome => 'concluido' });
    unless ($estado_concluido) {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Nao encontrou estado "concluido"',
             detail => 'Ocorreu um erro de configuracao no sistema.' });
    }

    $estado_guiche->update
      ({ vt_fim => $now });

    $c->stash->{guiche}->estados->create
      ({ vt_ini => $now,
         vt_fim => 'Infinity',
         id_estado => $estado_concluido->id_estado });

    $c->stash->{refresh_gerente} = 1;
    $c->stash->{refresh_guiche} ||= [];
    push @{$c->stash->{refresh_guiche}}, $c->stash->{guiche}->id_guiche;
}

sub disponivel :WSDLPort('GestaoAtendente') :DBICTransaction('DB') :MI {
    my ($self, $c, $query) = @_;

    my $now = $c->stash->{now};
    my $estado_guiche = $c->stash->{guiche}->estado_atual->search
      ({ },
       { prefetch => 'estado' })->first;
    unless ($estado_guiche && (($estado_guiche->estado->nome eq 'concluido') || ($estado_guiche->estado->nome eq 'pausa') )) {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Estado invalido',
             detail => 'Guiche deve estar "concluido" ou em "pausa" para voltar a estar disponivel' });
    }

    if($estado_guiche->estado->nome eq 'pausa'){
        my $pausa = $c->stash->{guiche}->pausa_atual->first;
        if ($pausa) {
            $pausa->update
             ({vt_fim => $now});
        }
    }

    if($estado_guiche->estado->nome eq 'interno'){
        my $pausa = $c->stash->{guiche}->pausa_atual->first;
        if ($pausa) {
            $pausa->update
             ({vt_fim => $now});
        }
    }

    my $estado_disponivel = $c->model('DB::TipoEstadoGuiche')->find
      ({ nome => 'disponivel' });
    unless ($estado_disponivel) {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Nao encontrou estado "disponivel"',
             detail => 'Ocorreu um erro de configuracao no sistema.' });
    }

    my $atendimento = $c->stash->{guiche}->atendimento_atual->find;
    if ($atendimento) {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Atendimento ainda associado.',
             detail => 'Nao pode voltar a estar disponivel enquanto atendimento estiver associado ao guiche.' });
    }

    $estado_guiche->update
      ({ vt_fim => $now });

    $c->stash->{guiche}->estados->create
      ({ vt_ini => $now,
         vt_fim => 'Infinity',
         id_estado => $estado_disponivel->id_estado });


    $c->stash->{escalonar_gerente} = 1;
    $c->stash->{escalonar_senha} = 1;
    $c->stash->{refresh_guiche} ||= [];
    push @{$c->stash->{refresh_guiche}}, $c->stash->{guiche}->id_guiche;
}

sub fechar_guiche :WSDLPort('GestaoAtendente') :DBICTransaction('DB') :MI {

    #fechar_guiche irá desvincular o atendente ao guiche que está aberto
    #e criar um novo estado para o guiche.

    my ($self, $c, $query) = @_;

    my $now = $c->stash->{now};
    my $estado_guiche = $c->stash->{guiche}->estados->find
      ({ vt_ini => { '<=', $now },
         vt_fim => { '>', $now }},
       { prefetch => 'estado' });
    #unless ($estado_guiche && $estado_guiche->estado->nome !~ 'atendimento') {
    #gerente sempre vai poder fechar o guichê, mesmo estando em atendimento.
    unless ($estado_guiche) {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Estado invalido',
             detail => 'Guiche nao pode estar "atendimento" quando for fechado' });
    }

    my $estado_fechado = $c->model('DB::TipoEstadoGuiche')->find
      ({ nome => 'fechado' });
    unless ($estado_fechado) {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Nao encontrou estado "fechado"',
             detail => 'Ocorreu um erro de configuracao no sistema.' });
    }

    my $atendimento = $c->stash->{guiche}->atendimentos->find
      ({ vt_ini => { '<=', $now },
         vt_fim => { '>', $now }});
    if ($atendimento) {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Atendimento ainda associado.',
             detail => 'Nao pode fechar enquanto atendimento estiver associado ao guiche.' });
    }

    #checa se existe pausa
    if($estado_guiche->estado->nome eq 'pausa'){
        my $pausa = $c->stash->{guiche}->pausa_atual->find;
        if ($pausa) {
            $pausa->update
             ({vt_fim => $now});
        }
    }

    #checa se existe servico interno
    if($estado_guiche->estado->nome eq 'interno'){
        my $interno = $c->stash->{guiche}->servico_atual->find;
        if ($interno) {
            $interno->update
             ({vt_fim => $now});
        }
    }

    $estado_guiche->update
      ({ vt_fim => $now });

    my $atendente = $c->stash->{guiche}->atendentes
                    ->find( { vt_ini => { '<=', $now  },
                              vt_fim => { '>', $now   } } );

    if ($atendente) {
        $atendente->update({ vt_fim => $now });
    } else {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Atendimento ainda associado.',
             detail => 'Nenhum atendente associado ao guichê.' });
    }

    $c->stash->{guiche}->estados->create
      ({ vt_ini => $now,
         vt_fim => 'Infinity',
         id_estado => $estado_fechado->id_estado });


    $c->stash->{refresh_gerente} = 1;
    $c->stash->{refresh_guiche} ||= [];
    push @{$c->stash->{refresh_guiche}}, $c->stash->{guiche}->id_guiche;

}

sub iniciar_servico_interno :WSDLPort('GestaoAtendente') :DBICTransaction('DB') :MI {
    my ($self, $c, $query) = @_;

    my $now = $c->stash->{now};
    my $id_servico = $query->{servico}{id_servico};

    #pegando estado atual do guiche
    my $estado_guiche = $c->stash->{guiche}->estado_atual->search
      ({ },
       { prefetch => 'estado' })->first;
    #guiche tem que estar concluido ou disponivel para iniciar servico interno
    unless ($estado_guiche && (($estado_guiche->estado->nome eq 'concluido') || ($estado_guiche->estado->nome eq 'disponivel') )) {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Estado invalido',
             detail => 'Guiche deve estar "concluido" ou "disponivel" para iniciar um serviço interno.' });
    }

    #pegando estado servico interno
    my $estado_interno = $c->model('DB::TipoEstadoGuiche')->find
      ({ nome => 'interno' });
    unless ($estado_interno) {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Nao encontrou estado "interno"',
             detail => 'Ocorreu um erro de configuracao no sistema.' });
    }

    #fechando estado anterior do guiche
    $estado_guiche->update
      ({ vt_fim => $now });

    #criando estado interno para o guiche
    $c->stash->{guiche}->estados->create
      ({ vt_ini => $now,
         vt_fim => 'Infinity',
         id_estado => $estado_interno->id_estado });

    #criando objeto servico_guiche
    $c->stash->{guiche}->servicos->create
      ({ vt_ini => $now,
         vt_fim => 'Infinity',
         id_servico =>  $id_servico,
         informacoes => '' });

    $c->stash->{refresh_gerente} = 1;
    $c->stash->{refresh_guiche} ||= [];
    push @{$c->stash->{refresh_guiche}}, $c->stash->{guiche}->id_guiche;

}

sub listar_servicos  :WSDLPort('GestaoAtendente') :DBICTransaction('DB') :MI {
    my ($self, $c) = @_;

    my $now = $c->stash->{now};

    #pega no model todos os serviços
    my $servicos = $c->model('DB::ServicoInterno')->search
      ({ 'me.vt_ini' => { '<=', $now },
         'me.vt_fim' => { '>', $now } },
       { prefetch => 'classe',
         order_by => ['classe.nome', 'me.nome'] });

    my $lista_servicos = [];

    while (my $servico = $servicos->next) {
        push @$lista_servicos,
          { (map { $_ => $servico->$_() }
             qw/id_servico id_classe nome/ ),
            classe => $servico->classe->nome };
    }

    #retorna uma lista dos serviços
    $c->stash->{soap}->compile_return
      ({ lista_servicos => { servico => $lista_servicos } });

}

sub listar_servicos_atendimento  :WSDLPort('GestaoAtendente') :DBICTransaction('DB') :MI {
    my ($self, $c) = @_;

    my $now = $c->stash->{now};

    #pega no model todos os serviços
    my $servicos = $c->model('DB::Servico')->search
      ({ 'me.vt_ini' => { '<=', $now },
         'me.vt_fim' => { '>', $now } },
       { order_by => ['classe.nome', 'me.nome'],
         prefetch => 'classe' });

    my $lista_servicos_atendimento = [];

    while (my $servico = $servicos->next) {
        push @$lista_servicos_atendimento,
          { (map { $_ => $servico->$_() }
             qw/id_servico id_classe nome/ ),
            classe => $servico->classe->nome };
    }

    #retorna uma lista dos serviços
    $c->stash->{soap}->compile_return
      ({ lista_servicos => { servico => $lista_servicos_atendimento } });

}

sub setar_info_interno : WSDLPort('GestaoAtendente') :DBICTransaction('DB') :MI {
    my ($self, $c, $query) = @_;

    my $informacoes = $query->{servico}{informacoes};

    #unless ($informacoes) {
    #    die $c->stash->{soap}->fault
    #      ({ code => 'Server',
    #         reason => 'Nao encontrou informacoes associadas ao servico.',
    #         detail => 'Nao existia informacoes associadas ao servico.' });
    #}

    my $servico_atual = $c->stash->{guiche}->servico_atual->first;

    unless ($servico_atual) {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Nao encontrou um servico associado.',
             detail => 'Nao existia servico associado ao guiche.' });
    }

    $servico_atual->update
    ({ informacoes => $informacoes });

    $c->stash->{refresh_gerente} = 1;
    $c->stash->{refresh_guiche} ||= [];
    push @{$c->stash->{refresh_guiche}}, $c->stash->{guiche}->id_guiche;
}

sub iniciar_servico_atendimento :WSDLPort('GestaoAtendente') :DBICTransaction('DB') :MI {
    my ($self, $c, $query) = @_;

    my $now = $c->stash->{now};
    my $id_servico = $query->{servico}{id_servico};

    #pegando estado atual do guiche
    my $estado_guiche = $c->stash->{guiche}->estado_atual->search
      ({ },
       { prefetch => 'estado' })->first;
    #guiche tem que estar atendimento para iniciar servico atendimento
    unless ($estado_guiche && ($estado_guiche->estado->nome eq 'atendimento')) {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Estado invalido',
             detail => 'Guiche deve estar "atendimento" para iniciar um serviço em atendimento.' });
    }

    #pegar atendimento atual do guiche_atendimento
    my $atend_guiche = $c->stash->{guiche}->atendimento_atual->find({});
    unless ($atend_guiche) {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Nao encontrou atendimento associado.',
             detail => 'Nao existia atendimento associado ao guiche.' });
    }

    #pegar atendimento atual do atendimento
    my $atendimento = $atend_guiche->atendimento;
    unless ($atendimento) {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Nao encontrou atendimento associado.',
             detail => 'Nao existia atendimento associado ao guiche.' });
    }
    
    
    #criando objeto servico_atendimento 
    $atendimento->servico_atual->create
      ({ vt_ini => $now,
         vt_fim => 'Infinity',
         id_servico =>  $id_servico,
         informacoes => '' });

    $c->stash->{refresh_gerente} = 1;
    $c->stash->{refresh_guiche} ||= [];
    push @{$c->stash->{refresh_guiche}}, $c->stash->{guiche}->id_guiche;

}

sub fechar_servico_atendimento: WSDLPort('GestaoAtendente') :DBICTransaction('DB') :MI {
    my ($self, $c, $query) = @_;

    my $id_servico = $query->{servico}{id_servico};
    
    my $now = $c->stash->{now};
    
    #pegando estado atual do guiche
    my $estado_guiche = $c->stash->{guiche}->estado_atual->search
      ({ },
       { prefetch => 'estado' })->first;
    #guiche tem que estar atendimento para iniciar servico atendimento
    unless ($estado_guiche && ($estado_guiche->estado->nome eq 'atendimento')) {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Estado invalido',
             detail => 'Guiche deve estar "atendimento" para iniciar um serviço em atendimento.' });
    }

    #pegar atendimento atual do guiche_atendimento
    my $atend_guiche = $c->stash->{guiche}->atendimento_atual->find({});
    unless ($atend_guiche) {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Nao encontrou atendimento associado.',
             detail => 'Nao existia atendimento associado ao guiche.' });
    }

    #pegar atendimento atual do atendimento
    my $atendimento = $atend_guiche->atendimento;
    unless ($atendimento) {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Nao encontrou atendimento associado.',
             detail => 'Nao existia atendimento associado ao guiche.' });
    }

    #pegando servico 
    my $servico_atual = $atendimento->servico_atual->search
      ({ id_servico => $id_servico });
       
    #encerra objeto servico
    $servico_atual->update
      ({ vt_fim => $now });

    $c->stash->{refresh_gerente} = 1;
    $c->stash->{refresh_guiche} ||= [];
    push @{$c->stash->{refresh_guiche}}, $c->stash->{guiche}->id_guiche;
}
sub setar_info_atendimento : WSDLPort('GestaoAtendente') :DBICTransaction('DB') :MI {
    my ($self, $c, $query) = @_;

    my $informacoes = $query->{servico}{informacoes};
    my $id_servico = $query->{servico}{id_servico};

    #unless ($informacoes) {
    #    die $c->stash->{soap}->fault
    #      ({ code => 'Server',
    #         reason => 'Nao encontrou informacoes associadas ao servico.',
    #         detail => 'Nao existia informacoes associadas ao servico.' });
    #}

    unless ($id_servico) {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Nao encontrou servico.',
             detail => 'Nao existia servico associado.' });
    }

    #pegar atendimento atual do guiche_atendimento
    my $atend_guiche = $c->stash->{guiche}->atendimento_atual->find({});
    unless ($atend_guiche) {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Nao encontrou atendimento associado.',
             detail => 'Nao existia atendimento associado ao guiche.' });
    }

    #pegar atendimento atual do atendimento
    my $atendimento = $atend_guiche->atendimento;
    unless ($atendimento) {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Nao encontrou atendimento associado.',
             detail => 'Nao existia atendimento associado ao guiche.' });
    }

    my $servico_atual = $atendimento->servico_atual->search
      ({ id_servico => $id_servico });

    unless ($servico_atual) {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Nao encontrou um servico associado.',
             detail => 'Nao existia servico associado ao guiche.' });
    }

    $servico_atual->update
    ({ informacoes => $informacoes });

    $c->stash->{refresh_gerente} = 1;
    $c->stash->{refresh_guiche} ||= [];
    push @{$c->stash->{refresh_guiche}}, $c->stash->{guiche}->id_guiche;
}

sub retornar_pausa : WSDLPort('GestaoAtendente') :DBICTransaction('DB') :MI {
    my ($self, $c) = @_;
    
    my $now = $c->stash->{now};
    my $estado_guiche = $c->stash->{guiche}->estado_atual->search
      ({ },
       { prefetch => 'estado' })->first;
    unless ($estado_guiche && ($estado_guiche->estado->nome eq 'pausa')) {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Estado invalido',
             detail => 'Guiche deve estar em "pausa" para voltar da pausa' });
    }

    if($estado_guiche->estado->nome eq 'pausa'){
        my $pausa = $c->stash->{guiche}->pausa_atual->first;
        if ($pausa) {
            $pausa->update
             ({vt_fim => $now});
        }
    }
    
    my $estado_concluido = $c->model('DB::TipoEstadoGuiche')->find
      ({ nome => 'concluido' });
    unless ($estado_concluido) {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Nao encontrou estado "concluido"',
             detail => 'Ocorreu um erro de configuracao no sistema.' });
    }

    $estado_guiche->update
      ({ vt_fim => $now });

    $c->stash->{guiche}->estados->create
      ({ vt_ini => $now,
         vt_fim => 'Infinity',
         id_estado => $estado_concluido->id_estado });

    $c->stash->{refresh_gerente} = 1;
    $c->stash->{refresh_guiche} ||= [];
    push @{$c->stash->{refresh_guiche}}, $c->stash->{guiche}->id_guiche;
    
}

sub mudar_senha: WSDLPort('GestaoAtendente') :DBICTransaction('DB') :MI{
	my ($self, $c, $query) = @_;

    my $senhaatual = $query->{guiche}{senha};
    my $novasenha = $query->{guiche}{estado};
    
    my $senhabanco = $c->stash->{funcionario}->get_column('password');
	
    unless($senhabanco eq md5_hex($senhaatual)){
   		die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Senhas não conferem',
             detail => 'Senha digitada não corresponde à senha atual.' });
    }
    
    $c->stash->{funcionario}->update( { password => md5_hex($novasenha) });
    $c->stash->{soap}->compile_return({ guiche => { senha => 'Senha alterada com sucesso' } });
		
}

1;

__END__

=head1 NAME

Atendente - Funcionalidades do atendente

=head1 DESCRIPTION

Este módulo implementa todas as funcionalidades disponíveis para o
atendente.

=cut


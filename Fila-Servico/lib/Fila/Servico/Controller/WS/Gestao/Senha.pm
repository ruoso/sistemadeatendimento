package Fila::Servico::Controller::WS::Gestao::Senha;
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

    my $local = $c->model('DB::Local')->search
      ({ 'me.jid_senhas' => $from,
         'me.vt_ini' => { '<=' => $now },
         'me.vt_fim' => { '>' => $now },
         'estados.vt_ini' => { '<=' => $now },
         'estados.vt_fim' => { '>' => $now },
         'estado.nome' => 'aberto'},
       { prefetch => { 'estados' => 'estado' }})->first();

    if ($local) {
        $c->stash->{local} = $local;
        $c->stash->{gerente} = $local->gerente_atual->first->funcionario;
    } else {
        $c->action->prepare_soap_helper($self, $c);
        $c->stash->{soap}->fault
          ({code => 'Server',
            reason => 'Permissao Negada',
            detail => 'Não é o emissor de senhas autorizado ou local nao esta aberto'});
        return 0;
    }
}

sub dados_local :WSDLPort('GestaoSenha') :DBICTransaction('DB') :MI {
    my ($self, $c, $query) = @_;
    $c->forward('/ws/gestao/local/dados_local');
}

sub listar_categorias :WSDLPort('GestaoSenha') :DBICTransaction('DB') :MI {
    my ($self, $c, $query) = @_;

    my $now = $c->stash->{now};

    
    my $ordem = $c->stash->{local}->configuracoes_categoria->search
      ({ 'me.vt_ini' => { '<=' => $now } ,
    	 'me.vt_fim' => { '>' => $now },
    	 'me.ordem' => { '<>' => 0 }}, { 'order_by' => 'me.ordem ASC' , prefetch => 'categoria' } );
    	 
   	unless ($ordem) {
   		die $c->stash->{soap}->fault(
   			{ code => 'Server' ,
   			  reason => 'Nao encontrou ordem das categorias do emissor',
   			  detail => 'Ocorreu um erro ao buscar a ordem das categorias do emissor.' }
   		);
   	}

    #my $categorias = $c->stash->{local}->configuracoes_categoria->search
    #  ({ 'me.vt_ini' => { '<=', $now },
    #     'me.vt_fim' => { '>', $now }},
    #   { prefetch => 'categoria' });

    my $cat = [];

    #while (my $categoria = $categorias->next) {
    #    push @$cat,
    #      { id_categoria => $categoria->id_categoria,
    #        nome => $categoria->categoria->nome,
    #        codigo => $categoria->categoria->codigo };
    #}
    while (my $categoria = $ordem->next) { 
    	push @$cat, 
    	  { id_categoria => $categoria->categoria->id_categoria,
    	    nome => $categoria->categoria->nome,
    	    codigo => $categoria->categoria->codigo,
            ordem => $categoria->ordem };
    } 


    $c->stash->{soap}->compile_return
      ({ lista_categorias => { categoria => $cat }});
}

sub solicitar_senha :WSDLPort('GestaoSenha') :DBICTransaction('DB') :MI {
    my ($self, $c, $query) = @_;

    # Temos que ver qual é a senha do atendimento mais recente nessa
    # categoria, para dar uma senha subsequente.
    my $id_categoria = $query->{atendimento}{id_categoria};
    unless ($id_categoria) {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Categoria nao Informada',
             detail => 'E preciso informar a categoria para solicitar uma senha'});
    }

    my $now = $c->stash->{now};
    
    my $categoria = $c->stash->{local}->configuracoes_categoria_atual->search
      ({ 'me.id_categoria' => $id_categoria },
       { prefetch => 'categoria' })->first;
    unless ($categoria) {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Categoria invalida',
             detail => 'Categoria nao existe, ou nao tem configuracao nesse local'});
    }

    my $estados = $c->stash->{local}->estado_atual->search
      ({ },
       { 'prefetch' => 'estado' })->first;
    unless ($estados->estado->nome eq 'aberto') {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Local nao esta aberto',
             detail => 'Local precisa estar aberto para solicitar uma senha'});
    }

    my $abertura = $estados->vt_ini;

    # encontrar o atendimento mais recente desde que o local foi
    # aberto.

    my $codigo_senha_atual = 0;
    my $recente = $c->stash->{local}->atendimentos->search
      ({ 'vt_ini' => { '>=', $abertura },
         'categoria.id_categoria' => $id_categoria },
       { 'order_by' => 'me.vt_ini DESC',
         'prefetch' => { 'senha' => 'categoria' },
         'rows' => 1 })->first;
    if ($recente) {
        $codigo_senha_atual = $recente->senha->codigo;
    }


    # se a senha gerada estiver alocada a um atendimento corrente,
    # tentar a proxima, até encontrar uma senha válida.

    my $started_at = $codigo_senha_atual;
    my $recicled = 0;

  CHECARSENHA:
    do {
        if ($codigo_senha_atual >= 999) {
            # as senhas acabaram, vamos reiniciar.
            $codigo_senha_atual = 0;
            $recicled = 1;
        }

        $codigo_senha_atual++;

        if ($recicled &&
            $codigo_senha_atual >= $started_at) {
            die $c->stash->{soap}->fault
              ({ code => 'Server',
                 reason => 'Erro ao atribuir senha',
                 detail => 'Sistema nao conseguiu atribuir uma senha nova.' });
        }

        # verificar se a senha está disponível.
        my $verificar = $c->model('DB::Senha')->search
          ({ 'me.id_categoria' => $id_categoria,
             'me.codigo' => $codigo_senha_atual,
             'atendimentos.vt_ini' => { '>=' => $now },
             'atendimentos.vt_fim' => { '<'  => $now },
             'atendimentos.id_local' => $c->stash->{local}->id_local },
           { join => 'atendimentos' });
        if ($verificar->first) {
            goto CHECARSENHA;
        }
    };

    my $senha = $c->stash->{local}->senhas->find
      ({ 'me.id_categoria' => $id_categoria,
         'me.codigo' => $codigo_senha_atual });
    unless ($senha) {
         die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Nao conseguiu encontrar senha',
             detail => 'Houve um erro de configuracao no sistema.' });
    }

    my $estado_espera = $c->model('DB::TipoEstadoAtendimento')->find
      ({ nome => 'espera' });
    unless ($estado_espera) {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Nao conseguiu encontrar estado de atendimento "espera"',
             detail => 'Houve um erro de configuracao no sistema.' });
    }

    # Criar um atendimento novo, associado a essa senha, a categoria
    # dessa senha e esse local, com o estado "espera".
    my $atendimento = $c->model('DB::Atendimento')->create
      ({ id_senha => $senha->id_senha,
         id_local => $c->stash->{local}->id_local,
         vt_ini => $now,
         vt_fim => 'Infinity',
         estados =>
         [{ id_estado => $estado_espera->id_estado,
            vt_ini => $now,
            vt_fim => 'Infinity' }],
         categorias =>
         [{ id_categoria => $id_categoria,
            vt_ini => $now,
            vt_fim => 'Infinity' }]});

    # disparar o escalonamento.
    $c->stash->{escalonar_senha} = 1;

    # retornar esse atendimento.
    $c->stash->{soap}->compile_return
      ({ atendimento =>
         { id_atendimento => $atendimento->id_atendimento,
           vt_ini => DateTime::Format::XSD->format_datetime($now),
           id_local => $c->stash->{local}->id_local,
           id_senha => $senha->id_senha,
           id_categoria => $senha->id_categoria,
           senha => sprintf('%s%03d', $categoria->categoria->codigo, $codigo_senha_atual),
           estado => 'espera' }});
}

1;

__END__

=head1 NAME

Senha - Regras para o emissor de senhas

=head1 DESCRIPTION

Esse módulo implementa os serviços disponíveis para o emissor de senha.

=cut


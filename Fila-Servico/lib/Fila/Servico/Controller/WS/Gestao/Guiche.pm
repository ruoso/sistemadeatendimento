package Fila::Servico::Controller::WS::Gestao::Guiche;
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

    # GestaoGuiche exige que seja um funcionario de um local., então se
    # esse "from" não for o funcionario de nenhum local, já retornamos
    # um fault daqui, senão guardamos o gerente no stash com prefetch
    # do local.
    my $now = $c->stash->{now};
    my $funcionario = $c->model('DB::Funcionario')->search
      ({ jid => $from,
         'locais.vt_ini' => { '<=' => $now },
         'locais.vt_fim' => { '>' => $now },
         'local.vt_ini' => { '<=' => $now },
         'local.vt_fim' => { '>' => $now },
         'estados.vt_ini' => { '<=' => $now },
         'estados.vt_fim' => { '>' => $now },
         'estado.nome' => ['aberto','senhas_encerradas']},
       { prefetch => { 'locais' =>
           { 'local' => { 'estados' => 'estado' } }}})->first();

    if ($funcionario) {
        $c->stash->{funcionario} = $funcionario;
        $c->stash->{local} = $funcionario->locais->first->local;
        $c->stash->{gerente} = $c->stash->{local}->gerentes->first;
    } else {
        $c->action->prepare_soap_helper($self, $c);
        $c->stash->{soap}->fault
          ({code => 'Server',
            reason => 'Permissao Negada',
            detail => 'Funcionario nao trabalha no local ou local nao esta aberto'});
        return 0;
    }
}

sub dados_local :WSDLPort('GestaoGuiche') :DBICTransaction('DB') :MI {
    my ($self, $c, $query) = @_;
    $c->forward('/ws/gestao/local/dados_local');
}

sub listar_guiches :WSDLPort('GestaoGuiche') :DBICTransaction('DB') :MI {
    my ($self, $c, $query) = @_;
    my $now = $c->stash->{now};

    my $guiches = $c->stash->{local}->guiches->search
      ({ 'me.vt_ini' => { '<=', $now },
         'me.vt_fim' => { '>', $now },
         'estados.vt_ini' => { '<=', $now },
         'estados.vt_fim' => { '>', $now }},
       { prefetch => { 'estados' => 'estado' }});

    my $lista_guiches = [];

    while (my $guiche = $guiches->next) {
        push @$lista_guiches,
          {( map { $_ => $guiche->$_() }
             qw/id_local id_guiche identificador/ ),
           estado => $guiche->estados->first->estado->nome };
    }

    $c->stash->{soap}->compile_return
      ({ lista_guiches => { guiche => $lista_guiches } });
}

sub listar_categorias :WSDLPort('GestaoGuiche') :DBICTransaction('DB') :MI {
    my ($self, $c, $query) = @_;
    my $now = $c->stash->{now};

    my $categorias = $c->stash->{local}->configuracoes_categoria->search
      ({ 'me.vt_ini' => { '<=', $now },
         'me.vt_fim' => { '>', $now }},
       { prefetch => 'categoria',
         order_by => 'codigo' });

    my $lista_categorias = [];

    while (my $categoria = $categorias->next) {
      my $ca = $categoria->categoria;
        push @$lista_categorias,
          {( map { $_ => $ca->$_() }
             qw/id_categoria codigo nome/ )};
    }

    $c->stash->{soap}->compile_return
      ({ lista_categorias => { categoria => $lista_categorias } });
}

sub abrir_guiche :WSDLPort('GestaoGuiche') :DBICTransaction('DB') :MI {
    my ($self, $c, $query) = @_;

    #Pega o id do guiche que foi enviado para ser aberto
    my $guiche = $c->model('DB::Guiche')->find($query->{guiche});

    #Pega status do guiche
    my $now = $c->stash->{now};
    my $status  = $guiche->estados->search
      ({ vt_ini => { '<=', $now },
         vt_fim => { '>', $now }},
       { prefetch => 'estado' })->first;

    if ($status && $status->estado->nome ne 'fechado') {
        die $c->stash->{soap}->fault
          ({code => 'Server',
            reason => 'Guiche ja aberto',
            detail => 'O guiche precisa estar fechado para ser aberto'});
    } elsif ($status) {
        $status->update({ vt_fim => $now })
    }

    my $estado_aberto = $c->model('DB::TipoEstadoGuiche')->find
      ({ nome => 'disponivel' });

    unless ($estado_aberto) {
        die $c->stash->{soap}->fault
          ({code => 'Server',
            reason => 'Nao pode encontrar estado "disponivel"',
            detail => 'Existe um erro de configuracao no banco de dados'});
    }

    $guiche->estados->create
      ({ id_estado => $estado_aberto->id_estado,
         vt_ini => $now,
         vt_fim => 'Infinity' });

    $guiche->atendentes->create
      ({ id_funcionario => $c->stash->{funcionario}->id_funcionario,
         vt_ini => $now,
         vt_fim => 'Infinity' });

    $c->stash->{guiche} = $guiche;
    $c->stash->{escalonar_senha} = 1;
    $c->stash->{refresh_gerente} = 1;

}


__PACKAGE__;


__END__

=head1 NAME

Guiche - Permite a abertura do guichê

=head1 DESCRIPTION

Esse módulo permite a um funcionário que ainda não está associado a um
guichê, listar os guichês e abrir um.

=cut


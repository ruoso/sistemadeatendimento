package Fila::Servico::Controller::WS::Gestao::Local;
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
use Carp qw(croak);
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

    # GestaoLocal exige que seja um gerente, então se esse "from" não
    # for o gerente de nenhum local, já retornamos um fault daqui, senão
    # guardamos o gerente no stash com prefetch do local.
    my $now = $c->stash->{now};
    my $funcionario = $c->model('DB::Funcionario')->search
      ({ jid => $from,
         'gerentes.vt_ini' => { '<=' => $now },
         'gerentes.vt_fim' => { '>' => $now },
         'local.vt_ini' => { '<=' => $now },
         'local.vt_fim' => { '>' => $now }},
       { prefetch => { 'gerentes' => 'local' } })->first();

    if ($funcionario) {
        $c->stash->{funcionario} = $funcionario;
        $c->stash->{gerente} = $funcionario->gerentes->first;
        $c->stash->{local} = $c->stash->{gerente}->local;
        return 1;
    } else {
        $c->action->prepare_soap_helper($self, $c);
        $c->stash->{soap}->fault
          ({code => 'Server',
            reason => 'Permissao Negada',
            detail => 'Funcionario precisa ser gerente para acessar'});
        return 0;
    }
}

sub refresh_painel :Private {
    my ($self, $c) = @_;
    return unless $c->stash->{local};
    my $atendimentos = $c->stash->{local}->atendimentos_atuais->search
      ({ 'estado.nome' => 'chamando' },
       { prefetch => [{ 'estado_atual' => 'estado' },
                      { 'senha' => 'categoria' },
                      { 'guiche_atual' => 'guiche' }]});
    my $ret = [];
    while (my $atendimento = $atendimentos->next) {
        my $id = $atendimento->guiche_atual->first->guiche->identificador;
        $id =~ s/(^\s+|\s+$)//gs;
        push @$ret, { senha => sprintf('%s%03d', $atendimento->senha->categoria->codigo,
                                       $atendimento->senha->codigo),
                      guiche => $id };
    }

    $c->model('SOAP')->transport->connection($c->engine->connection($c));
    $c->model('SOAP')->transport->addrs([$c->stash->{local}->jid_painel.'/callback']);
    $c->model('SOAP::Painel')->senhas_chamando({ senhas_chamando => { senha => $ret }});

}

sub refresh_gerente :Private {
    my ($self, $c) = @_;

    # esse método é chamado por outras ações que precisam fazer um
    # callback para o gerente do local. As informações todas são
    # enviadas, para que possa ser apresentada a tela.

    my $storage = $c->model('DB')->storage;
    $storage->ensure_connected;

    $storage->txn_do
      (sub {
         # Essa operação é somente leitura, dessa forma, vamos mandar o
         # model alterar o tipo da transação, de forma a reduzir a
         # contenção de locks
         $storage->dbh->do('SET TRANSACTION READ ONLY');

         my $local = $self->status_local($c, {});
         my $guiches = $self->status_guiches($c, {});
         my $encaminhamentos = $self->listar_encaminhamentos($c, {});

         my $old = $c->stash->{soap}->compile_return();
         $c->model('SOAP')->transport->connection
           ($c->engine->connection($c));
         $c->model('SOAP')->transport->addrs
           ([$c->stash->{local}->gerente_atual->first->funcionario->jid.'/cb/render/gerente']);
         $c->model('SOAP::CB::Gerente')->render_gerente
           ({ %$local, %$guiches, %$encaminhamentos });
         $c->stash->{soap}->compile_return($old);
       });
}


sub dados_local :WSDLPort('GestaoLocal') :DBICTransaction('DB') :MI {
    my ($self, $c, $query) = @_;

    my $now = $c->stash->{now};
    my $status  = $c->stash->{local}->estados->search
      ({ 'me.vt_ini' => { '<=', $now },
         'me.vt_fim' => { '>', $now }},
       {
        prefetch =>  'estado' })->first;

    $c->stash->{soap}->compile_return
      ({ local =>
         {
          ( map { $_ => $c->stash->{local}->$_() }
            qw/ id_local nome / ),
          ( map { ( $c->stash->{local}->$_ &&
                    $c->stash->{local}->$_->is_infinite ) ? () :
                      ($_ => DateTime::Format::XSD->format_datetime
                       ($c->stash->{local}->$_)) }
            qw/ vt_ini vt_fim / ),
          estado => $status->estado->nome,
          jid_gerente => $c->stash->{local}->gerente_atual->first->funcionario->jid
         }
       });
}

sub abrir_local :WSDLPort('GestaoLocal') :DBICTransaction('DB') :MI {
    my ($self, $c, $query) = @_;

    my $now = $c->stash->{now};

    my $status  = $c->stash->{local}->estados->search
      ({ vt_ini => { '<=', $now },
         vt_fim => { '>', $now }},
       {
        prefetch => 'estado' })->first;

    if ($status && $status->estado->nome eq 'aberto') {
        die $c->stash->{soap}->fault
          ({code => 'Server',
            reason => 'Local ja aberto',
            detail => 'O local ja se encontra aberto'});
    } elsif ($status) {
        $status->update({ vt_fim => $now })
    }

    my $estado_aberto = $c->model('DB::TipoEstadoLocal')->find
      ({ nome => 'aberto' });

    unless ($estado_aberto) {
        die $c->stash->{soap}->fault
          ({code => 'Server',
            reason => 'Nao pode encontrar estado "aberto"',
            detail => 'Existe um erro de configuracao no banco de dados'});
    }

    $c->stash->{local}->estados->create
      ({ id_estado => $estado_aberto->id_estado,
         vt_ini => $now,
         vt_fim => 'Infinity' });

    $c->model('SOAP')->transport->connection($c->engine->connection($c));
    $c->model('SOAP')->transport->addrs([$c->stash->{local}->jid_senhas.'/callback']);
    $c->model('SOAP::Senha')->local_aberto({ refresh_request => '' });

    $c->stash->{refresh_gerente} = 1;
}

sub encerrar_senhas :WSDLPort('GestaoLocal') :DBICTransaction('DB') :MI {
    my ($self, $c, $query) = @_;

    my $now = $c->stash->{now};
    my $status  = $c->stash->{local}->estados->search
      ({ vt_ini => { '<=', $now },
         vt_fim => { '>', $now }},
       {
        prefetch => 'estado' })->first;

    if ($status && $status->estado->nome ne 'aberto') {
        die $c->stash->{soap}->fault
          ({code => 'Server',
            reason => 'Local nao esta aberto',
            detail => 'O local precisa estar aberto'});
    } elsif ($status) {
        $status->update({ vt_fim => $now })
    }

    my $estado_senc = $c->model('DB::TipoEstadoLocal')->find
      ({ nome => 'senhas_encerradas' });

    unless ($estado_senc) {
        die $c->stash->{soap}->fault
          ({code => 'Server',
            reason => 'Nao pode encontrar estado "senhas_encerradas"',
            detail => 'Existe um erro de configuracao no banco de dados'});
    }

    $c->stash->{local}->estados->create
      ({ id_estado => $estado_senc->id_estado,
         vt_ini => $now,
         vt_fim => 'Infinity' });

    $c->model('SOAP')->transport->connection($c->engine->connection($c));
    $c->model('SOAP')->transport->addrs([$c->stash->{local}->jid_senhas.'/callback']);
    $c->model('SOAP::Senha')->senhas_encerradas({ refresh_request => '' });

    $c->stash->{refresh_gerente} = 1;
}

sub status_local :WSDLPort('GestaoLocal') :DBICTransaction('DB') :MI {
    my ($self, $c, $query) = @_;
    my %categorias;
    my $agregado = {};
    my $now = $c->stash->{now};

    my $estado_local_aberto = $c->model('DB::TipoEstadoLocal')->find
      ({ nome => 'aberto' });
    
    unless ($estado_local_aberto) {
        die $c->stash->{soap}->fault
          ({code => 'Server',
            reason => 'Nao pode encontrar estado "aberto"',
            detail => 'Existe um erro de configuracao no banco de dados'});
    }
    # minha modificação

    my $id_gerente = $c->stash->{gerente}->id_funcionario;
    my $busca_gerente = $c->model('DB::Funcionario')->find
      ({ id_funcionario => $id_gerente });
    my $gerente = $busca_gerente->nome;
    require Data::Dumper;
    print STDERR "O hash é ", Data::Dumper::Dumper( \$gerente ), "\n";

    # agora tah faltando 'mandar 'o $gerente para ser mostrado no template
	
    # obter o tempo maximo em espera por categoria,
    # o agregado pode ser obtido sem outra consulta.
    my $lista = $c->stash->{local}->configuracoes_categoria_atual->search
      ({ 'estado.nome' => 'espera' },
       { join => { categoria =>
                   { atendimentos_atuais =>
                     { atendimento =>
                       {
                        estado_atual => 'estado' }}}},
         select => [ 'me.id_categoria',
                     'categoria.codigo',
                     {
                      min => 'estado_atual.vt_ini' },
                     {
                      count => 'atendimento.id_atendimento' },
                     'me.limite_tempo_espera',
                     'me.limite_pessoas_espera' ],
         as => ['id_categoria',
                'codigo',
                'espera_mais_antiga',
                'quantidade_espera',
                'limite_tempo_espera',
                'limite_pessoas_espera'],
         group_by => [ 'me.id_categoria', 'categoria.codigo',
                       'me.limite_tempo_espera', 'me.limite_pessoas_espera' ]});

    while (my $categoria = $lista->next) {
        my $id_categoria = $categoria->get_column('id_categoria');
        $categorias{$id_categoria} ||=
          {
           codigo => $categoria->get_column('codigo') };

        my $espera = $categoria->get_column('espera_mais_antiga');

        $espera =
          DateTime::Format::XSD->format_datetime
              (DateTime::Format::Pg->parse_datetime($espera)
               ->set_time_zone('local'))
                if $espera;

        if ($espera && $categoria->get_column('limite_tempo_espera')) {
            my $base = DateTime::Format::XSD->parse_datetime($espera);
            my $dif = DateTime->now(time_zone => 'local')->subtract_datetime
              ($base);
            my $lim = DateTime::Duration->new(seconds => $categoria->get_column('limite_tempo_espera'));
            if (DateTime::Duration->compare($dif,$lim,$base) > 0) {
                $categorias{$id_categoria}{alert} = 1;
            }
        }

        $agregado->{espera_mais_antiga} ||= $espera;
        $agregado->{espera_mais_antiga} = $espera
          if $espera && $espera lt $agregado->{espera_mais_antiga};

        $categorias{$id_categoria}{espera_mais_antiga} = $espera;

        my $quant = $categoria->get_column('quantidade_espera');
        $agregado->{quantidade_espera} ||= 0;
        $agregado->{quantidade_espera} += $quant;

        if ($quant && $quant > $categoria->get_column('limite_pessoas_espera')) {
            $categorias{$id_categoria}{alert} = 1;
        }

        $categorias{$id_categoria}{quantidade_espera} = $quant;
    }


    {
        # obter o tempo média de espera e de atendimento nas últimas 4 horas.
        # por categoria
        my $lista = $c->stash->{local}->configuracoes_categoria->search
          ({ 'me.vt_ini' => { '<=', $now },
             'me.vt_fim' => { '>', $now },
             -and =>
             [{ -or =>
                [{ 'estados.vt_ini' => { '>=', $now->clone->subtract( hours => 4) } },
                 {
                  'estados.vt_ini' => undef }]},
              { -or =>
                [{ 'estados.vt_fim' => { '<=', $now } },
                 {
                  'estados.vt_fim' => undef }]},
              {
               'estado.nome' => [ 'espera', 'atendimento', undef ] }]},
           { join => { categoria =>
                       { atendimentos =>
                         { atendimento =>
                           {
                            estados => 'estado' }}}},
             select => [ 'me.id_categoria',
                         'categoria.codigo',
                         'estado.nome',
                         { 'to_char',
                           [{ avg => 'estados.vt_fim - estados.vt_ini' },\"'HH24:MI:SS'" #"
                           ]}],
             as => ['id_categoria',
                    'codigo',
                    'estado',
                    'media'],
             group_by => [ 'me.id_categoria', 'categoria.codigo', 'estados.id_estado', 'estado.nome' ] });


        while (my $categoria_estado = $lista->next) {
            my $estado = $categoria_estado->get_column('estado');
            next unless $estado && $estado =~ /^(espera|atendimento)$/;

            my $id_categoria = $categoria_estado->get_column('id_categoria');
            $categorias{$id_categoria} ||=
              {
               codigo => $categoria_estado->get_column('codigo') };

            $categorias{$id_categoria}{"tempo_medio_".$estado} = $categoria_estado->get_column('media');
        }
    }


    {
        # agregado
        my $lista = $c->stash->{local}->configuracoes_categoria->search
          ({ 'me.vt_ini' => { '<=', $now },
             'me.vt_fim' => { '>', $now },
             -and => [
                      { -or => [
                                {
                                 'estados.vt_ini' => { '>=', $now->clone->subtract( hours => 4) } },
                                {
                                 'estados.vt_ini' => undef }]},
                      { -or => [
                                {
                                 'estados.vt_fim' => { '<=', $now } },
                                {
                                 'estados.vt_fim' => undef }]},
                      {
                       'estado.nome' => [ 'espera', 'atendimento', undef ] }]},
           { join => { categoria =>
                       { atendimentos =>
                         { atendimento =>
                           {
                            estados => 'estado' }}}},
             select => [ 'estado.nome',
                         {
                          'to_char', [{ avg => 'estados.vt_fim - estados.vt_ini' },\"'HH24:MI:SS'" #"
                                     ]}],
             as => ['estado',
                    'media'],
             group_by => [ 'estados.id_estado', 'estado.nome' ] });

        while (my $estado = $lista->next) {
            my $strestado = $estado->get_column('estado');
            next unless $strestado && $strestado =~ /^(espera|atendimento)$/;

            $agregado->{"tempo_medio_".$strestado} = $estado->get_column('media');
        }
    }

    my $estado_local  = $c->stash->{local}->estado_atual->search
      ({ },
       {
        prefetch =>  'estado' })->first;

    #encaminhamentos

    #pegar ultimo vt_ini do ultimo estadoaberto do local.
    my $ultimo_aberto  = $c->stash->{local}->estados->search
      ({ 
        'estado.nome' => $estado_local_aberto->nome }, { 
                                                        join => 'estado', 
                                                        order_by => 'vt_ini DESC'
                                                       })->first;

    my $total_enc=0;
    my $total_enc_abertos=0;

    if ($ultimo_aberto) {

        my $enc = $c->model('DB::GuicheEncaminhamento')->find(
                                                              {
                                                               'me.vt_ini' => { '>=', $ultimo_aberto->get_column('vt_ini') }
                                                              },
                                                              {
                                                               select => [ { count => 'me.id_atendimento' } ],
                                                               as     => [ 'encaminhamentos' ]
                                                              }
                                                             );

        $total_enc = $enc->get_column('encaminhamentos');

        #encaminhamentos ainda sem atendimento
        $enc = $c->model('DB::GuicheEncaminhamento')->find(
                                                           { 
                                                            'me.vt_ini' => { '>=', $ultimo_aberto->get_column('vt_ini') },
                                                            'me.vt_fim' => 'Infinity'
                                                           },
                                                           {
                                                            select => [ { count => 'me.id_atendimento' } ],
                                                            as     => [ 'encaminhamentos' ]
                                                           }
                                                          );

        $total_enc_abertos = $enc->get_column('encaminhamentos');
    }

    return $c->stash->{soap}->compile_return
      ({ local =>
         {
          estado => $estado_local->estado->nome,
          encaminhamentos => $total_enc,
          encaminhamentos_abertos => $total_enc_abertos,
          ( map { $_ => $c->stash->{local}->$_() }
            qw/ id_local nome / ),
          ( map { $c->stash->{local}->$_->is_infinite ? () :
                    ($_ => DateTime::Format::XSD->format_datetime
                     ($c->stash->{local}->$_)) }
            qw/ vt_ini vt_fim / ),
          status =>
          {
           agregado => $agregado,
           categorias =>
           { categoria =>
             [ map { { id_categoria => $_, %{$categorias{$_}} } }
               keys %categorias ] }
          }}
       });
}

sub fechar_local_force :WSDLPort('GestaoLocal') :DBICTransaction('DB') :MI {
    my ($self, $c, $query) = @_;

    my $now = $c->stash->{now};
    my $status  = $c->stash->{local}->estados->search
      ({ vt_ini => { '<=', $now },
         vt_fim => { '>', $now }},
       { prefetch => 'estado' })->first;

    if ($status &&
        $status->estado->nome ne 'aberto' &&
        $status->estado->nome ne 'senhas_encerradas') {
        die $c->stash->{soap}->fault
          ({code => 'Server',
            reason => 'Estado invalido',
            detail => 'O local precisa estar aberto ou com senhas encerradas'});
    } elsif ($status) {
        $status->update({ vt_fim => $now })
    }

    my $estado_encerrado = $c->model('DB::TipoEstadoAtendimento')->find
      ({ nome => 'encerrado' });
    unless ($estado_encerrado) {
        die $c->stash->{soap}->fault
          ({code => 'Server',
            reason => 'Nao pode encontrar estado "encerrado"',
            detail => 'Existe um erro de configuracao no banco de dados'});
    }

    my $atendimentos_nao_fechados = $c->stash->{local}->atendimentos_atuais;
    while (my $atendimento = $atendimentos_nao_fechados->next) {
        # forcar o fechamento do atendimento.
        my $estado_atual = $atendimento->estado_atual->first;
        $estado_atual->update({ vt_fim => $now }) if $estado_atual;
        $atendimento->estados->create
          ({ vt_ini => $now,
             vt_fim => 'Infinity',
             id_estado => $estado_encerrado->id_estado });

        # ver se esta associado a guiche.
        my $guiche_atual = $atendimento->guiche_atual->first;
        $guiche_atual->update({ vt_fim => $now }) if $guiche_atual;

        # ver se tem algum servico associado.
        my $servico_atual = $atendimento->servico_atual->first;
        $servico_atual->update({ vt_fim => $now }) if $servico_atual;

        # encerrar o atendimento
        $atendimento->update({ vt_fim => $now }) if $atendimento;
    }


    my $guiches_nao_fechados = $c->stash->{local}->guiches_atuais->search
      ({ 'estado.nome' => { '!=', 'fechado' }},
       { prefetch => { estado_atual => 'estado' } });

    my $estado_fechado_guiche = $c->model('DB::TipoEstadoGuiche')->find
      ({ nome => 'fechado' });

    unless ($estado_fechado_guiche) {
        die $c->stash->{soap}->fault
          ({code => 'Server',
            reason => 'Nao pode encontrar estado "fechado"',
            detail => 'Existe um erro de configuracao no banco de dados'});
    }

    while (my $guiche = $guiches_nao_fechados->next) {
        # forcar o fechamento do guiche.
        my $estado_atual = $guiche->estado_atual->first;
        $estado_atual->update({ vt_fim => $now }) if $estado_atual;
        $guiche->estados->create
          ({ vt_ini => $now,
             vt_fim => 'Infinity',
             id_estado => $estado_fechado_guiche->id_estado });

        # dessasociar o atendente.
        my $atendente_atual = $guiche->atendente_atual->first;
        $atendente_atual->update({ vt_fim => $now }) if $atendente_atual;

        # encerrar alguma pausa
        my $pausa_atual = $guiche->pausa_atual->first;
        $pausa_atual->update({ vt_fim => $now }) if $pausa_atual;

        # enverrar algum servico
        my $servico_atual = $guiche->servico_atual->first;
        $servico_atual->update({ vt_fim => $now }) if $servico_atual;
    }


    my $estado_fechado = $c->model('DB::TipoEstadoLocal')->find
      ({ nome => 'fechado' });

    unless ($estado_fechado) {
        die $c->stash->{soap}->fault
          ({code => 'Server',
            reason => 'Nao pode encontrar estado "fechado"',
            detail => 'Existe um erro de configuracao no banco de dados'});
    }

    $c->stash->{local}->estados->create
      ({ id_estado => $estado_fechado->id_estado,
         vt_ini => $now,
         vt_fim => 'Infinity' });

    $c->stash->{refresh_gerente} = 1;
}

sub fechar_local :WSDLPort('GestaoLocal') :DBICTransaction('DB') :MI {
    my ($self, $c, $query) = @_;

    my $now = $c->stash->{now};
    my $status  = $c->stash->{local}->estados->search
      ({ vt_ini => { '<=', $now },
         vt_fim => { '>', $now }},
       {
        prefetch => 'estado' })->first;

    if ($status &&
        $status->estado->nome ne 'aberto' &&
        $status->estado->nome ne 'senhas_encerradas') {
        die $c->stash->{soap}->fault
          ({code => 'Server',
            reason => 'Estado invalido',
            detail => 'O local precisa estar aberto ou com senhas encerradas'});
    } elsif ($status) {
        $status->update({ vt_fim => $now })
    }

    my $guiches_nao_fechados = $c->stash->{local}->guiches_atuais->search
      ({ 'estado.nome' => { '!=', 'fechado' }},
       {
        prefetch => { estado_atual => 'estado' } });

    if ($guiches_nao_fechados->next) {
        die $c->stash->{soap}->fault
          ({code => 'Server',
            reason => 'Guiches nao estao fechados',
            detail => 'O local so pode ser fechado quando todos os '
            .'guiches estiverem fechados'});
    }

    my $atendimentos_nao_fechados = $c->stash->{local}->atendimentos_atuais;

    if ($atendimentos_nao_fechados->next) {
        die $c->stash->{soap}->fault
          ({code => 'Server',
            reason => 'Atendimentos nao estao encerrados',
            detail => 'O local so pode ser fechado quando todos os '
            .'atendimentos estiverem encerrados'});
    }

    my $estado_fechado = $c->model('DB::TipoEstadoLocal')->find
      ({ nome => 'fechado' });

    unless ($estado_fechado) {
        die $c->stash->{soap}->fault
          ({code => 'Server',
            reason => 'Nao pode encontrar estado "fechado"',
            detail => 'Existe um erro de configuracao no banco de dados'});
    }

    $c->stash->{local}->estados->create
      ({ id_estado => $estado_fechado->id_estado,
         vt_ini => $now,
         vt_fim => 'Infinity' });

    $c->stash->{refresh_gerente} = 1;
}

sub status_guiches :WSDLPort('GestaoLocal') :DBICTransaction('DB') :MI {
    my ($self, $c, $query) = @_;

    my $now = $c->stash->{now};

    my $guiches = $c->stash->{local}->guiches->search
      ({ 'me.vt_ini' => { '<=', $now },
         'me.vt_fim' => { '>', $now  },
         'limites_atuais.id_local' => [ undef, $c->stash->{local}->id_local ] },
       {
        'join'   => [{ 'estado_atual' => { 'estado' => 'limites_atuais' } },
                     'pausa_atual',
                     {
                      'servico_atual' => 'servico' },
                     { 'atendimento_atual' => { 'atendimento' =>
                                                [ { 'senha' => 'categoria' },
                                                  {
                                                   'estado_atual' => 'estado' } ]}},
                     {
                      'atendente_atual' => 'funcionario' }],
        'select' => [ 'me.id_guiche',
                      'me.identificador',
                      'me.pular_opiniometro',
                      'funcionario.id_funcionario',
                      'funcionario.nome',
                      'funcionario.jid',
                      'estado.nome',
                      'estado_atual.vt_ini',
                      'categoria.codigo',
                      'senha.codigo',
                      'estado_2.nome',
                      'estado_atual_2.vt_ini',
                      'atendimento.id_atendimento',
                      'pausa_atual.motivo',
                      'servico.nome',
                      'limites_atuais.segundos',
                    ],
        'as'     => [ 'id_guiche',
                      'identificador',
                      'pular_opiniometro',
                      'id_funcionario',
                      'funcionario',
                      'jid',
                      'estado',
                      'estado_desde',
                      'codigo_categoria',
                      'codigo_senha',
                      'estado_atendimento',
                      'estado_atendimento_desde',
                      'id_atendimento',
                      'pausa_motivo',
                      'nome_servico',
                      'limite'
                    ],
        'order_by' => [ 'me.id_guiche' ]
       });

    my $ret = [];
    while (my $guiche = $guiches->next) {

        my %dates =
          ( map { $guiche->get_column($_) ?
                    ($_ => DateTime::Format::XSD->format_datetime
                     (DateTime::Format::Pg->parse_datetime
                      ($guiche->get_column($_))->set_time_zone('local'))) : () }
            qw/ estado_desde estado_atendimento_desde / );

        my $alert = 0;
        if ($dates{estado_desde} && $guiche->get_column('limite')) {
            my $base = DateTime::Format::XSD->parse_datetime($dates{estado_desde});
            my $dif = DateTime->now(time_zone => 'local')->subtract_datetime
              ($base);
            my $sec = DateTime::Duration->new('seconds' => $guiche->get_column('limite'));
            if (DateTime::Duration->compare($dif,$sec,$base) > 0) {
                $alert = 1;
            }
        }

        push @$ret,
          {
           ( map { $_ => $guiche->get_column($_) }
             qw( id_guiche identificador pular_opiniometro estado estado_atendimento
                  funcionario id_funcionario jid id_atendimento pausa_motivo nome_servico  ) ),
           %dates,
           id_local => $c->stash->{local}->id_local,
           alert => $alert,
           senha => $guiche->get_column('codigo_senha') ?
           ( sprintf('%s%03d', ( map { $guiche->get_column($_) || '' }
                                 qw( codigo_categoria codigo_senha ) )) ) : '',
          }
      }

    $c->stash->{soap}->compile_return
      ({ lista_guiches => { guiche => $ret } });

}

sub escalonar_senha :WSDLPort('GestaoLocal') :DBICTransaction('DB') :MI {
    my ($self, $c) = @_;

    # descobrir os guiches disponiveis, e atribuir atendimentos para
    # eles.
    my $now = $c->stash->{now};
    my $guiches = $c->stash->{local}->guiches->search
      ({ 'estado.nome' => 'disponivel',
         'estados.vt_ini' => { '<=', $now },
         'estados.vt_fim' => { '>', $now },
         'me.vt_ini' => { '<=', $now },
         'me.vt_fim' => { '>', $now }
       },
       { 'prefetch' => { 'estados' => 'estado' },
         'order_by' => 'estados.vt_ini'
       });

    my $estado_chamando = $c->model('DB::TipoEstadoAtendimento')->find
      ({ 'nome' => 'chamando' });
    unless ($estado_chamando) {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Estado de atendimento "chamando" nao encontrado',
             detail => 'Ocorreu um erro de configuracao no servidor' });
    }

    my $estado_chamando_guiche = $c->model('DB::TipoEstadoGuiche')->find
      ({ 'nome' => 'chamando' });
    unless ($estado_chamando_guiche) {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Estado de guiche "chamando" nao encontrado',
             detail => 'Ocorreu um erro de configuracao no servidor' });
    }


    while (my $guiche = $guiches->next) {

        my $encaminhamento = $guiche->encaminhamentos_atuais->first;
        my $atendimento;

        if ($encaminhamento) {
	  $atendimento = $encaminhamento->atendimento;
	  $encaminhamento->update({ vt_fim => $now });
	} else {
	  # precisamos descobrir se esse guiche tem categorias
	  # configuradas, no caso de ele ter, a consulta de
	  # atendimentos em espera irá se restringir a esse conjunto
	  # de categorias.
	  my @ids = map { $_->id_categoria } $guiche->categorias_atuais;
	  my %restringir;
	  if (@ids) {
	    %restringir = ( 'categoria_atual.id_categoria' => { 'IN' => \@ids });
	  }

	  # descobrir os atendimentos em espera.  O escalonamento vai ter o
	  # conceito de proporção entre o tempo de espera dependendo da
	  # prioridade da categoria. A prioridade vai representar um
	  # multiplicador para o tempo de espera, o que significa que, se
	  # uma categoria tem prioridade 1, o tempo de espera vai ter a
	  # proporção de 1 para 1. Uma categoria com prioridade 2 significa
	  # que o tempo de espera vai significar o dobro. Ou seja, se uma
	  # pessoa está esperando 10 minutos em uma categoria de prioridade
	  # 2 vai representar para o sistema como se ela já estivesse
	  # esperando a 20 minutos.
	  $atendimento = $c->stash->{local}->atendimentos_atuais->find
	    ({ 'estado.nome' => 'espera',
	       'configuracoes_atuais.id_local' => $c->stash->{local}->id_local,
	       %restringir  },
	     { 'join' =>
	       [{ 'estado_atual' => 'estado' },
		{ 'categoria_atual' => { 'categoria' => 'configuracoes_atuais' }}],
	       'order_by' => '((now() - estado_atual.vt_ini) * configuracoes_atuais.prioridade) DESC'});
	}

        if ($atendimento) {
            my $outros_guiches = $atendimento->guiches->search
              ({ 'me.vt_fim' => { '>', $now }});
            while (my $outro_guiche = $outros_guiches->next) {
                $outro_guiche->update
                  ({ vt_fim => $now });
            }

            my $outros_estados_guiche = $guiche->estados->search
              ({ 'me.vt_fim' => { '>', $now }});
            while (my $outro_estado = $outros_estados_guiche->next) {
                $outro_estado->update
                  ({ vt_fim => $now });
            }

            $guiche->estados->create
              ({ vt_ini => $now,
                 vt_fim => 'Infinity',
                 id_estado => $estado_chamando_guiche->id_estado });

            $atendimento->guiches->create
              ({ vt_ini => $now,
                 vt_fim => 'Infinity',
                 id_guiche => $guiche->id_guiche });

            my $estados = $atendimento->estados->search
              ({ 'me.vt_fim' => { '>', $now }});

            while (my $outro_estado = $estados->next) {
                $estados->update
                  ({ vt_fim => $now });
            }

            $atendimento->estados->create
              ({ vt_ini => $now,
                 vt_fim => 'Infinity',
                 id_estado => $estado_chamando->id_estado });

            $c->stash->{guiche} = $guiche;
            $c->stash->{refresh_guiche} ||= [];
            push @{$c->stash->{refresh_guiche}}, $guiche->id_guiche;
        }

    }

    # Vamos obter o vt_ini do estado 'chamando' da 3 senha atras...
    my $vtinis = $c->stash->{local}->atendimentos->search
      ({ 'estado.nome' => 'chamando' },
       {
        join => { estados => 'estado' },
        order_by => 'estados.vt_ini DESC',
        rows => 1,
        offset => 2,
        select => [ 'estados.vt_ini' ],
        as => [ 'vt_ini' ]})->first;
    if ($vtinis) {
        my $vt_ini = $vtinis->get_column('vt_ini');
        my $encerrar = $c->stash->{local}->atendimentos_atuais->search
          ({ 'estado.nome' => 'no_show',
             'estados.vt_ini' => { '<' => $vt_ini } },
           { join => { estados => 'estado' }});
        while (my $at = $encerrar->next) {
            $at->update({ 'vt_fim' => $now });
        }

    }

    $c->stash->{refresh_painel} = 1;
    $c->stash->{refresh_gerente} = 1;
}

sub dados_funcionario :WSDLPort('GestaoLocal') :DBICTransaction('DB') :MI {
      #dados_funcionario é utilizado para receber um jid de um funcionario e 
      #retornar o nome do funcionario.

    my ($self, $c, $query) = @_;

    my $jid = $query->{funcionario}{jid};

    my $funcionario = $c->model('DB::Funcionario')->find
      ({ jid => $jid });

    if (!$funcionario) {
        die $c->stash->{soap}->fault
          ({ code => 'Client',
             reason => 'Funcionario nao encontrado;',
             detail => 'Nao foi encontrado um funcionario com jid '.$jid });
    }

    $c->stash->{soap}->compile_return
      ({ funcionario => { nome => $funcionario->nome } });

}

sub encerrar_atendimento :WSDLPort('GestaoLocal') :DBICTransaction('DB') :MI {
    my ($self, $c, $query) = @_;

    my $now = $c->stash->{now};
    my $atendimento = $c->model('DB::Atendimento')->find
      ( $query->{atendimento} );

    if (!$atendimento) {
        die $c->stash->{soap}->fault
          ({ code => 'Client',
             reason => 'Atendimento nao encontrado;',
             detail => 'Nao foi encontrado o atendimento' });
    }

    my $guiche = $atendimento->guiche_atual->first->guiche;

    my $estado_atual = $atendimento->estado_atual->search
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
    $atendimento->estados->create
      ({ vt_ini => $now,
         vt_fim => 'Infinity',
         id_estado => $estado_at_encerrado->id_estado });
    $atendimento->update({ vt_fim => $now });

    $atendimento->guiche_atual->first->update({ vt_fim => $now });

    $guiche->estado_atual->first->update({ vt_fim => $now });
    $guiche->estados->create
      ({ vt_ini => $now,
         vt_fim => 'Infinity',
         id_estado => $estado_gu_concluido->id_estado });

    $c->model('SOAP')->transport->connection($c->engine->connection($c));

    $c->model('SOAP')->transport->addrs([$guiche->jid_opiniometro . '/callback/']);
    $c->model('SOAP::Opiniometro')
      ->encerrar_opiniometro({ refresh_request => '' });

    $c->stash->{refresh_gerente} = 1;
    $c->stash->{refresh_guiche} ||= [];
    push @{$c->stash->{refresh_guiche}}, $guiche->id_guiche;
}

sub devolver_senha :WSDLPort('GestaoLocal') :DBITransaction('DB') :MI {
    my ($self, $c, $query) = @_;
    my $now = $c->stash->{now};
    my $id_guiche = $query->{guiche}{id_guiche};

    #Checa se existe guiche
    unless ($id_guiche) {
        die $c->stash->{soap}->fault
          ({ code => 'Client',
             reason => 'Guiche sem id',
             detail => 'É preciso informar guichê usando id.' });
    }

    my $guiche = $c->model('DB::Guiche')->find({ id_guiche => $id_guiche });
    $c->stash->{guiche} = $guiche;
    $c->stash->{atendente} = $guiche->atendente_atual->first;
    $c->forward('/ws/gestao/atendente/devolver_senha');
}

sub fechar_guiche :WSDLPort('GestaoLocal') :DBICTransaction('DB') :MI {
      #esse fechar_guiche recebe um id_guiche como parametro para fechar, 
      #no caso, vou usa-lo quando o gerente fechar algum guiche e passar o id.
    my ($self, $c, $query) = @_;

    my $now = $c->stash->{now};
    my $id_guiche = $query->{guiche}{id_guiche};

    #Checa se existe guiche
    unless ($id_guiche) {
        die $c->stash->{soap}->fault
          ({ code => 'Client',
             reason => 'Guiche sem id',
             detail => 'É preciso informar guichê usando id.' });
    }

    my $guiche = $c->model('DB::Guiche')->find({ id_guiche => $id_guiche });
    $c->stash->{guiche} = $guiche;
    $c->stash->{atendente} = $guiche->atendente_atual->first;
    $c->forward('/ws/gestao/atendente/fechar_guiche');
}

sub fechar_todos :WSDLPort('GestaoLocal') :DBICTransaction('DB') :MI {
      # esse metodo fecha todos os guiches com estado = concluido ou disponivel
    my ($self, $c) = @_;

    my $now = $c->stash->{now};

    # Pega todos os guiches
    my $guiches = $c->model('DB::Guiche')->search
      ({ 'me.vt_ini' => { '<=', $now } ,
         'me.vt_fim' => { '>', $now } ,
         'estados.vt_ini' => { '<=', $now },
         'estados.vt_fim' => { '>', $now },
         'estado.nome' => [ 'concluido' , 'disponivel' ]},
       {
        prefetch => { 'estados' => 'estado' }});

    # Checa se existe guiche
    unless ($guiches) {
        die $c->stash->{soap}->fault
          ({ code => 'Client',
             reason => 'Sem guichês para fechar',
             detail => 'Nenhum guichê encontrado com estado concluido ou disponivel.' });
    }

    while (my $guiche = $guiches->next) {
        my $old = $c->stash->{guiche};
        my $olda = $c->stash->{atendente};
        $c->stash->{atendente} = $guiche->atendente_atual->first;
        $c->forward('/ws/gestao/atendente/fechar_guiche');
        $c->stash->{guiche} = $old;
        $c->stash->{atendente} = $olda;
    }
}

sub concluir_atendimento :WSDLPort('GestaoLocal') :DBICTransaction('DB') :MI {
    my ($self, $c, $query) = @_;

    my $now = $c->stash->{now};
    my $id_guiche = $query->{guiche}{id_guiche};

    #Checa se existe guiche
    unless ($id_guiche) {
        die $c->stash->{soap}->fault
          ({ code => 'Client',
             reason => 'Guiche sem id',
             detail => 'É preciso informar guichê usando id.' });
    }

    my $guiche = $c->model('DB::Guiche')->find({ id_guiche => $id_guiche });
    $c->stash->{guiche} = $guiche;
    $c->stash->{atendente} = $guiche->atendente_atual->first;
    $c->forward('/ws/gestao/atendente/concluir_atendimento');
}

sub pular_opiniometro :WSDLPort('GestaoLocal') :DBICTransaction('DB') :MI {
    my ($self, $c, $query) = @_;

    my $now = $c->stash->{now};
    my $id_guiche = $query->{guiche}{id_guiche};
    my $valor = $query->{guiche}{pular_opiniometro};

    #Checa se existe guiche
    unless ($id_guiche) {
        die $c->stash->{soap}->fault
          ({ code => 'Client',
             reason => 'Guiche sem id',
             detail => 'É preciso informar guichê usando id.' });
    }

    my $guiche = $c->model('DB::Guiche')->find({ id_guiche => $id_guiche });

    $guiche->update
      ({ pular_opiniometro => $valor });

    $c->stash->{refresh_gerente} = 1;
}

sub listar_encaminhamentos: WSDLPort('GestaoLocal') :DBICTransaction('DB'): MI {
    my ($self, $c, $query) = @_;

    my $estado_local_aberto = $c->model('DB::TipoEstadoLocal')->find
      ({ nome => 'aberto' });

    unless ($estado_local_aberto) {
        die $c->stash->{soap}->fault
          ({code => 'Server',
            reason => 'Nao pode encontrar estado "aberto"',
            detail => 'Existe um erro de configuracao no banco de dados'});
    }

    #pegar ultimo vt_ini do ultimo estadoaberto do local.
    my $ultimo_aberto  =
      $c->stash->{local}->estados->search
        ({ 'estado.nome' => $estado_local_aberto->nome },
         { join => 'estado',
           select => [ 'me.vt_ini' ],
           as => [ 'vt_ini' ],
           order_by => 'vt_ini DESC' })->first;

    my $ret = [];
    if ($ultimo_aberto) {
        my $vt_ini = $ultimo_aberto->get_column('vt_ini');

        my $enc =
          $c->model('DB::GuicheEncaminhamento')->search
            ({ 'me.vt_ini' => { '>=', $vt_ini } },
             { join => [ 'guiche' , 'guiche_origem' ],
               select => [
                          'me.vt_ini',
                          'guiche.identificador',
                          'guiche_origem.identificador',
                          'me.id_atendimento',
                          'me.informacoes',
                          'me.vt_fim'
                         ],
               as     => [
                          'vt_ini' ,
                          'id_guiche',
                          'id_guiche_origem',
                          'id_atendimento',
                          'informacoes',
                          'vt_fim'
                         ],
               order_by => [ 'me.vt_ini DESC' ]});

        while (my $encaminhamento = $enc->next) {
            push @$ret,
              {
               ( map { $_ => $encaminhamento->get_column($_) }
                 qw( id_guiche id_guiche_origem id_atendimento informacoes ) 
               ),
               ( map { ($encaminhamento->$_ && $encaminhamento->$_->is_infinite) ?
                         () : ($_ => DateTime::Format::XSD->format_datetime($encaminhamento->$_->set_time_zone('local'))) }
                 qw/ vt_ini vt_fim /
               ),
              }
          }
    }
    return $c->stash->{soap}->compile_return
      ({ lista_encaminhamentos => { encaminhamento => $ret } });
}

sub associar_gerente :WSDLPort('GestaoLocal') :DBICTransaction('DB') :MI {
    my ($self, $c, $query) = @_;

    # esse associar_gerente recebe um id_funcionario como parametro
    my $now = $c->stash->{now};
    my $id_funcionario = $query->{funcionario}{id_funcionario};
    my $guiche_associado = $c->model('DB::AtendenteGuiche')->find
      ({ id_funcionario => $id_funcionario ,
         vt_fim => 'Infinity'});

    # Checa se existe o funcionario e se ele está desassociado do guiche
    unless ($id_funcionario) {
        die $c->stash->{soap}->fault
          ({ code => 'Client',
             reason => 'Funcionario sem id',
             detail => 'É preciso informar funcionario usando id.' });
    }
    if ($guiche_associado) {
        die $c->stash->{soap}->fault
          ({ code => 'Server',
             reason => 'Atendente esta conectado a uma mesa',
             detail => 'Atendente nao pode ser gerente se estiver ligado a uma mesa.' });
    }
    $c->stash->{gerente}->update({ vt_fim => DateTime->now(time_zone => 'local') });

    $c->stash->{local}->gerentes->create
      ({ id_funcionario => $id_funcionario,
         vt_ini => DateTime->now(time_zone => 'local'),
         vt_fim => 'Infinity' });

    return $c->stash->{soap}->compile_return
      ({ funcionario => { id_funcionario => $id_funcionario } });
}

sub listar_funcionarios :WSDLPort('GestaoLocal') :DBICTransaction('DB') :MI {
    my ($self, $c, $query) = @_;

    my $now = $c->stash->{now};

    # guarda na variável $funcionarios todos os funcionários do local
    my $funcionarios = $c->stash->{local}->funcionarios->search
      ({ 'me.vt_ini' => { '<=', $now },
         'me.vt_fim' => { '>=', $now } },
       {
        'order_by' => 'me.id_funcionario' }); 

    my $lista_funcionarios = [];
    while (my $funcionario = $funcionarios->next) {

        # verifica se o funcionário está associado a algum guichê...
        my $guiche_associado = $c->model('DB::AtendenteGuiche')->find
          ({ id_funcionario => $funcionario->id_funcionario,
             vt_fim => 'Infinity'});

        # ...se não tiver, guarda-o na listar_funcionarios. Além
        # disso, também não guarda na lista o funcionário que é
        # gerente, para que ele não se desconecte à toa.
        unless (($guiche_associado) || ($funcionario->id_funcionario == $c->stash->{gerente}->get_column('id_funcionario'))) {
            push @$lista_funcionarios,
              {
               ( map { $_ => $funcionario->funcionario->$_() }  
                 qw/ nome id_funcionario / )};
        }
    }

    $c->stash->{soap}->compile_return
      ({ lista_funcionarios => { funcionario => $lista_funcionarios } });    

}

1;


__END__

=head1 NAME

Local - Implementa a lógica do gerente

=head1 DESCRIPTION

Esse módulo implementa as funções disponíveis para o gerente.

=cut


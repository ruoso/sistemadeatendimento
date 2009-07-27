package Fila::ETL::Controller::Opiniao;
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
use base qw(Catalyst::Controller);

sub opiniao :Chained('/base') :PathPart :CaptureArgs(0) {
  my ($self, $c) = @_;
  $c->stash->{vt_base} = $c->stash->{now};
}

sub avaliacao :Chained('opiniao') :PathPart :Args(0) {
  my ($self, $c) = @_;

  $c->model('Federado')->doeach
    ($c, sub {
       my $id = shift;
       my $min = 'minute';

       my $result = $c->model('DB::ActivityLog')->search
         ({ activity_type => '/opiniao/avaliacao',
            id_local => $id },
          { order_by => 'vt_base DESC' });

       if (my $last = $result->first) {
         $c->stash->{last_vt_base} = $last->vt_base;
       } else {
         $c->stash->{last_vt_base} = '-Infinity';
       }

       my $local = $c->model('Federado')->target($c, $id, 'Local')->find
	 ({ id_local => $id });

       my $sql = q#

SELECT DATE_TRUNC('minute', resposta_avaliacao.vt_fac) AS datahora, COUNT(*) AS
 quantidade, resposta, categoria.nome, categoria.codigo,
 categoria.id_categoria, pergunta_avaliacao.pergunta, funcionario.nome
 AS nome_func, funcionario.jid, guiche.identificador

FROM
 resposta_avaliacao INNER JOIN
 pergunta_avaliacao USING (id_pergunta) INNER JOIN
 atendimento
  ON (resposta_avaliacao.id_atendimento=atendimento.id_atendimento AND
      atendimento.id_local=?) LEFT JOIN
 categoria_atendimento
  ON (atendimento.id_atendimento=categoria_atendimento.id_atendimento AND
      categoria_atendimento.vt_ini <= resposta_avaliacao.vt_fac AND
      categoria_atendimento.vt_fim >= resposta_avaliacao.vt_fac) LEFT JOIN
 categoria USING (id_categoria) LEFT JOIN
 guiche_atendimento
  ON (atendimento.id_atendimento=guiche_atendimento.id_atendimento AND
      guiche_atendimento.vt_ini <= resposta_avaliacao.vt_fac AND
      guiche_atendimento.vt_fim >= resposta_avaliacao.vt_fac) LEFT JOIN
 guiche USING (id_guiche) LEFT JOIN
 atendente_guiche
  ON (atendente_guiche.id_guiche=guiche.id_guiche AND
      atendente_guiche.vt_ini <= resposta_avaliacao.vt_fac AND
      atendente_guiche.vt_fim >= resposta_avaliacao.vt_fac) LEFT JOIN
 funcionario USING (id_funcionario)

WHERE
 resposta_avaliacao.vt_fac > ? AND
 resposta_avaliacao.vt_fac <= ?

GROUP BY DATE_TRUNC('minute', resposta_avaliacao.vt_fac), resposta,
 categoria.nome, categoria.codigo, categoria.id_categoria, pergunta,
 funcionario.nome, funcionario.jid, guiche.identificador

#;

       my $storage = $c->model('Federado')->storage($c, $id);
       $storage->ensure_connected;
       my $dbi = $storage->dbh;

       my $sth = $dbi->prepare($sql);
       $sth->execute( $id,
                      $c->stash->{last_vt_base}, $c->stash->{vt_base},
                    );

       my $dlocal = $c->model('DB::DLocal')->get_dimension($local);
       my $func_cache = {};
       my $cate_cache = {};
       my $guic_cache = {};
       my $perg_cache = {};
       my $resp_cache = {};

       while (my $item = $sth->fetchrow_hashref) {
         my $datahora = $item->{datahora};
         my $datahora_dt = DateTime::Format::Pg->parse_datetime($datahora);
         my $data = $c->model('DB::DData')->get_dimension($datahora_dt);
         my $horario = $c->model('DB::DHorario')->get_dimension($datahora_dt);

         unless (exists $func_cache->{$item->{jid}}) {
           $func_cache->{$item->{jid}} = $c->model('DB::DAtendente')
             ->get_dimension({ nome => $item->{nome_func}, jid => $item->{jid}});
         }
         my $func = $func_cache->{$item->{jid}};

         unless (exists $cate_cache->{$item->{id_categoria}}) {
           $cate_cache->{$item->{id_categoria}} =
             $c->model('DB::DCategoria')->get_dimension($item);
         }
         my $cate = $cate_cache->{$item->{id_categoria}};

         unless (exists $guic_cache->{$item->{identificador}}) {
           $guic_cache->{$item->{identificador}} =
             $c->model('DB::DGuiche')->get_dimension($item->{identificador});
         }
         my $guic = $guic_cache->{$item->{identificador}};

         unless (exists $perg_cache->{$item->{pergunta}}) {
           $perg_cache->{$item->{pergunta}} =
             $c->model('DB::DPerguntaAvaliacao')->get_dimension($item->{pergunta});
         }
         my $perg = $perg_cache->{$item->{pergunta}};

         unless (exists $resp_cache->{$item->{resposta}}) {
           $resp_cache->{$item->{resposta}} =
             $c->model('DB::DRespostaAvaliacao')->get_dimension($item->{resposta});
         }
         my $resp = $resp_cache->{$item->{resposta}};

         $c->model('DB::FAvaliacao')->create
           ({ id_local => $dlocal,
              data => $data,
              horario => $horario,
              id_guiche => $guic,
              id_categoria => $cate,
              id_atendente => $func,
              id_pergunta => $perg,
              id_resposta => $resp,
              quantidade => $item->{quantidade}
            });
       }


       $c->model('DB::ActivityLog')->create
         ({ activity_type => '/opiniao/avaliacao',
            vt_base => $c->stash->{vt_base},
            vt_ini => $c->stash->{now},
            id_local => $id });

     });


}

1;

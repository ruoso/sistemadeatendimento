package Fila::ETL::Controller::Guiches;
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
use List::Util qw(sum);
use base qw(Catalyst::Controller);

sub guiches :Chained('/base') :PathPart :CaptureArgs(0) {
  my ($self, $c) = @_;
  $c->stash->{vt_base} = $c->stash->{now};
}

sub estados :Chained('guiches') :PathPart :Args(0) {
  my ($self, $c) = @_;

  $c->model('Federado')->doeach
    ($c, sub {
       my $id = shift;

       my $result = $c->model('DB::ActivityLog')->search
         ({ activity_type => '/guiches/estados',
            id_local => $id },
          { order_by => 'vt_base DESC' });

       if (my $last = $result->first) {
         $c->stash->{last_vt_base} = $last->vt_base;
       } else {
         $c->stash->{last_vt_base} = '-Infinity';
       }

       my $local = $c->model('Federado')->target($c, $id, 'Local')->find
	 ({ id_local => $id });

       my $sql_times = q{
SELECT
 DISTINCT DATE_TRUNC('minute', estado_guiche.vt_ini) + '59.9999999 seconds' AS vt_fac
FROM
 guiche LEFT JOIN 
 estado_guiche USING (id_guiche)
WHERE
 guiche.id_local = ? AND
 guiche.vt_ini >= ? AND
 guiche.vt_ini < ? AND
 estado_guiche.vt_ini >= ? AND
 estado_guiche.vt_ini < ?
};

         my $sql_estados = q{
SELECT
 COUNT(tipo_estado_guiche.*) as quantidade,
 tipo_estado_guiche.nome as nome_estado

FROM
 guiche LEFT JOIN
 estado_guiche
   ON (guiche.id_guiche=estado_guiche.id_guiche AND
       estado_guiche.vt_ini <= ? AND
       estado_guiche.vt_fim > ?) LEFT JOIN
 tipo_estado_guiche USING (id_estado)

WHERE tipo_estado_guiche.nome IS NOT NULL
 AND guiche.id_local=?

GROUP BY
  tipo_estado_guiche.nome


};

       my $storage = $c->model('Federado')->storage($c, $id);
       $storage->ensure_connected;
       my $dbi = $storage->dbh;

       my $sth = $dbi->prepare($sql_times);
       $sth->execute( $id,
                      $c->stash->{last_vt_base}, $c->stash->{vt_base},
                      $c->stash->{last_vt_base}, $c->stash->{vt_base},
                    );

       my $sth_inner = $dbi->prepare($sql_estados);

       my $dlocal = $c->model('DB::DLocal')->get_dimension($local);
       my $func_cache = {};
       my $guic_cache = {};

       while (my ($datahora) = $sth->fetchrow_array) {
         my $datahora_dt = DateTime::Format::Pg->parse_datetime($datahora);
         my $data = $c->model('DB::DData')->get_dimension($datahora_dt);
         my $horario = $c->model('DB::DHorario')->get_dimension($datahora_dt);
         my $counters = {};

         $sth_inner->execute($datahora,$datahora,$id);
         while (my $item = $sth_inner->fetchrow_hashref) {
           $counters->{$item->{nome_estado}} = $item->{quantidade};
         }

         $c->model('DB::FEstadosGuiches')->create
           ({ id_local => $dlocal,
              data => $data,
              horario => $horario,
              quantidade_publico =>
              sum( map { $counters->{$_} || 0 }
                   'disponivel',
                   'chamando',
                   'atendimento',
                   'avaliacao',
                   'concluido'
                 ),
              ( map { 'quantidade_'.$_ => ($counters->{$_} || 0) }
                'fechado',
                'pausa',
                'interno',
                'disponivel',
                'chamando',
                'atendimento',
                'avaliacao',
                'concluido'
              )
            });
       }

       $c->model('DB::ActivityLog')->create
         ({ activity_type => '/guiches/estados',
            id_local => $id,
            vt_base => $c->stash->{vt_base},
            vt_ini => $c->stash->{now} });

     });

}
1;

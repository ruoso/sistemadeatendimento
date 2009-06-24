package Fila::ETL::Controller::Atendimento;
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

sub atendimento :Chained('/base') :PathPart :CaptureArgs(0) {
  my ($self, $c) = @_;
  $c->stash->{vt_base} = $c->stash->{now};
}

sub quantidade :Chained('atendimento') :PathPart :Args(0) {
  my ($self, $c) = @_;

  $c->model('Federado')->doeach
    ($c, sub {
       my $id = shift;
       my $min = 'minute';

       my $result = $c->model('DB::ActivityLog')->search
         ({ activity_type => '/atendimento/quantidade',
            id_local => $id },
          { order_by => 'vt_base DESC' });

       if (my $last = $result->first) {
         $c->stash->{last_vt_base} = $last->vt_base;
       } else {
         $c->stash->{last_vt_base} = '-Infinity';
       }

       my $local = $c->model('Federado')->target($c, $id, 'Local')->find
	 ({ id_local => $id });

       my $consulta = $local->atendimentos->search
	 ({ -and => [ { 'me.vt_ini' => { '>' => $c->stash->{last_vt_base} } },
		      { 'me.vt_ini' => { '<=' => $c->stash->{vt_base} } },
		      { 'atendentes.vt_ini' => \" <= me.vt_ini" },
		      { 'atendentes.vt_fim' => \" > me.vt_ini"  },
		      { 'estado.nome' => 'espera' },
		      { 'estados.vt_fim' => \"< now()" },
		      { 'estado_2.nome' => 'chamando' },
		      { 'estados_2.vt_fim' => \"< now()" },
		      { 'estado_3.nome' => 'atendimento' },
		      { 'estados_3.vt_fim' => \"< now()" },
                      { 'categorias.vt_ini' => \" <= estados_3.vt_ini" },
                      { 'categorias.vt_fim' => \" >= estados_3.vt_fim" },
                      { 'guiches.vt_ini' => \" <= estados_3.vt_ini" },
                      { 'guiches.vt_fim' => \" >= estados_3.vt_fim" },
                      { 'atendentes.vt_ini' => \" <= estados_3.vt_ini" },
                      { 'atendentes.vt_fim' => \" >= estados_3.vt_fim" },
		      \"((estados.vt_fim - estados.vt_ini) < '5 hours')",
		      \"((estados_2.vt_fim - estados.vt_ini) < '5 hours')",
		      \"((estados_3.vt_fim - estados.vt_ini) < '5 hours')",
		    ] },

	  { join => [
		     { 'guiches' => { 'guiche' => { 'atendentes' => 'funcionario' }}},
		     { 'categorias' => 'categoria' },
		     { 'estados' => 'estado' },
		     { 'estados' => 'estado' },
		     { 'estados' => 'estado' }
		    ],

	    select => [ \'count(distinct me.id_atendimento)',
			\'date_trunc(\'minute\', me.vt_ini)',

			\'min(EXTRACT(\'epoch\' FROM (CASE WHEN estados.vt_fim > NOW() THEN NOW() ELSE estados.vt_fim END) - estados.vt_ini))',
			\'max(EXTRACT(\'epoch\' FROM (CASE WHEN estados.vt_fim > NOW() THEN NOW() ELSE estados.vt_fim END) - estados.vt_ini))',
			\'sum(EXTRACT(\'epoch\' FROM (CASE WHEN estados.vt_fim > NOW() THEN NOW() ELSE estados.vt_fim END) - estados.vt_ini))',

			\'min(EXTRACT(\'epoch\' FROM (CASE WHEN estados_2.vt_fim > NOW() THEN NOW() ELSE estados_2.vt_fim END) - estados_2.vt_ini))',
			\'max(EXTRACT(\'epoch\' FROM (CASE WHEN estados_2.vt_fim > NOW() THEN NOW() ELSE estados_2.vt_fim END) - estados_2.vt_ini))',
			\'sum(EXTRACT(\'epoch\' FROM (CASE WHEN estados_2.vt_fim > NOW() THEN NOW() ELSE estados_2.vt_fim END) - estados_2.vt_ini))',

			\'min(EXTRACT(\'epoch\' FROM (CASE WHEN estados_3.vt_fim > NOW() THEN NOW() ELSE estados_3.vt_fim END) - estados_3.vt_ini))',
			\'max(EXTRACT(\'epoch\' FROM (CASE WHEN estados_3.vt_fim > NOW() THEN NOW() ELSE estados_3.vt_fim END) - estados_3.vt_ini))',
			\'sum(EXTRACT(\'epoch\' FROM (CASE WHEN estados_3.vt_fim > NOW() THEN NOW() ELSE estados_3.vt_fim END) - estados_3.vt_ini))',

			'guiches.id_guiche', 'guiche.id_guiche',
			'guiche.id_local', 'guiche.vt_ini',
			'guiche.vt_fim', 'guiche.identificador',
			'guiche.jid_opiniometro',
			'guiche.pular_opiniometro',
			'atendentes.id_funcionario',
			'atendentes.id_guiche',
			'atendentes.vt_ini', 'atendentes.vt_fim',
			'funcionario.id_funcionario',
			'funcionario.nome', 'funcionario.jid',
			'funcionario.password',
			'categorias.id_categoria',
			'categoria.id_categoria', 'categoria.nome',
			'categoria.codigo'
		      ],

	    as => [ 'quantidade',
		    'datahora',

		    'min_tempo_espera',
		    'max_tempo_espera',
		    'sum_tempo_espera',

		    'min_tempo_deslocamento',
		    'max_tempo_deslocamento',
		    'sum_tempo_deslocamento',

		    'min_tempo_atendimento',
		    'max_tempo_atendimento',
		    'sum_tempo_atendimento',

		    'guiches_id_guiche',
		    'guiche_id_guiche',
		    'guiche_id_local',
		    'guiche_vt_ini',
		    'guiche_vt_fim',
		    'guiche_identificador',
		    'guiche_jid_opiniometro',
		    'guiche_pular_opiniometro',
		    'atendentes_id_funcionario',
		    'atendentes_id_guiche',
		    'atendentes_vt_ini',
		    'atendentes_vt_fim',
		    'funcionario_id_funcionario',
		    'funcionario_nome',
		    'funcionario_jid',
		    'funcionario_password',
		    'categorias_id_categoria',
		    'categoria_id_categoria',
		    'categoria_nome',
		    'categoria_codigo'
		  ],

	    group_by => [ 'guiches.id_guiche', 'guiche.id_guiche',
			  'guiche.id_local', 'guiche.vt_ini',
			  'guiche.vt_fim', 'guiche.identificador',
			  'guiche.jid_opiniometro',
			  'guiche.pular_opiniometro',
			  'atendentes.id_funcionario',
			  'atendentes.id_guiche',
			  'atendentes.vt_ini', 'atendentes.vt_fim',
			  'funcionario.id_funcionario',
			  'funcionario.nome', 'funcionario.jid',
			  'funcionario.password',
			  'categorias.id_categoria',
			  'categoria.id_categoria',
			  'categoria.nome', 'categoria.codigo',
			  'date_trunc(\'minute\', me.vt_ini)' ]});

       while (my $item = $consulta->next()) {

	 my $dlocal = $c->model('DB::DLocal')->get_dimension($local);

	 my $categoria = $c->model('DB::DCategoria')->get_dimension
	   (Fila::Servico::DB::Categoria->new
	    ({ map { my $col = $_;
		     $col =~ s/^[^_]+_//;
		     $col => $item->get_column($_)
		   } qw(categoria_id_categoria categoria_nome categoria_codigo) }));

	 my $guiche = $c->model('DB::DGuiche')->get_dimension
	   ( Fila::Servico::DB::Guiche->new
	     ({ map { my $col = $_;
		      $col =~ s/^[^_]+_//;
		      $col => $item->get_column($_)
		    } qw(guiche_id_guiche guiche_identificador) }));

	 my $atendente = $c->model('DB::DAtendente')->get_dimension
	   ( Fila::Servico::DB::Funcionario->new
	     ({ map { my $col = $_;
		      $col =~ s/^[^_]+_//;
		      $col => $item->get_column($_)
		    } qw(funcionario_id_funcionario funcionario_jid funcionario_nome) }));

	 $c->model('DB::FQuantidadeAtendimentos')->create
	   ({ id_local => $dlocal,
	      id_categoria => $categoria,
	      id_guiche => $guiche,
	      id_atendente => $atendente,

	      data => $c->model('DB::DData')->get_dimension
	      ( DateTime::Format::Pg->parse_datetime($item->get_column('datahora') ) ),

	      horario => $c->model('DB::DHorario')->get_dimension
	      ( DateTime::Format::Pg->parse_datetime($item->get_column('datahora') ) ),

	      ( map { $_ => int(0 + $item->get_column($_)) }
		'quantidade',
		'min_tempo_espera',
		'max_tempo_espera',
		'sum_tempo_espera',
		'min_tempo_deslocamento',
		'max_tempo_deslocamento',
		'sum_tempo_deslocamento',
		'min_tempo_atendimento',
		'max_tempo_atendimento',
		'sum_tempo_atendimento',
	      )
	    });
       }

       $c->model('DB::ActivityLog')->create
         ({ activity_type => '/atendimento/quantidade',
            vt_base => $c->stash->{vt_base},
            vt_ini => $c->stash->{now},
            id_local => $id });

     });


}

sub estados :Chained('atendimento') :PathPart :Args(0) {
  my ($self, $c) = @_;

  $c->model('Federado')->doeach
    ($c, sub {
       my $id = shift;

       my $result = $c->model('DB::ActivityLog')->search
         ({ activity_type => '/atendimento/estados',
            id_local => $id },
          { order_by => 'vt_base DESC' });

       if (my $last = $result->first) {
         $c->stash->{last_vt_base} = $last->vt_base;
       } else {
         $c->stash->{last_vt_base} = '-Infinity';
       }

       my $local = $c->model('Federado')->target($c, $id, 'Local')->find
	 ({ id_local => $id });

       my $sql = q#;
SELECT

 date_trunc('minute',times.vt_fac) AS datahora,
 COUNT(es_espe_ini.*) AS espe_ini,
 COUNT(es_espe_fim.*) AS espe_fim,
 COUNT(es_cham_ini.*) AS cham_ini,
 COUNT(es_cham_fim.*) AS cham_fim,
 COUNT(es_aten_ini.*) AS aten_ini,
 COUNT(es_aten_fim.*) AS aten_fim,
 COUNT(es_no_show.*) AS no_show,
 ct_espe_ini.id_categoria AS  ct_espe_ini_id_categoria,
 ct_espe_ini.nome AS  ct_espe_ini_nome,
 ct_espe_ini.codigo AS  ct_espe_ini_codigo,
 ct_espe_fim.id_categoria AS  ct_espe_fim_id_categoria,
 ct_espe_fim.nome AS  ct_espe_fim_nome,
 ct_espe_fim.codigo AS  ct_espe_fim_codigo,
 ct_cham_ini.id_categoria AS  ct_cham_ini_id_categoria,
 ct_cham_ini.nome AS  ct_cham_ini_nome,
 ct_cham_ini.codigo AS  ct_cham_ini_codigo,
 ct_cham_fim.id_categoria AS  ct_cham_fim_id_categoria,
 ct_cham_fim.nome AS  ct_cham_fim_nome,
 ct_cham_fim.codigo AS  ct_cham_fim_codigo,
 ct_aten_ini.id_categoria AS  ct_aten_ini_id_categoria,
 ct_aten_ini.nome AS  ct_aten_ini_nome,
 ct_aten_ini.codigo AS  ct_aten_ini_codigo,
 ct_aten_fim.id_categoria AS  ct_aten_fim_id_categoria,
 ct_aten_fim.nome AS  ct_aten_fim_nome,
 ct_aten_fim.codigo AS  ct_aten_fim_codigo,
 ct_no_show.id_categoria AS  ct_no_show_id_categoria,
 ct_no_show.nome AS  ct_no_show_nome,
 ct_no_show.codigo AS ct_no_show_codigo

FROM

 ( SELECT vt_ini AS vt_fac FROM estado_atendimento estados_ini
   WHERE (
     ( estados_ini.vt_ini >= ? ) AND
     ( estados_ini.vt_ini < ? ) )
   UNION
   SELECT vt_fim AS vt_fac FROM estado_atendimento estados_fim
   WHERE (
     ( estados_fim.vt_fim >= ? ) AND
     ( estados_fim.vt_fim < ? ) )
 ) AS times

 LEFT JOIN estado_atendimento AS es_espe_ini ON (times.vt_fac = es_espe_ini.vt_ini
       AND es_espe_ini.id_estado=(SELECT id_estado FROM tipo_estado_atendimento WHERE nome='espera'))

 LEFT JOIN atendimento AS at_espe_ini ON
      ( es_espe_ini.id_atendimento = at_espe_ini.id_atendimento AND
        at_espe_ini.id_local = ? )

 LEFT JOIN categoria_atendimento AS cs_espe_ini ON
      ( at_espe_ini.id_atendimento = cs_espe_ini.id_atendimento)

 LEFT JOIN categoria AS ct_espe_ini ON
      ( cs_espe_ini.id_categoria = ct_espe_ini.id_categoria)

 LEFT JOIN estado_atendimento AS es_espe_fim ON (times.vt_fac = es_espe_fim.vt_fim
       AND es_espe_fim.id_estado=(SELECT id_estado FROM tipo_estado_atendimento WHERE nome='espera'))

 LEFT JOIN atendimento AS at_espe_fim ON
      ( es_espe_fim.id_atendimento = at_espe_fim.id_atendimento AND
        at_espe_fim.id_local = ? )

 LEFT JOIN categoria_atendimento AS cs_espe_fim ON
      ( at_espe_fim.id_atendimento = cs_espe_fim.id_atendimento)

 LEFT JOIN categoria AS ct_espe_fim ON
      ( cs_espe_fim.id_categoria = ct_espe_fim.id_categoria)

 LEFT JOIN estado_atendimento AS es_cham_ini ON (times.vt_fac = es_cham_ini.vt_ini
       AND es_cham_ini.id_estado=(SELECT id_estado FROM tipo_estado_atendimento WHERE nome='chamando'))

 LEFT JOIN atendimento AS at_cham_ini ON
      ( es_cham_ini.id_atendimento = at_cham_ini.id_atendimento AND
        at_cham_ini.id_local = ? )

 LEFT JOIN categoria_atendimento AS cs_cham_ini ON
      ( at_cham_ini.id_atendimento = cs_cham_ini.id_atendimento)

 LEFT JOIN categoria AS ct_cham_ini ON
      ( cs_cham_ini.id_categoria = ct_cham_ini.id_categoria)

 LEFT JOIN estado_atendimento AS es_cham_fim ON (times.vt_fac = es_cham_fim.vt_fim
       AND es_cham_fim.id_estado=(SELECT id_estado FROM tipo_estado_atendimento WHERE nome='chamando'))

 LEFT JOIN atendimento AS at_cham_fim ON
      ( es_cham_fim.id_atendimento = at_cham_fim.id_atendimento AND
        at_cham_fim.id_local = ? )

 LEFT JOIN categoria_atendimento AS cs_cham_fim ON
      ( at_cham_fim.id_atendimento = cs_cham_fim.id_atendimento)

 LEFT JOIN categoria AS ct_cham_fim ON
      ( cs_cham_fim.id_categoria = ct_cham_fim.id_categoria)

 LEFT JOIN estado_atendimento AS es_aten_ini ON (times.vt_fac = es_aten_ini.vt_ini
       AND es_aten_ini.id_estado=(SELECT id_estado FROM tipo_estado_atendimento WHERE nome='atendimento'))

 LEFT JOIN atendimento AS at_aten_ini ON
      ( es_aten_ini.id_atendimento = at_aten_ini.id_atendimento AND
        at_aten_ini.id_local = ? )

 LEFT JOIN categoria_atendimento AS cs_aten_ini ON
      ( at_aten_ini.id_atendimento = cs_aten_ini.id_atendimento)

 LEFT JOIN categoria AS ct_aten_ini ON
      ( cs_aten_ini.id_categoria = ct_aten_ini.id_categoria)

 LEFT JOIN estado_atendimento AS es_aten_fim ON (times.vt_fac = es_aten_fim.vt_fim
       AND es_aten_fim.id_estado=(SELECT id_estado FROM tipo_estado_atendimento WHERE nome='atendimento'))

 LEFT JOIN atendimento AS at_aten_fim ON
      ( es_aten_fim.id_atendimento = at_aten_fim.id_atendimento AND
        at_aten_fim.id_local = ? )

 LEFT JOIN categoria_atendimento AS cs_aten_fim ON
      ( at_aten_fim.id_atendimento = cs_aten_fim.id_atendimento)

 LEFT JOIN categoria AS ct_aten_fim ON
      ( cs_aten_fim.id_categoria = ct_aten_fim.id_categoria)

 LEFT JOIN estado_atendimento AS es_no_show  ON (times.vt_fac = es_no_show.vt_ini
       AND es_no_show.id_estado=(SELECT id_estado FROM tipo_estado_atendimento WHERE nome='no_show'))

 LEFT JOIN atendimento AS at_no_show ON
      ( es_no_show.id_atendimento = at_no_show.id_atendimento AND
        at_no_show.id_local = ? )

 LEFT JOIN categoria_atendimento AS cs_no_show ON
      ( at_no_show.id_atendimento = cs_no_show.id_atendimento)

 LEFT JOIN categoria AS ct_no_show ON
      ( cs_no_show.id_categoria = ct_no_show.id_categoria)

GROUP BY date_trunc('minute',times.vt_fac),
  ct_espe_ini.id_categoria, ct_espe_ini.nome, ct_espe_ini.codigo,
  ct_espe_fim.id_categoria, ct_espe_fim.nome, ct_espe_fim.codigo,
  ct_cham_ini.id_categoria, ct_cham_ini.nome, ct_cham_ini.codigo,
  ct_cham_fim.id_categoria, ct_cham_fim.nome, ct_cham_fim.codigo,
  ct_aten_ini.id_categoria, ct_aten_ini.nome, ct_aten_ini.codigo,
  ct_aten_fim.id_categoria, ct_aten_fim.nome, ct_aten_fim.codigo,
  ct_no_show.id_categoria, ct_no_show.nome, ct_no_show.codigo

ORDER BY datahora

#;

       my $storage = $c->model('Federado')->storage($c, $id);
       $storage->ensure_connected;
       my $dbi = $storage->dbh;

       my $sth = $dbi->prepare($sql);
       $sth->execute( $c->stash->{last_vt_base}, $c->stash->{vt_base},
		      $c->stash->{last_vt_base}, $c->stash->{vt_base},
		      map { $id } 1..7 );

       my $dlocal = $c->model('DB::DLocal')->get_dimension($local);
       my $last_datahora;
       my $counters_cat = {};
       my $last_data;

       while (my $item = $sth->fetchrow_hashref) {

	 if ($last_datahora && $item->{datahora} ne $last_datahora) {

	   # inserir registros para cada categoria
	   my $data = $c->model('DB::DData')->get_dimension
	     ( DateTime::Format::Pg->parse_datetime($last_datahora) );
	   my $horario = $c->model('DB::DHorario')->get_dimension
	     ( DateTime::Format::Pg->parse_datetime($last_datahora) );

	   foreach my $id_categoria (keys %{$counters_cat}) {

	     my $categoria = $c->model('DB::DCategoria')->get_dimension
	       (Fila::Servico::DB::Categoria->new
		({ map { $_ => $counters_cat->{$id_categoria}{categoria}{$_}
		       } qw(id_categoria nome codigo) }));


	     $c->model('DB::FQuantidadeEstados')->create
	       ({ id_local => $dlocal,
		  id_categoria => $categoria,
		  data => $data,
		  horario => $horario,

		  ( map { 'quantidade_'.$_ => ($counters_cat->{$id_categoria}{$_} || 0) }
		    'espera',
		    'chamando',
		    'atendimento',
		    'no_show'
		  )
		});

	     $counters_cat->{$id_categoria}{no_show} = 0;
	   }

	   $last_datahora = $item->{datahora};
	   if ($last_data ne $data) {
	     $last_datahora = undef;
	     $last_data = undef;
	   }

	 }
	 if (not $last_datahora ) {
	   # vamos obter os contadores iniciais para aquela datahora

	   my $sql_quant = q#

SELECT
  cat_est.estado,
  cat_est.id_categoria,
  cat_est.codigo,
  cat_est.nome,
  COUNT(categoria_atendimento.*) as total
FROM
  ( SELECT tipo_estado_atendimento.id_estado,
    tipo_estado_atendimento.nome AS estado, categoria.id_categoria,
    categoria.codigo, categoria.nome FROM tipo_estado_atendimento,
    categoria
     WHERE
    tipo_estado_atendimento.nome IN ('espera','chamando','atendimento')
  ) AS cat_est
  INNER JOIN estado_atendimento
   ON (estado_atendimento.id_estado = cat_est.id_estado AND
       ? BETWEEN estado_atendimento.vt_ini AND estado_atendimento.vt_fim)
  INNER JOIN atendimento
   ON (estado_atendimento.id_atendimento = atendimento.id_atendimento AND
       ? BETWEEN atendimento.vt_ini AND atendimento.vt_fim)
  INNER JOIN categoria_atendimento
   ON (atendimento.id_atendimento = categoria_atendimento.id_atendimento AND
       categoria_atendimento.id_categoria = cat_est.id_categoria)
GROUP BY
  cat_est.estado,
  cat_est.id_categoria,
  cat_est.codigo,
  cat_est.nome

#;

	   my $sth = $dbi->prepare($sql_quant);
	   $sth->execute($item->{datahora}, $item->{datahora});

           $counters_cat = {};

	   while (my $cat_est = $sth->fetchrow_hashref) {
	     $counters_cat->{$cat_est->{id_categoria}}{categoria} = $cat_est;
	     $counters_cat->{$cat_est->{id_categoria}}{$cat_est->{estado}} = $cat_est->{total};
	     $counters_cat->{$cat_est->{id_categoria}}{no_show} = 0;
	   }

	   $last_datahora = $item->{datahora};
	   $last_data = $last_datahora;
	   $last_data =~ s/\s.+$//;
	 }

	 # vamos calcular os contadores
	 if ($item->{espe_ini}) {
	   $counters_cat->{$item->{ct_espe_ini_id_categoria}}{espera} += $item->{espe_ini};
	   $counters_cat->{$item->{ct_espe_ini_id_categoria}}{categoria}{codigo} = $item->{ct_espe_ini_codigo};
	   $counters_cat->{$item->{ct_espe_ini_id_categoria}}{categoria}{nome} = $item->{ct_espe_ini_nome};
	 }
	 if ($item->{espe_fim}) {
	   $counters_cat->{$item->{ct_espe_fim_id_categoria}}{espera} -= $item->{espe_fim};
	   $counters_cat->{$item->{ct_espe_fim_id_categoria}}{categoria}{codigo} = $item->{ct_espe_fim_codigo};
	   $counters_cat->{$item->{ct_espe_fim_id_categoria}}{categoria}{nome} = $item->{ct_espe_fim_nome};
	 }
	 if ($item->{cham_ini}) {
	   $counters_cat->{$item->{ct_cham_ini_id_categoria}}{chamando} += $item->{cham_ini};
	   $counters_cat->{$item->{ct_cham_ini_id_categoria}}{categoria}{codigo} = $item->{ct_cham_ini_codigo};
	   $counters_cat->{$item->{ct_cham_ini_id_categoria}}{categoria}{nome} = $item->{ct_cham_ini_nome};
	 }
	 if ($item->{cham_fim}) {
	   $counters_cat->{$item->{ct_cham_fim_id_categoria}}{chamando} -= $item->{cham_fim};
	   $counters_cat->{$item->{ct_cham_fim_id_categoria}}{categoria}{codigo} = $item->{ct_cham_fim_codigo};
	   $counters_cat->{$item->{ct_cham_fim_id_categoria}}{categoria}{nome} = $item->{ct_cham_fim_nome};
	 }
	 if ($item->{aten_ini}) {
	   $counters_cat->{$item->{ct_aten_ini_id_categoria}}{atendimento} += $item->{aten_ini};
	   $counters_cat->{$item->{ct_aten_ini_id_categoria}}{categoria}{codigo} = $item->{ct_aten_ini_codigo};
	   $counters_cat->{$item->{ct_aten_ini_id_categoria}}{categoria}{nome} = $item->{ct_aten_ini_nome};
	 }
	 if ($item->{aten_fim}) {
	   $counters_cat->{$item->{ct_aten_fim_id_categoria}}{atendimento} -= $item->{aten_fim};
	   $counters_cat->{$item->{ct_aten_fim_id_categoria}}{categoria}{codigo} = $item->{ct_aten_fim_codigo};
	   $counters_cat->{$item->{ct_aten_fim_id_categoria}}{categoria}{nome} = $item->{ct_aten_fim_nome};
	 }
	 if ($item->{no_show}) {
	   $counters_cat->{$item->{ct_no_show_id_categoria}}{no_show} += $item->{no_show};
	   $counters_cat->{$item->{ct_no_show_id_categoria}}{categoria}{codigo} = $item->{ct_no_show_codigo};
	   $counters_cat->{$item->{ct_no_show_id_categoria}}{categoria}{nome} = $item->{ct_no_show_nome};
	 }

       }

       $c->model('DB::ActivityLog')->create
         ({ activity_type => '/atendimento/estados',
            id_local => $id,
            vt_base => $c->stash->{vt_base},
            vt_ini => $c->stash->{now} });

     });



}

1;

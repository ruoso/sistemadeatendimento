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

       my $sql_times = q{
SELECT
 DISTINCT DATE_TRUNC('minute', estado_atendimento.vt_ini) + '59.9999999 seconds' AS vt_fac
FROM
 atendimento LEFT JOIN 
 estado_atendimento USING (id_atendimento)
WHERE
 atendimento.id_local = ? AND
 atendimento.vt_ini >= ? AND
 atendimento.vt_ini < ? AND
 estado_atendimento.vt_ini >= ? AND
 estado_atendimento.vt_ini < ?
};

         my $sql_estados_categorias = q{
SELECT
 COUNT(tipo_estado_atendimento.*) as quantidade,
 categoria.nome, categoria.codigo, categoria.id_categoria,
 tipo_estado_atendimento.nome as nome_estado

FROM
 categoria LEFT JOIN
 categoria_atendimento
   ON (categoria.id_categoria=categoria_atendimento.id_categoria AND
       categoria_atendimento.vt_ini <= ? AND
       categoria_atendimento.vt_fim > ?) LEFT JOIN
 atendimento
   ON (atendimento.id_atendimento=categoria_atendimento.id_atendimento AND
       atendimento.id_local = ? ) LEFT JOIN
 estado_atendimento
   ON (atendimento.id_atendimento=estado_atendimento.id_atendimento AND
       estado_atendimento.vt_ini <= ? AND
       estado_atendimento.vt_fim > ?) LEFT JOIN
 tipo_estado_atendimento USING (id_estado)

WHERE tipo_estado_atendimento.nome IS NOT NULL

GROUP BY
  categoria.nome, categoria.codigo, categoria.id_categoria,
  tipo_estado_atendimento.nome


};

       my $storage = $c->model('Federado')->storage($c, $id);
       $storage->ensure_connected;
       my $dbi = $storage->dbh;

       my $sth = $dbi->prepare($sql_times);
       $sth->execute( $id,
                      $c->stash->{last_vt_base}, $c->stash->{vt_base},
                      $c->stash->{last_vt_base}, $c->stash->{vt_base},
                    );

       my $sth_inner = $dbi->prepare($sql_estados_categorias);

       my $dlocal = $c->model('DB::DLocal')->get_dimension($local);
       my $cat_cache = {};

       while (my ($datahora) = $sth->fetchrow_array) {
         my $datahora_dt = DateTime::Format::Pg->parse_datetime($datahora);
         my $data = $c->model('DB::DData')->get_dimension($datahora_dt);
         my $horario = $c->model('DB::DHorario')->get_dimension($datahora_dt);
         my $counters_cat = {};

         $sth_inner->execute($datahora,$datahora,$id,$datahora,$datahora);
         while (my $item = $sth_inner->fetchrow_hashref) {
           my $id_categoria = $item->{id_categoria};
           $counters_cat->{$id_categoria}{$item->{nome_estado}} = $item->{quantidade};
           $counters_cat->{$id_categoria}{categoria}{codigo} = $item->{codigo};
           $counters_cat->{$id_categoria}{categoria}{codigo} = $item->{nome};
         }

         foreach my $id_categoria (keys %{$counters_cat}) {
           unless (exists $cat_cache->{$id_categoria}) {
             $cat_cache->{$id_categoria} = $c->model('DB::DCategoria')->get_dimension
	       (Fila::Servico::DB::Categoria->new
		({ map { $_ => $counters_cat->{$id_categoria}{categoria}{$_}
		       } qw(id_categoria nome codigo) }));
           }
           my $categoria = $cat_cache->{$id_categoria};

           $c->model('DB::FQuantidadeEstados')->create
             ({ id_local => $dlocal,
                id_categoria => $categoria,
                data => $data,
                horario => $horario,

                ( map { 'quantidade_'.$_ => ($counters_cat->{$id_categoria}{$_} || 0) }
                  'espera',
                  'chamando',
                  'atendimento',
                  'avaliacao'
                )
              });
         }

       }

       $c->model('DB::ActivityLog')->create
         ({ activity_type => '/atendimento/estados',
            id_local => $id,
            vt_base => $c->stash->{vt_base},
            vt_ini => $c->stash->{now} });

     });

}

sub no_show :Chained('atendimento') :PathPart :Args(0) {
  my ($self, $c) = @_;

  $c->model('Federado')->doeach
    ($c, sub {
       my $id = shift;

       my $result = $c->model('DB::ActivityLog')->search
         ({ activity_type => '/atendimento/no_show',
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
SELECT
 DATE_TRUNC('minute', estado_atendimento.vt_ini) AS datahora,
 COUNT(estado_atendimento.*) AS quantidade,
 categoria.nome, categoria.codigo, categoria.id_categoria

FROM
 tipo_estado_atendimento INNER JOIN
 estado_atendimento
  ON (tipo_estado_atendimento.id_estado=estado_atendimento.id_estado AND
      estado_atendimento.vt_ini > ? AND
      estado_atendimento.vt_ini <= ?) INNER JOIN
 atendimento
  ON (estado_atendimento.id_atendimento=atendimento.id_atendimento AND
      atendimento.id_local = ? AND
      atendimento.vt_ini > ? AND
      atendimento.vt_ini <= ?) INNER JOIN
 categoria_atendimento
  ON (categoria_atendimento.id_atendimento=atendimento.id_atendimento AND
      categoria_atendimento.vt_ini <= estado_atendimento.vt_ini AND
      categoria_atendimento.vt_fim > estado_atendimento.vt_ini) INNER JOIN
 categoria USING (id_categoria)

WHERE tipo_estado_atendimento.nome='no_show'

GROUP BY
 DATE_TRUNC('minute', estado_atendimento.vt_ini),
 categoria.nome, categoria.codigo, categoria.id_categoria

#;

       my $storage = $c->model('Federado')->storage($c, $id);
       $storage->ensure_connected;
       my $dbi = $storage->dbh;

       my $sth = $dbi->prepare($sql);
       $sth->execute( $c->stash->{last_vt_base}, $c->stash->{vt_base},
                      $id,
                      $c->stash->{last_vt_base}, $c->stash->{vt_base},
                    );

       my $dlocal = $c->model('DB::DLocal')->get_dimension($local);
       my $cat_cache = {};

       while (my $item = $sth->fetchrow_hashref) {
         my $datahora = $item->{datahora};
         my $datahora_dt = DateTime::Format::Pg->parse_datetime($datahora);
         my $data = $c->model('DB::DData')->get_dimension($datahora_dt);
         my $horario = $c->model('DB::DHorario')->get_dimension($datahora_dt);
         my $id_categoria = $item->{id_categoria};

         unless (exists $cat_cache->{$id_categoria}) {
           $cat_cache->{$id_categoria} = $c->model('DB::DCategoria')->get_dimension
             (Fila::Servico::DB::Categoria->new
              ({ map { $_ => $item->{$_}
                     } qw(id_categoria nome codigo) }));
         }
         my $categoria = $cat_cache->{$id_categoria};

         $c->model('DB::FQuantidadeEstados')->create
           ({ id_local => $dlocal,
              id_categoria => $categoria,
              data => $data,
              horario => $horario,
              quantidade => $item->{quantidade}
            });
       }


       $c->model('DB::ActivityLog')->create
         ({ activity_type => '/atendimento/no_show',
            id_local => $id,
            vt_base => $c->stash->{vt_base},
            vt_ini => $c->stash->{now} });

     });

}


1;

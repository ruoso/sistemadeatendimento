#!/usr/bin/perl
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
use lib 'lib';
use SQL::Translator;

my $t = SQL::Translator->new
  (
   show_warnings       => 1,
   add_drop_table      => 1,
   quote_table_names   => 1,
   quote_field_names   => 1,
   validate            => 1,
  );
$t->parser_args
  (
   'DBIx::Schema' => 'Fila::Agendamento::DB',
  );
my $r = $t->translate
  (
   from => 'SQL::Translator::Parser::DBIx::Class',
   to => 'PostgreSQL',
  ) or die $t->error;
print $r;

print <<SQL;

DROP TABLE intervalos;
DROP VIEW intervalos;

CREATE VIEW intervalos AS
 SELECT inicio, inicio + interval '15 minutes' AS fim
 FROM (
    SELECT (DATE_TRUNC('day',NOW()) + dias * INTERVAL '1 day' + hora * INTERVAL '1 hour' + atend * INTERVAL '15 minutes') AS inicio
    FROM
    GENERATE_SERIES(0,14) dias,
    GENERATE_SERIES(0,23) hora,
    GENERATE_SERIES(0, 3) atend
    ORDER BY inicio
 ) AS t(inicio)
 WHERE t.inicio >= NOW() + interval '1 hour';

INSERT INTO local VALUES (1, '2008-01-01 00:00:00+0000', 'Infinity', 'Local de Teste');
INSERT INTO local VALUES (2, '2008-01-01 00:00:00+0000', 'Infinity', 'Outro Local');
INSERT INTO expediente VALUES (1, 1, 1, 8, 17);
INSERT INTO expediente VALUES (2, 1, 2, 8, 17);
INSERT INTO expediente VALUES (3, 1, 3, 8, 17);
INSERT INTO expediente VALUES (4, 1, 4, 8, 17);
INSERT INTO expediente VALUES (5, 1, 5, 8, 17);
INSERT INTO expediente VALUES (7, 2, 1, 8, 17);
INSERT INTO expediente VALUES (8, 2, 2, 8, 17);
INSERT INTO expediente VALUES (9, 2, 3, 8, 17);
INSERT INTO expediente VALUES (10, 2, 4, 8, 17);
INSERT INTO expediente VALUES (11, 2, 5, 8, 17);
INSERT INTO feriado VALUES (1, '2008-06-24', 'Dia do trabalhador');
INSERT INTO feriado VALUES (1, '2008-06-25', 'Nao e um feriado');
INSERT INTO feriado VALUES (2, '2008-06-26', 'Dia do trabalhador');
INSERT INTO feriado VALUES (2, '2008-06-27', 'Nao e um feriado');


SQL

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
   'DBIx::Schema' => 'Fila::Servico::DB',
  );
my $r = $t->translate
  (
   from => 'SQL::Translator::Parser::DBIx::Class',
   to => 'PostgreSQL',
  ) or die $t->error;
print $r;

print <<SQL;

INSERT INTO local VALUES (1, '2008-01-01 00:00:00+0000', 'Infinity', 'Local de Teste', 'emissor\@agents.fila.vhost', 'painel\@agents.fila.vhost', 'opiniometro\@agents.fila.vhost');
SELECT SETVAL('local_id_local_seq', 1);

INSERT INTO tipo_estado_local VALUES (1, 'aberto');
INSERT INTO tipo_estado_local VALUES (2, 'senhas_encerradas');
INSERT INTO tipo_estado_local VALUES (3, 'fechado');

INSERT INTO estado_local VALUES (1, 2, '2008-01-01 00:00:00+0000', 'Infinity');

INSERT INTO guiche VALUES (1, 1, '2008-01-01 00:00:00+0000', 'Infinity', '01', 'opiniometro01\@agents.fila.vhost',0);
INSERT INTO guiche VALUES (2, 1, '2008-01-01 00:00:00+0000', 'Infinity', '02', 'opiniometro02\@agents.fila.vhost',0);
INSERT INTO guiche VALUES (3, 1, '2008-01-01 00:00:00+0000', 'Infinity', '03', 'opiniometro03\@agents.fila.vhost',0);
INSERT INTO guiche VALUES (4, 1, '2008-01-01 00:00:00+0000', 'Infinity', '04', 'opiniometro04\@agents.fila.vhost',0);
INSERT INTO guiche VALUES (5, 1, '2008-01-01 00:00:00+0000', 'Infinity', '05', 'opiniometro05\@agents.fila.vhost',0);
INSERT INTO guiche VALUES (6, 1, '2008-01-01 00:00:00+0000', 'Infinity', '06', 'opiniometro06\@agents.fila.vhost',0);
INSERT INTO guiche VALUES (7, 1, '2008-01-01 00:00:00+0000', 'Infinity', '07', 'opiniometro07\@agents.fila.vhost',0);
INSERT INTO guiche VALUES (8, 1, '2008-01-01 00:00:00+0000', 'Infinity', '08', 'opiniometro08\@agents.fila.vhost',0);
INSERT INTO guiche VALUES (9, 1, '2008-01-01 00:00:00+0000', 'Infinity', '09', 'opiniometro09\@agents.fila.vhost',0);
INSERT INTO guiche VALUES (10, 1, '2008-01-01 00:00:00+0000', 'Infinity', '10', 'opiniometro10\@agents.fila.vhost',0);
INSERT INTO guiche VALUES (11, 1, '2008-01-01 00:00:00+0000', 'Infinity', '11', 'opiniometro11\@agents.fila.vhost',0);
INSERT INTO guiche VALUES (12, 1, '2008-01-01 00:00:00+0000', 'Infinity', '12', 'opiniometro12\@agents.fila.vhost',0);
INSERT INTO guiche VALUES (13, 1, '2008-01-01 00:00:00+0000', 'Infinity', '13', 'opiniometro13\@agents.fila.vhost',0);
INSERT INTO guiche VALUES (14, 1, '2008-01-01 00:00:00+0000', 'Infinity', '14', 'opiniometro14\@agents.fila.vhost',0);
INSERT INTO guiche VALUES (15, 1, '2008-01-01 00:00:00+0000', 'Infinity', '15', 'opiniometro15\@agents.fila.vhost',0);
INSERT INTO guiche VALUES (16, 1, '2008-01-01 00:00:00+0000', 'Infinity', '16', 'opiniometro16\@agents.fila.vhost',0);
INSERT INTO guiche VALUES (17, 1, '2008-01-01 00:00:00+0000', 'Infinity', '17', 'opiniometro17\@agents.fila.vhost',0);
INSERT INTO guiche VALUES (18, 1, '2008-01-01 00:00:00+0000', 'Infinity', '18', 'opiniometro18\@agents.fila.vhost',0);
INSERT INTO guiche VALUES (19, 1, '2008-01-01 00:00:00+0000', 'Infinity', '19', 'opiniometro19\@agents.fila.vhost',0);
INSERT INTO guiche VALUES (20, 1, '2008-01-01 00:00:00+0000', 'Infinity', '20', 'opiniometro20\@agents.fila.vhost',0);
INSERT INTO guiche VALUES (21, 1, '2008-01-01 00:00:00+0000', 'Infinity', '21', 'opiniometro21\@agents.fila.vhost',0);
INSERT INTO guiche VALUES (22, 1, '2008-01-01 00:00:00+0000', 'Infinity', '22', 'opiniometro22\@agents.fila.vhost',0);
INSERT INTO guiche VALUES (23, 1, '2008-01-01 00:00:00+0000', 'Infinity', '23', 'opiniometro23\@agents.fila.vhost',0);
INSERT INTO guiche VALUES (24, 1, '2008-01-01 00:00:00+0000', 'Infinity', '24', 'opiniometro24\@agents.fila.vhost',0);
INSERT INTO guiche VALUES (25, 1, '2008-01-01 00:00:00+0000', 'Infinity', '25', 'opiniometro25\@agents.fila.vhost',0);
SELECT SETVAL('guiche_id_guiche_seq', 25);

INSERT INTO tipo_estado_guiche VALUES (1, 'disponivel');
INSERT INTO tipo_estado_guiche VALUES (2, 'pausa');
INSERT INTO tipo_estado_guiche VALUES (3, 'chamando');
INSERT INTO tipo_estado_guiche VALUES (4, 'atendimento');
INSERT INTO tipo_estado_guiche VALUES (5, 'interno');
INSERT INTO tipo_estado_guiche VALUES (6, 'fechado');
INSERT INTO tipo_estado_guiche VALUES (7, 'avaliacao');
INSERT INTO tipo_estado_guiche VALUES (8, 'concluido');

INSERT INTO estado_guiche VALUES (1, 6, '2008-01-01 00:00:00+0000', 'Infinity');
INSERT INTO estado_guiche VALUES (2, 6, '2008-01-01 00:00:00+0000', 'Infinity');
INSERT INTO estado_guiche VALUES (3, 6, '2008-01-01 00:00:00+0000', 'Infinity');
INSERT INTO estado_guiche VALUES (4, 6, '2008-01-01 00:00:00+0000', 'Infinity');
INSERT INTO estado_guiche VALUES (5, 6, '2008-01-01 00:00:00+0000', 'Infinity');
INSERT INTO estado_guiche VALUES (6, 6, '2008-01-01 00:00:00+0000', 'Infinity');
INSERT INTO estado_guiche VALUES (7, 6, '2008-01-01 00:00:00+0000', 'Infinity');
INSERT INTO estado_guiche VALUES (8, 6, '2008-01-01 00:00:00+0000', 'Infinity');
INSERT INTO estado_guiche VALUES (9, 6, '2008-01-01 00:00:00+0000', 'Infinity');
INSERT INTO estado_guiche VALUES (10, 6, '2008-01-01 00:00:00+0000', 'Infinity');
INSERT INTO estado_guiche VALUES (11, 6, '2008-01-01 00:00:00+0000', 'Infinity');
INSERT INTO estado_guiche VALUES (12, 6, '2008-01-01 00:00:00+0000', 'Infinity');
INSERT INTO estado_guiche VALUES (13, 6, '2008-01-01 00:00:00+0000', 'Infinity');
INSERT INTO estado_guiche VALUES (14, 6, '2008-01-01 00:00:00+0000', 'Infinity');
INSERT INTO estado_guiche VALUES (15, 6, '2008-01-01 00:00:00+0000', 'Infinity');
INSERT INTO estado_guiche VALUES (16, 6, '2008-01-01 00:00:00+0000', 'Infinity');
INSERT INTO estado_guiche VALUES (17, 6, '2008-01-01 00:00:00+0000', 'Infinity');
INSERT INTO estado_guiche VALUES (18, 6, '2008-01-01 00:00:00+0000', 'Infinity');
INSERT INTO estado_guiche VALUES (19, 6, '2008-01-01 00:00:00+0000', 'Infinity');
INSERT INTO estado_guiche VALUES (20, 6, '2008-01-01 00:00:00+0000', 'Infinity');
INSERT INTO estado_guiche VALUES (21, 6, '2008-01-01 00:00:00+0000', 'Infinity');
INSERT INTO estado_guiche VALUES (22, 6, '2008-01-01 00:00:00+0000', 'Infinity');
INSERT INTO estado_guiche VALUES (23, 6, '2008-01-01 00:00:00+0000', 'Infinity');
INSERT INTO estado_guiche VALUES (24, 6, '2008-01-01 00:00:00+0000', 'Infinity');
INSERT INTO estado_guiche VALUES (25, 6, '2008-01-01 00:00:00+0000', 'Infinity');

INSERT INTO funcionario VALUES (1, 'Gerente de Exemplo', 'gerente\@people.fila.vhost', MD5('password'));
INSERT INTO funcionario VALUES (2, 'Atendente de Exemplo 1', 'atendente01\@people.fila.vhost', MD5('password'));
INSERT INTO funcionario VALUES (3, 'Atendente de Exemplo 2', 'atendente02\@people.fila.vhost', MD5('password'));
INSERT INTO funcionario VALUES (4, 'Atendente de Exemplo 3', 'atendente03\@people.fila.vhost', MD5('password'));
INSERT INTO funcionario VALUES (5, 'Atendente de Exemplo 4', 'atendente04\@people.fila.vhost', MD5('password'));
INSERT INTO funcionario VALUES (6, 'Atendente de Exemplo 5', 'atendente05\@people.fila.vhost', MD5('password'));
INSERT INTO funcionario VALUES (7, 'Atendente de Exemplo 6', 'atendente06\@people.fila.vhost', MD5('password'));
INSERT INTO funcionario VALUES (8, 'Atendente de Exemplo 7', 'atendente07\@people.fila.vhost', MD5('password'));
INSERT INTO funcionario VALUES (9, 'Atendente de Exemplo 8', 'atendente08\@people.fila.vhost', MD5('password'));
INSERT INTO funcionario VALUES (10, 'Atendente de Exemplo 9', 'atendente09\@people.fila.vhost', MD5('password'));
INSERT INTO funcionario VALUES (11, 'Atendente de Exemplo 10', 'atendente10\@people.fila.vhost', MD5('password'));
INSERT INTO funcionario VALUES (12, 'Atendente de Exemplo 11', 'atendente11\@people.fila.vhost', MD5('password'));
INSERT INTO funcionario VALUES (13, 'Atendente de Exemplo 12', 'atendente12\@people.fila.vhost', MD5('password'));
INSERT INTO funcionario VALUES (14, 'Atendente de Exemplo 13', 'atendente13\@people.fila.vhost', MD5('password'));
INSERT INTO funcionario VALUES (15, 'Atendente de Exemplo 14', 'atendente14\@people.fila.vhost', MD5('password'));
INSERT INTO funcionario VALUES (16, 'Atendente de Exemplo 15', 'atendente15\@people.fila.vhost', MD5('password'));
INSERT INTO funcionario VALUES (17, 'Atendente de Exemplo 16', 'atendente16\@people.fila.vhost', MD5('password'));
INSERT INTO funcionario VALUES (18, 'Atendente de Exemplo 17', 'atendente17\@people.fila.vhost', MD5('password'));
INSERT INTO funcionario VALUES (19, 'Atendente de Exemplo 18', 'atendente18\@people.fila.vhost', MD5('password'));
INSERT INTO funcionario VALUES (20, 'Atendente de Exemplo 19', 'atendente19\@people.fila.vhost', MD5('password'));
INSERT INTO funcionario VALUES (21, 'Atendente de Exemplo 20', 'atendente20\@people.fila.vhost', MD5('password'));
INSERT INTO funcionario VALUES (22, 'Atendente de Exemplo 21', 'atendente21\@people.fila.vhost', MD5('password'));
INSERT INTO funcionario VALUES (23, 'Atendente de Exemplo 22', 'atendente22\@people.fila.vhost', MD5('password'));
INSERT INTO funcionario VALUES (24, 'Atendente de Exemplo 23', 'atendente23\@people.fila.vhost', MD5('password'));
INSERT INTO funcionario VALUES (25, 'Atendente de Exemplo 24', 'atendente24\@people.fila.vhost', MD5('password'));
INSERT INTO funcionario VALUES (26, 'Atendente de Exemplo 25', 'atendente25\@people.fila.vhost', MD5('password'));
SELECT SETVAL('funcionario_id_funcionario_seq', 26);

INSERT INTO funcionario_local VALUES (1, 1, '2008-01-01 00:00:00+0000', 'Infinity');
INSERT INTO funcionario_local VALUES (2, 1, '2008-01-01 00:00:00+0000', 'Infinity');
INSERT INTO funcionario_local VALUES (3, 1, '2008-01-01 00:00:00+0000', 'Infinity');
INSERT INTO funcionario_local VALUES (4, 1, '2008-01-01 00:00:00+0000', 'Infinity');
INSERT INTO funcionario_local VALUES (5, 1, '2008-01-01 00:00:00+0000', 'Infinity');
INSERT INTO funcionario_local VALUES (6, 1, '2008-01-01 00:00:00+0000', 'Infinity');
INSERT INTO funcionario_local VALUES (7, 1, '2008-01-01 00:00:00+0000', 'Infinity');
INSERT INTO funcionario_local VALUES (8, 1, '2008-01-01 00:00:00+0000', 'Infinity');
INSERT INTO funcionario_local VALUES (9, 1, '2008-01-01 00:00:00+0000', 'Infinity');
INSERT INTO funcionario_local VALUES (10, 1, '2008-01-01 00:00:00+0000', 'Infinity');
INSERT INTO funcionario_local VALUES (11, 1, '2008-01-01 00:00:00+0000', 'Infinity');
INSERT INTO funcionario_local VALUES (12, 1, '2008-01-01 00:00:00+0000', 'Infinity');
INSERT INTO funcionario_local VALUES (13, 1, '2008-01-01 00:00:00+0000', 'Infinity');
INSERT INTO funcionario_local VALUES (14, 1, '2008-01-01 00:00:00+0000', 'Infinity');
INSERT INTO funcionario_local VALUES (15, 1, '2008-01-01 00:00:00+0000', 'Infinity');
INSERT INTO funcionario_local VALUES (16, 1, '2008-01-01 00:00:00+0000', 'Infinity');
INSERT INTO funcionario_local VALUES (17, 1, '2008-01-01 00:00:00+0000', 'Infinity');
INSERT INTO funcionario_local VALUES (18, 1, '2008-01-01 00:00:00+0000', 'Infinity');
INSERT INTO funcionario_local VALUES (19, 1, '2008-01-01 00:00:00+0000', 'Infinity');
INSERT INTO funcionario_local VALUES (20, 1, '2008-01-01 00:00:00+0000', 'Infinity');
INSERT INTO funcionario_local VALUES (21, 1, '2008-01-01 00:00:00+0000', 'Infinity');
INSERT INTO funcionario_local VALUES (22, 1, '2008-01-01 00:00:00+0000', 'Infinity');
INSERT INTO funcionario_local VALUES (23, 1, '2008-01-01 00:00:00+0000', 'Infinity');
INSERT INTO funcionario_local VALUES (24, 1, '2008-01-01 00:00:00+0000', 'Infinity');
INSERT INTO funcionario_local VALUES (25, 1, '2008-01-01 00:00:00+0000', 'Infinity');
INSERT INTO funcionario_local VALUES (26, 1, '2008-01-01 00:00:00+0000', 'Infinity');

INSERT INTO tipo_estado_atendimento VALUES (1, 'espera');
INSERT INTO tipo_estado_atendimento VALUES (2, 'chamando');
INSERT INTO tipo_estado_atendimento VALUES (3, 'encaminhado');
INSERT INTO tipo_estado_atendimento VALUES (4, 'atendimento');
INSERT INTO tipo_estado_atendimento VALUES (5, 'avaliacao');
INSERT INTO tipo_estado_atendimento VALUES (6, 'encerrado');
INSERT INTO tipo_estado_atendimento VALUES (7, 'no_show');

INSERT INTO gerente_local VALUES (1, 1, '2008-01-01 00:00:00+0000', 'Infinity');

INSERT INTO categoria VALUES (1, 'Atendimento Preferencial', 'P');
INSERT INTO categoria VALUES (2, 'Atendimento Normal', 'N');
INSERT INTO categoria VALUES (3, 'Servidor', 'S');
INSERT INTO categoria VALUES (4, 'Técnico', 'T');
INSERT INTO categoria VALUES (5, 'Agendamento', 'A');
SELECT SETVAL('categoria_id_categoria_seq', 5);

INSERT INTO configuracao_categoria VALUES (1,1,'2008-01-01 00:00:00+0000', 'Infinity', 1, 3600, 100,1);
INSERT INTO configuracao_categoria VALUES (1,2,'2008-01-01 00:00:00+0000', 'Infinity', 2, 3600, 100,2);
INSERT INTO configuracao_categoria VALUES (1,3,'2008-01-01 00:00:00+0000', 'Infinity', 3, 3600, 100,3);
INSERT INTO configuracao_categoria VALUES (1,4,'2008-01-01 00:00:00+0000', 'Infinity', 4, 3600, 100,0);
INSERT INTO configuracao_categoria VALUES (1,5,'2008-01-01 00:00:00+0000', 'Infinity', 5, 3600, 100,0);

INSERT INTO classe_servico VALUES (1,'Classe 1');
INSERT INTO classe_servico VALUES (2,'Classe 2');
INSERT INTO classe_servico VALUES (3,'Classe 3');
INSERT INTO classe_servico VALUES (4,'Classe 4');
SELECT SETVAL('classe_servico_id_classe_seq', 4);

INSERT INTO pergunta_avaliacao VALUES (1, '2008-01-01 00:00:00+0000', 'Infinity', 'O atendente foi simpático?');
INSERT INTO pergunta_avaliacao VALUES (2, '2008-01-01 00:00:00+0000', 'Infinity', 'O atendente foi gente boa?');
INSERT INTO pergunta_avaliacao VALUES (3, '2008-01-01 00:00:00+0000', 'Infinity', 'O atendente estava feliz?');
INSERT INTO pergunta_avaliacao VALUES (4, '2008-01-01 00:00:00+0000', 'Infinity', 'O atendimento foi rápido?');
INSERT INTO pergunta_avaliacao VALUES (5, '2008-01-01 00:00:00+0000', 'Infinity', 'O atendimento foi bom?');
SELECT SETVAL('pergunta_avaliacao_id_pergunta_seq', 5);

INSERT INTO pergunta_avaliacao_praca VALUES (1, '2008-01-01 00:00:00+0000', 'Infinity', 'Ambiente da praça');
INSERT INTO pergunta_avaliacao_praca VALUES (2, '2008-01-01 00:00:00+0000', 'Infinity', 'Rapidez da praça');
INSERT INTO pergunta_avaliacao_praca VALUES (3, '2008-01-01 00:00:00+0000', 'Infinity', 'Comforto da praça');
INSERT INTO pergunta_avaliacao_praca VALUES (4, '2008-01-01 00:00:00+0000', 'Infinity', 'Atendimento');
INSERT INTO pergunta_avaliacao_praca VALUES (5, '2008-01-01 00:00:00+0000', 'Infinity', 'Atendentes');
SELECT SETVAL('pergunta_avaliacao_praca_id_pergunta_seq', 5);

INSERT INTO configuracao_perguntas VALUES (1,'2008-01-01 00:00:00+0000', 'Infinity', 1, 2, 3, 4, 5);
INSERT INTO configuracao_perguntas_praca VALUES (1,'2008-01-01 00:00:00+0000', 'Infinity', 1, 2, 3, 4, 5);

INSERT INTO servico VALUES (1,1,'2008-01-01 00:00:00+0000', 'Infinity', 'SPU');
INSERT INTO servico VALUES (2,1,'2008-01-01 00:00:00+0000', 'Infinity', 'SCUMA');
INSERT INTO servico VALUES (3,2,'2008-01-01 00:00:00+0000', 'Infinity', 'Base de conhecimento');
INSERT INTO servico VALUES (4,3,'2008-01-01 00:00:00+0000', 'Infinity', 'Outros');
SELECT SETVAL('servico_id_servico_seq', 4);

INSERT INTO servico_interno VALUES (1,1,'2008-01-01 00:00:00+0000', 'Infinity', 'Digitalização de documentos');
INSERT INTO servico_interno VALUES (2,1,'2008-01-01 00:00:00+0000', 'Infinity', 'Xerox de documentos');
INSERT INTO servico_interno VALUES (3,2,'2008-01-01 00:00:00+0000', 'Infinity', 'Base de conhecimento');
INSERT INTO servico_interno VALUES (4,3,'2008-01-01 00:00:00+0000', 'Infinity', 'Outros');
SELECT SETVAL('servico_interno_id_servico_seq', 4);

SQL

for my $id_categoria (1..5) {
    for my $senha (1..999) {
        print 'INSERT INTO senha VALUES ('.((($id_categoria - 1)*999) + $senha).','.$id_categoria.',1,'.$senha.");\n";
    }
}

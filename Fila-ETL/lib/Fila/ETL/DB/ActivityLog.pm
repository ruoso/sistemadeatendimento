package Fila::ETL::DB::ActivityLog;
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
use base qw(DBIx::Class);

__PACKAGE__->load_components(qw(InflateColumn::DateTime PK::Auto Core));
__PACKAGE__->table('activitylog');
__PACKAGE__->add_columns
  (
   id_local =>
   {
    data_type => 'integer',
   },
   activity_type =>
   {
    data_type => 'varchar',
   },
   vt_ini =>
   {
    data_type => 'timestamp with time zone',
   },
   vt_base =>
   {
    data_type => 'timestamp with time zone',
   }
  );

__PACKAGE__->set_primary_key(qw(id_local activity_type vt_ini));

1;

__END__

=head1 NAME

ActivityLog - Controle de atividades de ETL

=head1 DESCRIPTION

Essa tabela contém as atividades de ETL realizadas, guardando a data
de base para as operações, bem como a data e hora de início da
operação. Essa tabela será usada pelo próprio processo de ETL para
poder determinar os intervalos de tempo a serem trabalhados.

=cut

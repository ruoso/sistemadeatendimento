package Fila::Agendamento::DB::IntervalosView;
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

use base qw(DBIx::Class);

__PACKAGE__->load_components(qw(InflateColumn::DateTime PK::Auto Core));
__PACKAGE__->table('intervalos');
__PACKAGE__->add_columns
  (
   inicio =>
   {
    data_type => 'timestamp with time zone',
   },
   fim =>
   {
    data_type => 'timestamp with time zone'
   }
  );

1;
__END__

=head1 NAME

Fila::Agendamento::DB::IntervalosView - Acesso ao view intervalos

=head1 SYNOPSIS

  CREATE VIEW intervalos AS SELECT inicio, inicio + interval '15
  minutes' AS fim FROM (select (date_trunc('day',now()) + dias *
  interval '1 day' + hora * interval '1 hour' + atend * interval '15
  minutes') AS inicio from generate_series(0,15) dias,
  generate_series(8, 17) hora, generate_series(0,3) atend) AS
  t(inicio) WHERE extract(dow FROM t.inicio) between 1 and 5 AND
  t.inicio >= NOW() + interval '1 hour';

=head1 DESCRIPTION

Este view é utilizado para listar os próximos intervalos possíveis
para o registro de novos agendamentos.

=cut


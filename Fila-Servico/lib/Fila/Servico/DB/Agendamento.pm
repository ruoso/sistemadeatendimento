package Fila::Servico::DB::Agendamento;
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
__PACKAGE__->table('agendamento');
__PACKAGE__->add_columns
  (
   id_atendimento =>
   {
    data_type => 'integer',
   },
   id_agendamento =>
   {
    data_type => 'integer',
   },
   nome =>
   {
    data_type => 'varchar'
   },
   email =>
   {
    data_type => 'varchar'
   },
   tipopessoa =>
   {
    data_type => 'varchar',
   },
   cnpjf =>
   {
    data_type => 'varchar',
   }
  );

__PACKAGE__->set_primary_key(qw(id_atendimento));
__PACKAGE__->belongs_to('atendimento', 'Fila::Servico::DB::Atendimento',
                        { 'foreign.id_atendimento' => 'self.id_atendimento' });

1;

__END__

=head1 NAME

Agendamento - Informação auxiliar de agendamento

=head1 DESCRIPTION

Quando o atendimento a ser realizado foi agendado previamente, essa
tabela deve conter informações acerca do titular do agendamento para
permitir uma verificação por parte do atendente.

=cut


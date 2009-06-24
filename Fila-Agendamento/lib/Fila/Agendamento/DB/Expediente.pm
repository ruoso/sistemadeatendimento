package Fila::Agendamento::DB::Expediente;
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
__PACKAGE__->table('expediente');
__PACKAGE__->add_columns
  (
   id_expediente =>
   {
    data_type => 'integer',
    is_autoincrement => 1,
   },
   id_local =>
   {
    data_type => 'integer',
   },
   dia_semana =>
   {
    data_type => 'integer',
   },
   hora_inicio =>
   {
    data_type => 'integer',
   },
   hora_fim =>
   {
    data_type => 'integer',
   }
  );
__PACKAGE__->set_primary_key(qw(id_expediente));

__PACKAGE__->belongs_to('local', 'Fila::Agendamento::DB::Local',
                        { 'foreign.id_local' => 'self.id_local' });

1;

__END__

=head1 NAME

Expediente - Lista cada expediente do local

=head1 DESCRIPTION

Permite a configuração da hora de inicio e fim de cada dia da semana
para cada local, permitindo configurar, por exemplo, o funcionamento
apenas pela manhã no sábado.

=cut


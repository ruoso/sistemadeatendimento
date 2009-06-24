package Fila::Servico::DB::ServicoGuiche;
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
__PACKAGE__->table('servico_guiche');
__PACKAGE__->add_columns
  (
   id_servico =>
   {
    data_type => 'integer',
   },
   id_guiche =>
   {
    data_type => 'integer',
   },
   vt_ini =>
   {
    data_type => 'timestamp with time zone',
   },
   vt_fim =>
   {
    data_type => 'timestamp with time zone',
   },
   informacoes =>
   {
    data_type => 'varchar',
   }
  );
__PACKAGE__->set_primary_key(qw(id_servico id_guiche vt_ini vt_fim));
__PACKAGE__->belongs_to('servico', 'Fila::Servico::DB::ServicoInterno',
                        { 'foreign.id_servico' => 'self.id_servico' });
__PACKAGE__->belongs_to('guiche', 'Fila::Servico::DB::Guiche',
                        { 'foreign.id_guiche' => 'self.id_guiche' });

1;

__END__

=head1 NAME

ServicoGuiche - Registro temporal dos servicos internos

=head1 DESCRIPTION

Essa tabela mantem o registro temporal dos serviços internos, ou seja,
realizados fora do contexto de um atendimento.

=cut


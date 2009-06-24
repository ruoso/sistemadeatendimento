package Fila::Servico::DB::Funcionario;
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
__PACKAGE__->table('funcionario');
__PACKAGE__->add_columns
  (
   id_funcionario =>
   {
    data_type => 'integer',
    is_auto_increment => 1
   },
   nome =>
   {
    data_type => 'varchar',
   },
   jid =>
   {
    data_type => 'varchar',
   },
   password =>
   {
    data_type => 'varchar',
   },
  );
__PACKAGE__->set_primary_key(qw(id_funcionario));

__PACKAGE__->has_many('locais', 'Fila::Servico::DB::FuncionarioLocal',
                      { 'foreign.id_funcionario' => 'self.id_funcionario' });

__PACKAGE__->has_many('local_atual', 'Fila::Servico::DB::FuncionarioLocal',
                      { 'foreign.id_funcionario' => 'self.id_funcionario',
                       'foreign.vt_ini' => \"<= NOW()", #"
                       'foreign.vt_fim' => \"> NOW()"}, #"
                      { join_type => 'left' });

__PACKAGE__->has_many('gerentes', 'Fila::Servico::DB::GerenteLocal',
                      { 'foreign.id_funcionario' => 'self.id_funcionario' });

__PACKAGE__->has_many('gerente_atual', 'Fila::Servico::DB::GerenteLocal',
                      { 'foreign.id_funcionario' => 'self.id_funcionario',
                       'foreign.vt_ini' => \"<= NOW()", #"
                       'foreign.vt_fim' => \"> NOW()"}, #"
                      { join_type => 'left' });

__PACKAGE__->has_many('atendentes', 'Fila::Servico::DB::AtendenteGuiche',
                      { 'foreign.id_funcionario' => 'self.id_funcionario' });

__PACKAGE__->has_many('atendente_atual', 'Fila::Servico::DB::AtendenteGuiche',
                      { 'foreign.id_funcionario' => 'self.id_funcionario',
                       'foreign.vt_ini' => \"<= NOW()", #"
                       'foreign.vt_fim' => \"> NOW()"}, #"
                      { join_type => 'left' });

__PACKAGE__->has_many('pausas', 'Fila::Servico::DB::Pausa',
                      { 'foreign.id_funcionario' => 'self.id_funcionario' });

__PACKAGE__->has_many('pausa_atual', 'Fila::Servico::DB::Pausa',
                      { 'foreign.id_funcionario' => 'self.id_funcionario',
                       'foreign.vt_ini' => \"<= NOW()", #"
                       'foreign.vt_fim' => \"> NOW()"}, #"
                      { join_type => 'left' });

1;

__END__

=head1 NAME

Funcionario - Funcionário que pode trabalhar em qualquer local

=head1 DESCRIPTION

A entidade funcionário é transversal aos locais de atendimento,
permitindo que um funcionário tome parte de mais de um local de
atendimento ao longo do tempo.

=cut


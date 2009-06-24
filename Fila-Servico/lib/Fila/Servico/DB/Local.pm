package Fila::Servico::DB::Local;
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
__PACKAGE__->table('local');
__PACKAGE__->add_columns
  (
   id_local =>
   {
    data_type => 'integer',
    is_auto_increment => 1
   },
   vt_ini =>
   {
    data_type => 'timestamp with time zone',
   },
   vt_fim =>
   {
    data_type => 'timestamp with time zone'
   },
   nome =>
   {
    data_type => 'varchar',
   },
   jid_senhas =>
   {
    data_type => 'varchar',
   },
   jid_painel =>
   {
    data_type => 'varchar',
   },
   jid_opiniometro =>
   {
    data_type => 'varchar',
   }
  );

__PACKAGE__->set_primary_key(qw(id_local));

__PACKAGE__->has_many('atendimentos', 'Fila::Servico::DB::Atendimento',
                      { 'foreign.id_local' => 'self.id_local' });

__PACKAGE__->has_many('atendimentos_atuais', 'Fila::Servico::DB::Atendimento',
                      { 'foreign.id_local' => 'self.id_local',
                       'foreign.vt_ini' => \"<= NOW()", #"
                       'foreign.vt_fim' => \"> NOW()"}, #"
                      {    'join_type' => 'left' });

__PACKAGE__->has_many('senhas', 'Fila::Servico::DB::Senha',
                      { 'foreign.id_local' => 'self.id_local' });

__PACKAGE__->has_many('guiches', 'Fila::Servico::DB::Guiche',
                      { 'foreign.id_local' => 'self.id_local' });

__PACKAGE__->has_many('guiches_atuais', 'Fila::Servico::DB::Guiche',
                      { 'foreign.id_local' => 'self.id_local',
                       'foreign.vt_ini' => \"<= NOW()", #"
                       'foreign.vt_fim' => \"> NOW()"}, #"
                      {    'join_type' => 'left' });

__PACKAGE__->has_many('estados', 'Fila::Servico::DB::EstadoLocal',
                      { 'foreign.id_local' => 'self.id_local' });

__PACKAGE__->has_many('estado_atual', 'Fila::Servico::DB::EstadoLocal',
                      { 'foreign.id_local' => 'self.id_local',
                       'foreign.vt_ini' => \"<= NOW()", #"
                       'foreign.vt_fim' => \"> NOW()"}, #"
                      {    'join_type' => 'left' });

__PACKAGE__->has_many('configuracoes_categoria', 'Fila::Servico::DB::ConfiguracaoCategoria',
                      { 'foreign.id_local' => 'self.id_local' },
                      { join_type => 'left' });

__PACKAGE__->has_many('configuracoes_limite', 'Fila::Servico::DB::ConfiguracaoLimite',
                      { 'foreign.id_local' => 'self.id_local' },
                      { join_type => 'left' });

__PACKAGE__->has_many('configuracoes_categoria_atual', 'Fila::Servico::DB::ConfiguracaoCategoria',
                      { 'foreign.id_local' => 'self.id_local',
                       'foreign.vt_ini' => \"<= NOW()", #"
                       'foreign.vt_fim' => \"> NOW()"}, #"
                      {    'join_type' => 'left' });

__PACKAGE__->has_many('funcionarios', 'Fila::Servico::DB::FuncionarioLocal',
                      { 'foreign.id_local' => 'self.id_local' });

__PACKAGE__->has_many('funcionarios_atuais', 'Fila::Servico::DB::FuncionarioLocal',
                      { 'foreign.id_local' => 'self.id_local',
                       'foreign.vt_ini' => \"<= NOW()", #"
                       'foreign.vt_fim' => \"> NOW()"}, #"
                      {    'join_type' => 'left' });

__PACKAGE__->has_many('gerentes', 'Fila::Servico::DB::GerenteLocal',
                      { 'foreign.id_local' => 'self.id_local' });

__PACKAGE__->has_many('gerente_atual', 'Fila::Servico::DB::GerenteLocal',
                      { 'foreign.id_local' => 'self.id_local',
                       'foreign.vt_ini' => \"<= NOW()", #"
                       'foreign.vt_fim' => \"> NOW()"}, #"
                      {    'join_type' => 'left' });
__PACKAGE__->has_many('respostas_avaliacao', 'Fila::Servico::DB::RespostaAvaliacaoPraca',
                      {'foreign.id_local' => 'self.id_local'});

__PACKAGE__->has_many('configuracoes_perguntas', 'Fila::Servico::DB::ConfiguracaoPerguntas',
                      { 'foreign.id_local' => 'self.id_local' });
__PACKAGE__->has_many('configuracoes_perguntas_praca', 'Fila::Servico::DB::ConfiguracaoPerguntasPraca',
                      { 'foreign.id_local' => 'self.id_local' });

1;

__END__

=head1 NAME

Local - Praça de atendimento

=head1 DESCRIPTION

Essa é a entidade central do sistema, que relaciona a praça de
atendimento, direta ou indiretamente, todas as outras entidades são
relacionadas a um local.

=cut


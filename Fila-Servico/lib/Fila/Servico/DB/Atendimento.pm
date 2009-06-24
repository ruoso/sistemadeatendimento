package Fila::Servico::DB::Atendimento;
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
__PACKAGE__->table('atendimento');
__PACKAGE__->add_columns
  (
   id_atendimento =>
   {
    data_type => 'integer',
    is_auto_increment => 1,
   },
   vt_ini =>
   {
    data_type => 'timestamp with time zone',
   },
   vt_fim =>
   {
    data_type => 'timestamp with time zone',
   },
   id_local =>
   {
    data_type => 'integer'
   },
   id_senha =>
   {
    data_type => 'integer'
   },
  );


__PACKAGE__->set_primary_key(qw(id_atendimento));
__PACKAGE__->belongs_to('local', 'Fila::Servico::DB::Local',
                        { 'foreign.id_local' => 'self.id_local' });
__PACKAGE__->belongs_to('senha', 'Fila::Servico::DB::Senha',
                        { 'foreign.id_senha' => 'self.id_senha' },
                        { 'join_type' => 'left' });

__PACKAGE__->might_have('agendamento', 'Fila::Servico::DB::Agendamento',
                        { 'foreign.id_atendimento' => 'self.id_atendimento' });

__PACKAGE__->has_many('estados', 'Fila::Servico::DB::EstadoAtendimento',
                      {'foreign.id_atendimento' => 'self.id_atendimento'},
                      { join_type => 'left' });

__PACKAGE__->has_many('estado_atual', 'Fila::Servico::DB::EstadoAtendimento',
                      {'foreign.id_atendimento' => 'self.id_atendimento',
                       'foreign.vt_ini' => \"<= NOW()", #"
                       'foreign.vt_fim' => \"> NOW()"}, #"
                       {'join_type' => 'left' });

__PACKAGE__->has_many('categorias', 'Fila::Servico::DB::CategoriaAtendimento',
                      {'foreign.id_atendimento' => 'self.id_atendimento'},
                      {    'join_type' => 'left' });

__PACKAGE__->has_many('categoria_atual', 'Fila::Servico::DB::CategoriaAtendimento',
                      {'foreign.id_atendimento' => 'self.id_atendimento',
                       'foreign.vt_ini' => \"<= NOW()", #"
                       'foreign.vt_fim' => \"> NOW()"}, #"
                      {    'join_type' => 'left' });

__PACKAGE__->has_many('guiches', 'Fila::Servico::DB::GuicheAtendimento',
                      {'foreign.id_atendimento' => 'self.id_atendimento'});

__PACKAGE__->has_many('guiche_atual', 'Fila::Servico::DB::GuicheAtendimento',
                      {'foreign.id_atendimento' => 'self.id_atendimento',
                       'foreign.vt_ini' => \"<= NOW()", #"
                       'foreign.vt_fim' => \"> NOW()"}, #"
                      {'join_type' => 'left' });

__PACKAGE__->has_many('servicos', 'Fila::Servico::DB::ServicoAtendimento',
                      {'foreign.id_atendimento' => 'self.id_atendimento'});

__PACKAGE__->has_many('servico_atual', 'Fila::Servico::DB::ServicoAtendimento',
                      {'foreign.id_atendimento' => 'self.id_atendimento',
                       'foreign.vt_ini' => \"<= NOW()", #"
                       'foreign.vt_fim' => \"> NOW()"}, #"
                      {'join_type' => 'left' });

__PACKAGE__->has_many('respostas_avaliacao', 'Fila::Servico::DB::RespostaAvaliacao',
                      {'foreign.id_atendimento' => 'self.id_atendimento'});

1;

__END__

=head1 NAME

Atendimento - Entidade central do processo de atendimento

=head1 DESCRIPTION

Essa entidade agrega todas as informações de um atendimento desde o
momento em que a senha é emitida até o momento em que ele registra a
opinião. Praticamente todos os relacionamentos e atributos são
temporais, com a excessão da senha, que é sempre a mesma ao longo de
toda a vida do atendimento.

=cut


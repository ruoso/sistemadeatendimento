package Fila::Servico::DB::Guiche;
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
__PACKAGE__->table('guiche');
__PACKAGE__->add_columns
  (
   id_guiche =>
   {
    data_type => 'integer',
    is_auto_increment => 1
   },
   id_local =>
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
   identificador =>
   {
    data_type => 'char(10)',
   },
   jid_opiniometro =>
   {
    data_type => 'varchar',
   },
   pular_opiniometro =>
   {
    data_type => 'integer',
   }
  );
__PACKAGE__->set_primary_key(qw(id_guiche));
__PACKAGE__->belongs_to('local', 'Fila::Servico::DB::Local',
                        { 'foreign.id_local' => 'self.id_local' });

__PACKAGE__->has_many('categorias', 'Fila::Servico::DB::GuicheCategoria',
		      { 'foreign.id_guiche' => 'self.id_guiche' },
		      { 'join_type' => 'left'});

__PACKAGE__->has_many('categorias_atuais', 'Fila::Servico::DB::GuicheCategoria',
		      { 'foreign.id_guiche' => 'self.id_guiche',
                        'foreign.vt_ini' => \"<= NOW()", #"
                        'foreign.vt_fim' => \"> NOW()", #"
		      },
		      { 'join_type' => 'left'});

__PACKAGE__->has_many('atendimentos', 'Fila::Servico::DB::GuicheAtendimento',
                      { 'foreign.id_guiche' => 'self.id_guiche' },
                      {    'join_type' => 'left' });

__PACKAGE__->has_many('encaminhamentos', 'Fila::Servico::DB::GuicheEncaminhamento',
                      { 'foreign.id_guiche' => 'self.id_guiche' },
                      { 'join_type' => 'left', 'order_by' => 'vt_ini' });

__PACKAGE__->has_many('encaminhamentos_atuais', 'Fila::Servico::DB::GuicheEncaminhamento',
                      { 'foreign.id_guiche' => 'self.id_guiche',
                        'foreign.vt_ini' => \"<= NOW()", #"
                        'foreign.vt_fim' => \"> NOW()", #"
                      },
                      { 'join_type' => 'left', 'order_by' => 'vt_ini' });

__PACKAGE__->has_many('atendimento_atual', 'Fila::Servico::DB::GuicheAtendimento',
                      { 'foreign.id_guiche' => 'self.id_guiche',
                       'foreign.vt_ini' => \"<= NOW()", #"
                       'foreign.vt_fim' => \"> NOW()", #"
                      },
                      {    'join_type' => 'left' });

__PACKAGE__->has_many('estados', 'Fila::Servico::DB::EstadoGuiche',
                      { 'foreign.id_guiche' => 'self.id_guiche' });

__PACKAGE__->has_many('estado_atual', 'Fila::Servico::DB::EstadoGuiche',
                      { 'foreign.id_guiche' => 'self.id_guiche',
                       'foreign.vt_ini' => \"<= NOW()", #"
                       'foreign.vt_fim' => \"> NOW()"}, #"
                      {    'join_type' => 'left'  });

__PACKAGE__->has_many('atendentes', 'Fila::Servico::DB::AtendenteGuiche',
                      { 'foreign.id_guiche' => 'self.id_guiche' });

__PACKAGE__->has_many('atendente_atual', 'Fila::Servico::DB::AtendenteGuiche',
                      { 'foreign.id_guiche' => 'self.id_guiche',
                       'foreign.vt_ini' => \"<= NOW()", #"
                       'foreign.vt_fim' => \"> NOW()"}, #"
                      {    'join_type' => 'left' });

__PACKAGE__->has_many('pausas', 'Fila::Servico::DB::Pausa',
                      { 'foreign.id_guiche' => 'self.id_guiche' });

__PACKAGE__->has_many('pausa_atual', 'Fila::Servico::DB::Pausa',
                      { 'foreign.id_guiche' => 'self.id_guiche',
                       'foreign.vt_ini' => \"<= NOW()", #"
                       'foreign.vt_fim' => \"> NOW()"}, #"
                      {    'join_type' => 'left' });

__PACKAGE__->has_many('servicos', 'Fila::Servico::DB::ServicoGuiche',
                      { 'foreign.id_guiche' => 'self.id_guiche' });

__PACKAGE__->has_many('servico_atual', 'Fila::Servico::DB::ServicoGuiche',
                      { 'foreign.id_guiche' => 'self.id_guiche',
                       'foreign.vt_ini' => \"<= NOW()", #"
                       'foreign.vt_fim' => \"> NOW()"}, #"
                      {    'join_type' => 'left' });
1;

__END__

=head1 NAME

Guiche - Guichê de atendimento

=head1 DESCRIPTION

Esta tabela representa a mesa específica onde são realizados os
atendimentos. Praticamente todos os atributos e relacionamentos são
temporais, com excessão do local, uma vez que um guichê sempre irá
pertencer ao mesmo local.

=cut


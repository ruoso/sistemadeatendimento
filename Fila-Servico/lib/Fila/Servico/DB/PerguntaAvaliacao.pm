package Fila::Servico::DB::PerguntaAvaliacao;
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
__PACKAGE__->table('pergunta_avaliacao');
__PACKAGE__->add_columns
  (
   id_pergunta =>
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
   pergunta =>
   {
    data_type => 'varchar'
   },
  );
__PACKAGE__->set_primary_key(qw(id_pergunta));
__PACKAGE__->has_many('respostas', 'Fila::Servico::DB::RespostaAvaliacao',
                      { 'foreign.id_pergunta' => 'self.id_pergunta' });
__PACKAGE__->belongs_to('configuracoes_perguntas', 'Fila::Servico::DB::ConfiguracaoPerguntas',
                      { 'foreign.id_pergunta' => 'self.id_pergunta' });

1;

__END__

=head1 NAME

PerguntaAvaliacao - Todas as perguntas do opiniometro

=head1 DESCRIPTION

Esta tabela lista todas as perguntas que podem ser configuradas no
opiniometro do guiche.

=cut


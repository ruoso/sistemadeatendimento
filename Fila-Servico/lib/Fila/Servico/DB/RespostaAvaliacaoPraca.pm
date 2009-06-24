package Fila::Servico::DB::RespostaAvaliacaoPraca;
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
__PACKAGE__->table('resposta_avaliacao_praca');
__PACKAGE__->add_columns
  (
   id_pergunta =>
   {
    data_type => 'integer',
   },
   id_local =>
   {
    data_type => 'integer',
   },
   vt_fac =>
   {
    data_type => 'timestamp with time zone',
   },
   resposta =>
   {
    data_type => 'integer'
   },
  );
__PACKAGE__->set_primary_key(qw(id_pergunta id_local vt_fac));
__PACKAGE__->belongs_to('local', 'Fila::Servico::DB::Local',
                        { 'foreign.id_local' => 'self.id_local' });
__PACKAGE__->belongs_to('pergunta', 'Fila::Servico::DB::PerguntaAvaliacaoPraca',
                        { 'foreign.id_pergunta' => 'self.id_pergunta' });

1;

__END__

=head1 NAME

RespostaAvaliacaoPraca - Registro dos preenchimentos no opiniometro geral

=head1 DESCRIPTION

Esta tabela contém o registro temporal de todas as avaliações gerais
da praça realizadas.

=cut


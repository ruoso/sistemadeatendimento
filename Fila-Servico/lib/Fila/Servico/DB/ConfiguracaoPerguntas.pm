package Fila::Servico::DB::ConfiguracaoPerguntas;
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
__PACKAGE__->table('configuracao_perguntas');
__PACKAGE__->add_columns
  (
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
   pergunta1 =>
   {
    data_type => 'integer'
   },
   pergunta2 =>
   {
    data_type => 'integer'
   },
   pergunta3 =>
   {
    data_type => 'integer'
   },
   pergunta4 =>
   {
    data_type => 'integer'
   },
   pergunta5 =>
   {
    data_type => 'integer'
   },
  );
__PACKAGE__->set_primary_key(qw(id_local vt_fim vt_ini));
__PACKAGE__->belongs_to('local', 'Fila::Servico::DB::Local',
                        { 'foreign.id_local' => 'self.id_local' });
__PACKAGE__->belongs_to('pergunta1', 'Fila::Servico::DB::PerguntaAvaliacao',
                        { 'foreign.id_pergunta' => 'self.pergunta1' });
__PACKAGE__->belongs_to('pergunta2', 'Fila::Servico::DB::PerguntaAvaliacao',
                        { 'foreign.id_pergunta' => 'self.pergunta2' });
__PACKAGE__->belongs_to('pergunta3', 'Fila::Servico::DB::PerguntaAvaliacao',
                        { 'foreign.id_pergunta' => 'self.pergunta3' });
__PACKAGE__->belongs_to('pergunta4', 'Fila::Servico::DB::PerguntaAvaliacao',
                        { 'foreign.id_pergunta' => 'self.pergunta4' });
__PACKAGE__->belongs_to('pergunta5', 'Fila::Servico::DB::PerguntaAvaliacao',
                        { 'foreign.id_pergunta' => 'self.pergunta5' });

1;

__END__

=head1 NAME

ConfiguracaoPerguntas - Configuração das perguntas do opiniometro do atendimento

=head1 DESCRIPTION

Essa tabela guarda o registro temporal das configurações das perguntas
nos opiniometros dos atendimentos.

=cut


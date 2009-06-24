package Fila::Servico::DB::Categoria;
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
__PACKAGE__->table('categoria');
__PACKAGE__->add_columns
  (
   id_categoria =>
   {
    data_type => 'integer',
    is_auto_increment => 1,
   },
   nome =>
   {
    data_type => 'varchar',
   },
   codigo =>
   {
    data_type => 'char(1)',
   },
  );
__PACKAGE__->set_primary_key(qw(id_categoria));
__PACKAGE__->has_many('atendimentos', 'Fila::Servico::DB::CategoriaAtendimento',
                      {'foreign.id_categoria' => 'self.id_categoria'},
                      { join_type => 'left' });

__PACKAGE__->has_many('atendimentos_atuais', 'Fila::Servico::DB::CategoriaAtendimento',
                      {'foreign.id_categoria' => 'self.id_categoria',
                       'foreign.vt_ini' => \"<= NOW()", #"
                       'foreign.vt_fim' => \"> NOW()"}, #"
                      { join_type => 'left' });

__PACKAGE__->has_many('senhas', 'Fila::Servico::DB::Senha',
                      {'foreign.id_categoria' => 'self.id_categoria'});

__PACKAGE__->has_many('configuracoes', 'Fila::Servico::DB::ConfiguracaoCategoria',
                      {'foreign.id_categoria' => 'self.id_categoria'});

__PACKAGE__->has_many('configuracoes_atuais', 'Fila::Servico::DB::ConfiguracaoCategoria',
                      {'foreign.id_categoria' => 'self.id_categoria',
                       'foreign.vt_ini' => \"<= NOW()", #"
                       'foreign.vt_fim' => \"> NOW()"}, #"
                      { join_type => 'left' });
1;

__END__

=head1 NAME

Categoria - Lista as categorias de atendimento

=head1 DESCRIPTION

Esta tabela lista todas as categorias passíveis de fazer parte do
processo de atendimento, mas a configuração efetiva dessas categorias
no contexto do local acontece na tabela ConfiguracaoCategoria.

=cut


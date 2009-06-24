package Fila::Servico::DB::ConfiguracaoCategoria;
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
__PACKAGE__->table('configuracao_categoria');
__PACKAGE__->add_columns
  (
   id_local =>
   {
    data_type => 'integer',
   },
   id_categoria =>
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
   prioridade =>
   {
    data_type => 'integer'
   },
   limite_tempo_espera =>
   {
    data_type => 'integer'
   },
   limite_pessoas_espera =>
   {
    data_type => 'integer'
   },
   ordem =>
   {
    data_type => 'integer'
   }
  );
__PACKAGE__->set_primary_key(qw(id_local id_categoria vt_ini vt_fim));
__PACKAGE__->belongs_to('local', 'Fila::Servico::DB::Local',
                        { 'foreign.id_local' => 'self.id_local' });
__PACKAGE__->belongs_to('categoria', 'Fila::Servico::DB::Categoria',
                        { 'foreign.id_categoria' => 'self.id_categoria' },
				  	    { join_type => 'left' });

1;

__END__

=head1 NAME

ConfiguracaoCategoria - Configuração de uma categoria em um local

=head1 DESCRIPTION

Essa tabela define a configuração de uma categoria na praça, incluindo
questões como a posição dessa categoria no equipamento emissor de
senhas, a prioridade dessa categoria para a chamada das senhas e
limites para alerta.

=cut


package Fila::Servico::DB::Senha;
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
__PACKAGE__->table('senha');
__PACKAGE__->add_columns
  (
   id_senha =>
   {
    data_type => 'integer',
    is_auto_increment => 1
   },
   id_categoria =>
   {
    data_type => 'integer',
   },
   id_local =>
   {
    data_type => 'integer',
   },
   codigo =>
   {
    data_type => 'integer',
   },
  );
__PACKAGE__->set_primary_key(qw(id_senha));
__PACKAGE__->belongs_to('local', 'Fila::Servico::DB::Local',
                        { 'foreign.id_local' => 'self.id_local' });
__PACKAGE__->belongs_to('categoria', 'Fila::Servico::DB::Categoria',
                        { 'foreign.id_categoria' => 'self.id_categoria' });
__PACKAGE__->has_many('atendimentos', 'Fila::Servico::DB::Atendimento',
                      { 'foreign.id_senha' => 'self.id_senha' });

1;

__END__

=head1 NAME

Senha - Representação do identificador visível do atendimento

=head1 DESCRIPTION

Apesar da senha ser o identificador visível do atendimento, a senha é
reutilizada ao longo do tempo, mas a associação entre senha e
atendimento não é temporal, o que significa que um atendimento mantém
o identificador visível do início ao fim. O sistema deve garantir que
dois atendimentos não estão associados à mesma senha ao mesmo tempo.

=cut


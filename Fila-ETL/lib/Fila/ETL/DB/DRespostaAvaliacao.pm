package Fila::ETL::DB::DRespostaAvaliacao;
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

use strict;
use warnings;
use base qw(DBIx::Class);

__PACKAGE__->load_components(qw(Core PK::Auto));
__PACKAGE__->table('d_resposta_avaliacao');
__PACKAGE__->add_columns
  (
   id_resposta =>
   {
    data_type => 'integer',
    is_auto_increment => 1
   },
   valor =>
   {
    data_type => "varchar"
   }
  );

__PACKAGE__->set_primary_key('id_resposta');
__PACKAGE__->resultset_class('Fila::ETL::DB::DRespostaAvaliacao::RS');

package Fila::ETL::DB::DRespostaAvaliacao::RS;
use base 'DBIx::Class::ResultSet';

sub get_dimension {
    my ($self, $resposta) = @_;
    my $valor = (qw(otimo bom regular ruim))[$resposta - 1];
    if (my $dim = $self->find({ id_resposta => $resposta })) {
	return $resposta;
    } else {
	return $self->create
          ({ valor => $valor, id_resposta => $resposta })->id_resposta;
    }
}

1;

__END__

=head1 NAME

DRespostaAvaliacao - Tabela da dimensão "Resposta Avaliacao"

=head1 SYNOPSIS

Essa tabela lista todas as entradas da dimensão "Resposta Avaliacao".

=cut

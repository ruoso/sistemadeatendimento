package Fila::ETL::DB::DCategoria;
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
__PACKAGE__->table('d_categoria');
__PACKAGE__->add_columns
  (
   id_categoria =>
   {
    data_type => 'integer',
    is_auto_increment => 1
   },
   nome =>
   {
    data_type => 'varchar',
    is_nullable => 1,
   },
   codigo =>
   {
    data_type => 'varchar',
    is_nullable => 1,
   },
   prioritaria =>
   {
    data_type => 'boolean',
    is_nullable => 1,
   }
  );

__PACKAGE__->set_primary_key('id_categoria');
__PACKAGE__->resultset_class('Fila::ETL::DB::DCategoria::RS');

package Fila::ETL::DB::DCategoria::RS;
use base 'DBIx::Class::ResultSet';


sub get_dimension {
  my ($self, $categoria) = @_;
  my ($codigo, $nome);
  if (ref $categoria eq 'HASH') {
    $codigo = $categoria->{codigo};
    $nome = $categoria->{nome};
  } else {
    $codigo = $categoria->{codigo};
    $nome = $categoria->nome;
  }
  if (my $dim = $self->find({ nome => $nome })) {
    return $dim->id_categoria;
  } else {
    # Aqui vamos presumir que se a categoria tem "preferencial" ou
    # "prioritaria" no nome, ela é prioritária, senão ela é normal.
    return $self->create
      ({ nome => $nome,
	 codigo => $codigo,
	 prioritaria => $nome =~ /(prefer|priorit)/i ? 1 : 0
       })->id_categoria;
  }
}


1;

__END__

=head1 NAME

DCategoria - Tabela da dimensão "Categoria"

=head1 SYNOPSIS

Essa tabela lista todas as entradas da dimensão "Categoria".

=cut

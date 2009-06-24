package Fila::ETL::DB::DGuiche;
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
__PACKAGE__->table('d_guiche');
__PACKAGE__->add_columns
  (
   id_guiche =>
   {
    data_type => 'integer',
    is_auto_increment => 1
   },
   identificador =>
   {
    data_type => 'varchar',
    is_nullable => 1,
   }
  );

__PACKAGE__->set_primary_key('id_guiche');
__PACKAGE__->resultset_class('Fila::ETL::DB::DGuiche::RS');

package Fila::ETL::DB::DGuiche::RS;
use base 'DBIx::Class::ResultSet';


sub get_dimension {
    my ($self, $guiche) = @_;
    my $ident = $guiche->identificador;
    if (my $dim = $self->find({ identificador => $ident })) {
	return $dim->id_guiche;
    } else {
	# TODO: Aqui deveríamos ter um conjunto maior de informações
	# sobre o guichê, como por exemplo, a distância entre o guichê
	# e a porta, a distância entre o guichê e a cadeira mais
	# próxima, a distância entre o guichê e a cadeira mais longe
	# para que pudéssemos obter mais informações. Por enquanto,
	# consolidamos apenas no número do guichê.
	return $self->create
	    ({ identificador => $ident ? $ident : '' })->id_guiche;
    }
}

1;

__END__

=head1 NAME

DGuiche - Tabela da dimensão "Guiche"

=head1 SYNOPSIS

Essa tabela lista todas as entradas da dimensão "Guiche".

=cut

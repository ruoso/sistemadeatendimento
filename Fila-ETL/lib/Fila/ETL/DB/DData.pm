package Fila::ETL::DB::DData;
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
__PACKAGE__->table('d_data');
__PACKAGE__->add_columns
  (
   data =>
   {
    data_type => 'char(10)',
   },
   ano =>
   {
    data_type => 'integer',
    is_nullable => 1,
   },
   mes =>
   {
    data_type => 'integer',
    is_nullable => 1,
   },
   dia =>
   {
    data_type => 'integer',
    is_nullable => 1,
   },
   diasemana =>
   {
    data_type => 'integer',
    is_nullable => 1,
   }
  );

__PACKAGE__->set_primary_key('data');
__PACKAGE__->resultset_class('Fila::ETL::DB::DData::RS');

package Fila::ETL::DB::DData::RS;
use base 'DBIx::Class::ResultSet';


sub get_dimension {
    my ($self, $date) = @_;
    my $result = $self->find({ ano => $date->year,
			       mes => $date->month,
			       dia => $date->day });
    if ($result) {
	return $result->data;
    } else {
	return $self->create
	    ({ data => $date->strftime('%F'),
	       ano => $date->year,
	       mes => $date->month,
	       dia => $date->day,
	       diasemana => $date->day_of_week })->data;
    }
}

1;

__END__

=head1 NAME

DData - Tabela da dimensão "Data"

=head1 SYNOPSIS

Essa tabela lista todas as entradas da dimensão "Data".

=cut

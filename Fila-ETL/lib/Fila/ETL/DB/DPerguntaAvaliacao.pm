package Fila::ETL::DB::DPerguntaAvaliacao;
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
__PACKAGE__->table('d_pergunta_avaliacao');
__PACKAGE__->add_columns
  (
   id_pergunta =>
   {
    data_type => 'integer',
    is_auto_increment => 1
   },
   texto =>
   {
    data_type => 'varchar',
    is_nullable => 1,
   }
  );

__PACKAGE__->set_primary_key('id_pergunta');
__PACKAGE__->resultset_class('Fila::ETL::DB::DAtendente::RS');

package Fila::ETL::DB::DPerguntaAvaliacao::RS;
use base 'DBIx::Class::ResultSet';

sub get_dimension {
    my ($self, $pergunta) = @_;
    my $texto = $pergunta->pergunta;
    if (my $dim = $self->find({ texto => $texto })) {
	return $dim->id_pergunta;
    } else {
	# TODO: Obter isso de um lugar mais inteligente;
	return $self->create
          ({ texto => $pergunta->pergunta })->id_pergunta;
    }
}

1;

__END__

=head1 NAME

DPerguntaAvaliacao - Tabela da dimensão "Pergunta Avaliacao"

=head1 SYNOPSIS

Essa tabela lista todas as entradas da dimensão "Pergunta Avaliacao".

=cut

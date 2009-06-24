package Fila::Agendamento::DB::Local;
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

use DateTime;
use base qw(DBIx::Class);

__PACKAGE__->load_components(qw(InflateColumn::DateTime PK::Auto Core));
__PACKAGE__->table('local');
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
    data_type => 'timestamp with time zone'
   },
   nome =>
   {
    data_type => 'varchar',
   },
  );
__PACKAGE__->set_primary_key(qw(id_local));

__PACKAGE__->has_many('atendimentos', 'Fila::Agendamento::DB::Atendimento',
                      { 'foreign.id_local' => 'self.id_local' });

__PACKAGE__->has_many('expedientes', 'Fila::Agendamento::DB::Expediente',
                      { 'foreign.id_local' => 'self.id_local' });

__PACKAGE__->has_many('feriados', 'Fila::Agendamento::DB::Feriado',
                      { 'foreign.id_local' => 'self.id_local' });


sub obter_grid {
    my ($self, $clean) = @_;

    my $sql = <<EOF;
SELECT
 DATE(date_trunc('day', i.inicio)) AS dia,
 i.inicio - date_trunc('day',i.inicio) AS hora,
 COUNT(e.*) AS expedientes,
 COUNT(a.*) AS atendimentos
FROM intervalos i
LEFT JOIN local l
ON (l.id_local=?)
LEFT JOIN feriado f
ON (date_trunc('day', i.inicio) = f.data
    AND f.id_local=l.id_local)
LEFT JOIN expediente e
ON (extract('dow' FROM i.inicio) = dia_semana
    AND extract('hour' FROM i.inicio) >= e.hora_inicio
    AND extract('hour' FROM i.inicio) <= e.hora_fim - 1
    AND e.id_local=l.id_local AND f.id_local IS NULL)
LEFT JOIN atendimento a
ON (a.id_local = l.id_local
    AND a.data >= i.inicio
    AND a.data < i.fim)
WHERE i.inicio < DATE_TRUNC('day',NOW()) + interval '10 days'
GROUP BY l.id_local, l.nome, i.inicio
ORDER BY hora, dia;
EOF

    my $storage = $self->result_source->storage;
    $storage->ensure_connected();
    my $sth = $storage->sth($sql);
    $sth->execute($self->id_local);

    my $grid;
    while (my ($dia, $hora, $exp, $at) = $sth->fetchrow_array) {

        $hora =~ s/\:..$//;

        $grid ||=
          { dias => {},
            horas => {} };
        my $info = $exp ? ( $at ? 'Ocupado' : 'Livre' ) : 'Indisp';
        $grid->{dias}{$dia}{$hora} = $info;
        $grid->{horas}{$hora}{$dia} = $info;
    }

    my $horas = $grid->{horas};
    if ($clean) {
        $horas =
          { map { $_ => $grid->{horas}{$_} }
            grep {
                my $hora = $_;
                grep { $grid->{horas}{$hora}{$_} !~ /Indisp/ }
                  keys %{$grid->{horas}{$hora}}
              }
            keys %{$grid->{horas}} };
    }
    $grid->{horas} = $horas;

    $grid->{idx_horas} = [ sort keys %{$grid->{horas}} ];
    $grid->{idx_dias} = [ sort keys %{$grid->{dias}} ];
    $grid->{dow_dias} = [ map {
        my ($a,$m,$d) = split /-/, $_;
        my $dt = DateTime->new(year => $a,
                               month => $m,
                               day => $d,
                               locale => 'pt_BR');
    } @{$grid->{idx_dias}} ];

    return $grid;
}

1;

__END__

=head1 NAME

Local - Define cada local para agendamento

=head1 DESCRIPTION

Cada local de agendamento deve ter o seu registro, e é através dessa
entidade que é montada a grelha dos horários livres ou ocupados que é
exibida na interface.

=cut


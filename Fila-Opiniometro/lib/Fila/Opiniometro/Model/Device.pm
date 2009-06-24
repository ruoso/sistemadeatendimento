package Fila::Opiniometro::Model::Device;
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
use EV;
use IO::Handle;
use POSIX qw(:termios_h);
use base 'Catalyst::Model';

__PACKAGE__->mk_accessors('fh', 'read_buffer', 'write_buffer');

our ($read_watcher, $write_watcher);

sub encerrar {
    my $self = shift;

    if ($Fila::Opiniometro::porta_opiniometro eq 'emulate') {
        warn 'Desligar Opiniometro!'.$/;
        $self->_check_emulate_watcher();
    } else {
        $self->push_write('@OPC.');
    }
}

sub iniciar {
    my $self = shift;

    if ($Fila::Opiniometro::porta_opiniometro eq 'emulate') {
        warn 'Iniciar Opiniometro!'.$/;
        $self->_check_emulate_watcher();
    } else {
        $self->push_write('@OPI'.$Fila::Opiniometro::timeout.'.');
    }
}

sub push_write {
    my ($self, $buf) = @_;

    $self->write_buffer
      (($self->write_buffer()||'').
       $buf);

    $self->_check_fh;
    $self->_check_wb;
}

sub _check_fh {
    my $self = shift;

    return if $self->fh;

    open my $fh, '+<', $Fila::Opiniometro::porta_opiniometro
      or do {
          warn 'Erro abrindo porta do emissor: '.$!;
          EV::unloop(EV::UNLOOP_ALL);
          die 'Erro abrindo porta do emissor: '.$!;
      };

    $fh->blocking(0);

    my $term = POSIX::Termios->new;
    $term->getattr(fileno($fh)) or die $!;

    $term->setiflag( $term->getiflag & ( &POSIX::IGNBRK | &POSIX::IGNPAR & ~&POSIX::INPCK & ~ &POSIX::IXON & ~ &POSIX::IXOFF));
    $term->setlflag( $term->getlflag & ~( &POSIX::ICANON | &POSIX::ECHO | &POSIX::ECHONL | &POSIX::ISIG | &POSIX::IEXTEN ));
    $term->setcflag( $term->getcflag & ( &POSIX::CSIZE | &POSIX::CS8 & ~&POSIX::PARENB));

    $term->setospeed(&POSIX::B1200);
    $term->setispeed(&POSIX::B1200);

    $term->setattr(fileno($fh), &POSIX::TCSANOW) or die $!;

    $self->fh($fh);

    $read_watcher = EV::io $fh, EV::READ, sub {
        my $buf;
        while (my $ret = $fh->sysread($buf, '100')) {
            $self->push_read($buf);
        }
    };
}

sub _check_emulate_watcher {
    my $self = shift;
    STDIN->blocking(0);
    $read_watcher = EV::io \*STDIN, EV::READ, sub {
        my $buf;
        while (my $ret = STDIN->sysread($buf, '100')) {
            warn 'Read '.$ret.' bytes ('.$buf.')';
            $self->push_read($buf);
        }
    };
}

sub _check_wb {
    my $self = shift;

    return if $write_watcher || !$self->write_buffer;

    $write_watcher = EV::io $self->fh, EV::WRITE, sub {
        use bytes;
        my $buf = $self->write_buffer;
        my $len = length $buf;
        my $wrt = $self->fh->syswrite($buf, $len);
        my $wrote = substr($buf,0,$wrt,'');
        warn 'Wrote '.$wrt.' bytes ('.$wrote.')';
        $self->write_buffer($buf);
        $write_watcher = undef unless $buf;
    };
}

sub push_read {
    my ($self, $buf) = @_;

    $self->read_buffer
      (($self->read_buffer()||'').
       $buf);

    $self->_check_rb;
}

sub _check_rb {
    my $self = shift;

    my $buf = $self->read_buffer;
    return unless $buf;
    return unless length $buf >= 5;

    while ($buf) {
        if (substr($buf,0,1) ne '@') {
            my $pos = index $buf, '@';
            if ($pos < 0) {
                warn 'Disarding bad read buffer ('.$buf.')';
                $self->read_buffer('');
                return;
            } else {
                my $bad = substr($buf,0,$pos-1,'');
                warn 'Discaring bad read buffer ('.$bad.')';
            }
        } elsif ($buf =~ s/^\@OPK.//) {
            # ok...
        } elsif ($buf =~ /^\@\d/) {
            last if length $buf < 7;
            my $cmd = substr($buf,0,7,'');
            my $respostas =
              [ map { { id_pergunta => $_->[0], resposta => $_->[1] } }
                map { [ $Fila::Opiniometro::perguntas->[$_] => substr($cmd,1+$_,1) ] }
                0..4 ];

			my $dados;
			if ($::praca && $::praca == 1) {
	            $dados = Fila::Opiniometro->model('SOAP::Opiniometro')->registrar_avaliacao_praca
	              ({ avaliacao_atendimento => { resposta => $respostas } });
			} else {
	            $dados = Fila::Opiniometro->model('SOAP::Opiniometro')->registrar_avaliacao
	              ({ avaliacao_atendimento => { resposta => $respostas } });
			}

            if ($dados->{Fault}) {
                warn 'Erro ao enviar avaliacao. '.$dados->{Fault}{faultstring};
            }
			if ($::praca && $::praca == 1) {
				sleep 5;
				$self->iniciar;
			} else {
                $self->encerrar;
            }

        } else {
            substr $buf, 0, 1, '';
            last;
        }
    }

    $self->read_buffer($buf);

}

1;

__END__

=head1 NAME

Device - Esse módulo implementa a comunicação com o aparelho
opiniometro

=head1 DESCRIPTION

Este módulo implementa a comunicação com o aparelho opiniometro,
utilizando o seguinte protocolo (> para escrita e < para leitura):

  # Inicia o opiniometro, deixando 5 segundos de
  # tempo para o usuario responder cada pergunta
  > @OPI5.
  # Sucesso
  < @OPK.
  # Falha
  < @OPE.
  # Registra a informação do voto
  < @12343.

=cut


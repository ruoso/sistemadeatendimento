package Fila::Senha::Model::Emissor;
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
# Fundação do Software Livre(FSF) Inc., 51 Franklin St, Fifth Floor

use strict;
use warnings;
use EV;
use IO::Handle;
use POSIX qw(:termios_h);
use base 'Catalyst::Model';

__PACKAGE__->mk_accessors('fh', 'read_buffer', 'write_buffer', 'ids');

our ($read_watcher, $write_watcher);

sub bloquear {
    my $self = shift;

    if ($Fila::Senha::porta_emissor eq 'emulate') {
        warn 'Emissor Bloqueado!'.$/;
    } else {
        $self->push_write('@ESP0000.');
    }
}

my $cats;
sub abrir {
    my $self = shift;

	warn 'Buscando categorias..';
	$cats ||= Fila::Senha->model('SOAP::Senha')->listar_categorias
      ({ local => {} });

	unless ($cats) {
        warn 'Erro buscando categorias.';
        die 'Erro buscando categorias.';
	}

    $self->ids({});

    my $max_ordem = 0;
    foreach my $tmp (@{$cats->{lista_categorias}{categoria}}) {
	$self->ids->{$tmp->{ordem}} = $tmp->{id_categoria};
	$max_ordem = $tmp->{ordem} if $tmp->{ordem} > $max_ordem;
    }

    my $categorias;
    for (1..$max_ordem) {
        $categorias .=
          $self->ids->{$_} ? '1' : '0';
    }

    if ($Fila::Senha::porta_emissor eq 'emulate') {
        warn 'Emissor aberto '.$categorias.'!'.$/;
        $self->_check_emulate_watcher();
    } else {
        warn 'Escrevendo categorias';
        $self->push_write('@ESP'.$categorias.'.');
    }
}

sub push_write {
    warn 'Iniciando push_write '.$_[1];
    my ($self, $buf) = @_;

    $self->write_buffer
      (($self->write_buffer()||'').
       $buf);

    $self->_check_fh;
    $self->_check_wb;
	warn 'Fim push_write';
}

sub _check_fh {
    my $self = shift;

    return if $self->fh;
    return if $Fila::Senha::porta_emissor eq 'emulate';
	
    open my $fh, '+<', $Fila::Senha::porta_emissor
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
}



sub _check_readwatcher {
	my $self = shift;
    $read_watcher ||= EV::io $self->fh, EV::READ, sub {
        my $buf;
        my $ret;
        while ($ret = $self->fh->sysread($buf, '100')) {
            warn 'sysread: '.$buf;
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
            $self->push_read($buf);
        }
    };
}

sub _check_wb {
    my $self = shift;

    return if $write_watcher || !$self->write_buffer;
    return if $Fila::Senha::porta_emissor eq 'emulate';

    $write_watcher = EV::io $self->fh, EV::WRITE, sub {
        use bytes;
        my $buf = $self->write_buffer;
        my $len = length $buf;
        my $wrt = $self->fh->syswrite($buf, $len);
        my $wrote = substr($buf,0,$wrt,'');
        $self->write_buffer($buf);

        warn 'Wrote ('.$wrote.') into device';
        $write_watcher = undef;
        $self->_check_readwatcher unless $buf; 
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
    return unless length $buf >= 2;

    while ($buf) {
        if (substr($buf,0,1) ne '@') {
            my $pos = index $buf, '@';
            if ($pos < 0) {
                warn 'Disarding bad read buffer ('.$buf.')';
                $self->read_buffer('');
                return;
            } else {
                my $bad = substr($buf,0,$pos,'');
                warn 'Discaring bad read buffer ('.$bad.')';
            }
            $self->read_buffer($buf); 
        } elsif ($buf =~ s/^\@ESE.//) {
            warn 'Device error.';
            $self->read_buffer($buf); 
        } elsif ($buf =~ s/^\@ESK.//) {
            # ok...
            warn 'Success sending command.';
            $self->read_buffer($buf); 
        } elsif ($buf =~ /^\@\d*$/) {
            last;
        } elsif ($buf =~ /^\@(\d+)\./) {
            my $cmd = substr($buf,0,2+length($1),'');
            $self->read_buffer($buf);

            $self->push_write('@ESK.');

            my $posicao = index $cmd, '1';
            warn $posicao;
            my $id_categoria = $self->ids->{$posicao};

            my $dados = Fila::Senha->model('SOAP::Senha')->solicitar_senha
              ({ atendimento => { id_categoria => $id_categoria } });
            if ($dados->{Fault}) {
                warn 'Erro ao pedir senha. '.$dados->{Fault}{faultstring};
            } else {
                Fila::Senha->model('Impressora')->imprimir_senha($dados);
            }

            sleep 5;
            $self->fh->close();
            $self->fh(undef);

            $self->abrir;
        } elsif (length $buf < 5) {
            last;
        } else {
            # bad command...
            warn 'Discarding command header, watch for more output.';
            substr($buf,0,1,'');
            $self->read_buffer($buf); 
        }
    }


}

1;

__END__

=head1 NAME

Fila::Senha::Model::Emissor - Comunica com o dispositivo emissor

=head1 DESCRIPTION

Esse módulo implementa o protocolo de comunicação com o emissor de
senhas. O emissor é um dispositivo serial que implementa o seguinte
protocolo (">" representa escrita e "<" representa leitura):

  # Configura o número de botões habilitados.
  > @ESP0000.
  > @ESP1100.

  # Retorno de sucesso
  < @ESK.

  # Retorno de erro
  > @ESE.

=head1 METHODS

=over

=item abrir

Busca a lista de categorias para emissao de senhas e envia para o
emissor o comando para habilitar os botões relacionados.

=item bloquear

Enviar um comando para desabilitar todos os botões do emissor.

=cut


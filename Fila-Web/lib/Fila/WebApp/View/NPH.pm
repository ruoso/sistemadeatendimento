package Fila::WebApp::View::NPH;
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
use base 'Catalyst::View::TT';

__PACKAGE__->config(TEMPLATE_EXTENSION => '.tt',
                    DEFAULT_ENCODING   => 'utf-8',
                    INCLUDE_PATH => [ Fila::WebApp->path_to('root') ]);


# Override desse método para renderizar o template para o STDOUT.
sub process {
    my ( $self, $c ) = @_;

    my $template = $c->stash->{template}
      ||  $c->action . $self->config->{TEMPLATE_EXTENSION};

    unless (defined $template) {
        $c->log->debug('No template specified for rendering') if $c->debug;
        return 0;
    }

    my $output = $self->render($c, $template);

    if (UNIVERSAL::isa($output, 'Template::Exception')) {
        my $error = qq/Couldn't render template "$output"/;
        $c->log->error($error);
        return 0;
    }

    print $output;

    return 1;
}


1;

__END__

=head1 NAME

NPH - Processamento diferenciado para NPH

=head1 DESCRIPTION

Essa classe view tem um processamento diferenciado para funcionar em
NPH, mas é, basicamente, uma subclasse do View::TT.

=cut


package Fila::Servico::Model::SOAP;
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
use XML::CompileX::Transport::SOAPXMPP;
use base 'Catalyst::Model::SOAP';

__PACKAGE__->config->{transport} = XML::CompileX::Transport::SOAPXMPP->new();

__PACKAGE__->register_wsdl
  ({ wsdl => Fila::Servico->path_to('/schemas/FilaWebApp.wsdl'),
     schema => Fila::Servico->path_to('/schemas/fila-servico.xsd') },
   { render_gerente => 'CB::Gerente',
     render_guiche_gerente => 'CB::GuicheGerente',
     render_atendente => 'CB::Atendente',
     render_error => 'CB::Error' });

__PACKAGE__->register_wsdl
  ({ wsdl => Fila::Servico->path_to('/schemas/FilaSenha.wsdl'),
     schema => Fila::Servico->path_to('/schemas/fila-servico.xsd') },
   { FilaSenhaCallback => 'Senha' });

__PACKAGE__->register_wsdl
  ({ wsdl => Fila::Servico->path_to('/schemas/FilaServico.wsdl'),
     schema => Fila::Servico->path_to('/schemas/fila-servico.xsd') },
   { Scheduler => 'Scheduler' });

__PACKAGE__->register_wsdl
  ({ wsdl => Fila::Servico->path_to('/schemas/FilaOpiniometro.wsdl'),
     schema => Fila::Servico->path_to('/schemas/fila-servico.xsd') },
   { FilaOpiniometroCallback => 'Opiniometro' });

__PACKAGE__->register_wsdl
  ({ wsdl => Fila::Servico->path_to('/schemas/FilaPainel.wsdl'),
     schema => Fila::Servico->path_to('/schemas/fila-servico.xsd') },
   { FilaPainelCallback => 'Painel' });

1;

__END__

=head1 NAME

SOAP - Permite o acesso para fazer os "callbacks" aos outros
componentes do sistema

=head1 DESCRIPTION

Este módulo dá acesso aos outros módulos do sistema para que possam
ser realizados os callbacks, de acordo com a necessidade de cada caso.

=cut


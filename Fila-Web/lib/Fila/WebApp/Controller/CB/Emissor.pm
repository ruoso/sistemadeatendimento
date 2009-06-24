package Fila::WebApp::Controller::CB::Emissor;
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
use Encode;
use base 'Catalyst::Controller::SOAP';
use DateTime::Format::XSD;

__PACKAGE__->config->{wsdl} =
  {wsdl => Fila::WebApp->path_to('schemas/FilaWeb.wsdl')};
  
sub solicitar_senha : WSDLPort('FilaWebEmissorCallback') {
	my ($self, $c, $query) = @_;
	
	my $id_categoria = $query->{callback_request}{param}[0]{value};

	$c->model('SOAP')->transport->addrs(['motor@gestao.fila.vhost/ws/gestao/senha']);	
    my $atendimento = $c->model('SOAP::Gestao::Senha')->solicitar_senha({ 
    	atendimento => { 
    	   				 id_categoria => $id_categoria 
    				   } 
    	}
    	);
	
	if ($atendimento) {
		my $senha = $atendimento->{atendimento}{senha};
		$c->stash->{senha} = $senha;
	   	    
	    my $vt_ini = (DateTime::Format::XSD->parse_datetime
                    ($atendimento->{atendimento}{vt_ini})->strftime('%d/%m/%Y %H:%M'));
        
        $c->stash->{vt_ini} = $vt_ini;
	    my $id_atendimento = $atendimento->{atendimento}{id_atendimento};
	    $c->stash->{id_atendimento} = $id_atendimento;
	    $c->stash->{template} = 'render/emissor/receber_senha.tt';
	    $c->forward($c->view());

	} else {
	    $c->stash->{error_message} = $atendimento->{Fault}{faultstring};
	    return $c->forward('/render/error_message');
	}
}
sub sair: WSDLPort('FilaWebEmissorCallback') {
    my ($self, $c, $query) = @_;
	$::connection->disconnect();
}


1;

__END__

=head1 NAME

Emissor - Emissão manual de senhas

=head1 DESCRIPTION

Esse é o controller que implementa a emissão de senhas manual,
comportando-se como o módulo emissor de senhas.

=cut


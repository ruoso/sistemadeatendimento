package Fila::Administracao::Controller::Funcionarios;
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
use parent 'Catalyst::Controller';
use Digest::MD5 qw(md5_hex md5_base64);
  
sub index :Path('') :Args(0) {
    my ($self, $c) = @_;
    $c->stash->{funcionarios} = $c->model('DB::Funcionario')->search
      (
      	{},{
      	'join' 	 => ['local_atual','gerente_atual'],
      	'select' => ['me.id_funcionario','me.nome','me.jid','local_atual.vt_fim','gerente_atual.vt_fim'],
      	'as' 	 => ['id_funcionario', 'nome', 'jid', 'vt_fim','gerente_vt_fim'],
      	'order_by'=> 'nome' }
      );
      #({},
      # { order_by => 'nome' });

}

sub preload :Chained :PathPart('funcionarios') :CaptureArgs(1) {
    my ($self, $c, $id) = @_;

    $c->stash->{funcionario} = $c->model('DB::Funcionario')->find
      ({ id_funcionario => $id }) or die 'Funcionario nao encontrado';
}

sub ver :Chained('preload') :PathPart('') :Args(0) {
    my ($self, $c) = @_;

	$c->stash->{template} = 'funcionarios/ver.tt';
    $c->stash->{locais} =
      $c->stash->{funcionario}->locais->search({},{prefetch => 'local',
                                                   order_by => 'me.vt_ini'});
    $c->stash->{gerentes} =
      $c->stash->{funcionario}->gerentes->search({},{prefetch => 'local',
                                                     order_by => 'me.vt_ini'});

    unless ($c->req->param('submitted')) {
        $c->req->param($_, $c->stash->{funcionario}->$_())
          for qw(nome jid);
    }
}

sub salvar :Chained('preload') :PathPart('salvar') :Args(0) {
    my ($self, $c) = @_;

    unless ($c->req->param('submitted')) {
        $c->res->redirect($c->uri_for('/funcionarios/'.$c->stash->{funcionario}->id_funcionario));
    } else {
    	if ($c->req->param('senha')) {
	    	if ($c->req->param('senha') eq $c->req->param('confirmacao')) {
		        $c->stash->{funcionario}->update
		          ({ nome => $c->req->param('nome'),
		             jid => $c->req->param('jid').'@people.fila.vhost' ,
		             password => md5_hex($c->req->param('senha')) });
		    } else {
		    	$c->stash->{template} = 'funcionarios/ver.tt';
	        	return $c->stash->{error} = "Senhas não conferem";
		    }	
		} else {
	        $c->stash->{funcionario}->update
	          ({ nome => $c->req->param('nome'),
	             jid => $c->req->param('jid').'@people.fila.vhost' });
		}
        $c->res->redirect($c->uri_for('/funcionarios/'));
    }
}

sub criar :Local :Args(0) {
    my ($self, $c) = @_;
    if ($c->req->param('submitted')) {
    	if ($c->req->param('senha') eq $c->req->param('confirmacao')) {
	        $c->model('DB::Funcionario')->create
	          ({ nome => $c->req->param('nome'),
	             jid => $c->req->param('jid').'@people.fila.vhost',
	             password => md5_hex($c->req->param('senha')) });
	        $c->res->redirect($c->uri_for('/funcionarios/'));
        } else {
        	$c->stash->{error} = "Senhas não conferem";
        }
    }
}

sub associar_gerente :Chained('preload') :PathPart('gerente/associar') :Args(0) {
    my ($self, $c) = @_;
    # primeiro testa para ver se o funcionario mencionado está ligado a uma mesa.
	my $guiche_associado = $c->model('DB::AtendenteGuiche')->find
          ({ id_funcionario => $c->stash->{funcionario}->id_funcionario ,
             vt_fim => 'Infinity'});
    if($guiche_associado){
    	$c->stash->{error} = 'Atendente nao pode ser gerente se estiver ligado a uma mesa';
    	$c->forward('/funcionarios/ver');
    } else {
		# para a figura não ter que procurar qual é o gerente atual, a gente sempre
	    # desassocia o gerente atual do local para associar o que ele está pedindo
    	my $local = $c->model('DB::Local')->find
          ({ id_local => $c->req->param('id_local') },
           { join => 'gerentes' })->gerentes->search
           ({ 'gerentes.vt_fim' => 'Infinity' })->update
           ({ vt_fim => DateTime->now(time_zone => 'local') });
	    $c->stash->{funcionario}->gerentes->create
         ({ id_local => $c->req->param('id_local'),
            vt_ini => DateTime->now(time_zone => 'local'),
            vt_fim => 'Infinity' });
    	$c->res->redirect('/funcionarios/'.$c->stash->{funcionario}->id_funcionario );
    }
 }

sub associar_local :Chained('preload') :PathPart('local/associar') :Args(0) {
    my ($self, $c) = @_;
    $c->stash->{funcionario}->locais->create
      ({ id_local => $c->req->param('id_local'),
         vt_ini => DateTime->now(time_zone => 'local'),
         vt_fim => 'Infinity' });
    $c->res->redirect('/funcionarios/'.$c->stash->{funcionario}->id_funcionario);
}

sub desassociar_gerente :Chained('preload') :PathPart('gerente') :Args(1) {
    my ($self, $c, $id_local) = @_;
    $c->stash->{funcionario}->gerentes->search
      ({ id_local => $id_local,
         vt_fim => 'Infinity' })->update
           ({ vt_fim => DateTime->now(time_zone => 'local') });
    $c->res->redirect('/funcionarios/'.$c->stash->{funcionario}->id_funcionario);
}

sub desassociar_local :Chained('preload') :PathPart('local') :Args(1) {
    my ($self, $c, $id_local) = @_;
    $c->stash->{funcionario}->locais->search
      ({ id_local => $id_local,
         vt_fim => 'Infinity' })->update
           ({ vt_fim => DateTime->now(time_zone => 'local') });
    $c->res->redirect('/funcionarios/'.$c->stash->{funcionario}->id_funcionario);
}

1;

__END__

=head1 NAME

Fila::Administracao::Controller::Funcionarios - Gestão dos Funcionários

=head1 DESCRIPTION

Este módulo implementa a administração dos dados dos funcionários,
incluindo a associação aos locais de atendimento e a associação à
função de gerente.

=cut


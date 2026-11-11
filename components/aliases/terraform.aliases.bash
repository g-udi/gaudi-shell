# shellcheck shell=bash
cite about-alias
about-alias 'Aliases for Terraform/OpenTofu'

if _command_exists terraform; then
	_gaudi_terraform_command=terraform
	alias tf='terraform'
elif _command_exists tofu; then
	_gaudi_terraform_command=tofu
	alias tf='tofu'
fi

if [[ -n "${_gaudi_terraform_command:-}" ]]; then
	alias tfa='tf apply'
	alias tfp='tf plan'
	alias tfd='tf destroy'
	alias tfv='tf validate'
	alias tfi='tf init'
	alias tfo='tf output'
	alias tfr='tf refresh'
	alias tfw='tf workspace'
	alias tfae='tf apply -auto-approve'
	alias tfpa='tf plan -out=tfplan && tf apply tfplan'
	alias tfpaf='tf plan -out=tfplan && tf apply -auto-approve tfplan'
fi
unset _gaudi_terraform_command

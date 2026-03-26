# #!/usr/bin/env bats
# # shellcheck shell=bats
# # shellcheck disable=SC2294,SC2004

# load "$GAUDI_TEST_DIRECTORY/helper.bash"

# load "$GAUDI_SHELL/components/completions/bash/gaudi-shell.completions.bash"

# local_setup() {
# 	prepare
# }

# __check_completion() {
# 	# Get the parameters as a single value
# 	COMP_LINE=$*

# 	# Get the parameters as an array
# 	eval set -- "$@"
# 	COMP_WORDS=("$@")

# 	# Index of the cursor in the line
# 	COMP_POINT=${#COMP_LINE}

# 	# Get the last character of the line that was entered
# 	COMP_LAST=$((${COMP_POINT} - 1))

# 	# If the last character was a space...
# 	if [[ ${COMP_LINE:$COMP_LAST} = ' ' ]]; then
# 		# ...then add an empty array item
# 		COMP_WORDS+=('')
# 	fi

# 	# Word index of the last word
# 	COMP_CWORD=$((${#COMP_WORDS[@]} - 1))

# 	# Run the gaudi-shell completion function
# 	_gaudi-shell-comp

# 	# Return the completion output
# 	echo "${COMPREPLY[@]}"
# }

# @test "gaudi-shell completion: ensure that the _gaudi-shell-comp function is available" {
# 	run type -a _gaudi-shell-comp &> /dev/null
# 	assert_success
# }

# @test "gaudi-shell completion: doctor - show options" {

# 	run __check_completion 'gaudi doctor '
# 	assert_line --index 0 "errors warnings all"
# }

# @test "gaudi-shell completion: help - show options" {

# 	run __check_completion 'gaudi help '
# 	assert_line --index 0 "aliases completions migrate plugins update"
# }

# @test "gaudi-shell completion: update - show no options" {

# 	run __check_completion 'gaudi update '
# 	refute_output
# }

# @test "gaudi-shell completion: show options" {

# 	run __check_completion 'gaudi '
# 	assert_line --index 0 "version help doctor reload restart search update backup restore disable enable show"
# }

# @test "gaudi-shell completion: show - show options" {

# 	run __check_completion 'gaudi show '
# 	assert_line --index 0 "aliases completions plugins"
# }

# @test "gaudi-shell completion: disable - show options" {

# 	run __check_completion 'gaudi disable '
# 	assert_line --index 0 "alias completion plugin"
# }

# @test "gaudi-shell completion: disable - show options a" {

# 	run __check_completion 'gaudi disable a'
# 	assert_line --index 0 "alias"
# }

# @test "gaudi-shell completion: disable - provide nothing when atom is not enabled" {

# 	run __check_completion 'gaudi disable alias ato'
# 	refute_output
# }

# @test "gaudi-shell completion: disable - provide all when atom is not enabled" {
# 	run __check_completion 'gaudi disable alias a'
# 	assert_line --index 0 "all"
# }

# # @test "gaudi-shell completion: disable - provide the a* aliases when atom is enabled with the old location and name" {

# #   run gaudi enable alias atom
# #   assert_link_exist $GAUDI_SHELL/components/enabled/150___atom.aliases.bash

# #   run __check_completion 'gaudi disable alias a'
# #   assert_line --index 0 "all atom"
# # }

# # @test "gaudi-shell completion: disable - provide the a* aliases when atom is enabled with the old location and priority-based name" {
# #   ln -s $GAUDI_SHELL/aliases/available/atom.aliases.bash $GAUDI_SHELL/aliases/enabled/150---atom.aliases.bash
# #   assert_link_exist "$GAUDI_SHELL/aliases/enabled/150---atom.aliases.bash"

# #   ln -s $GAUDI_SHELL/completion/available/apm.completion.bash $GAUDI_SHELL/completion/enabled/350---apm.completion.bash
# #   assert_link_exist "$GAUDI_SHELL/completion/enabled/350---apm.completion.bash"

# #   run __check_completion 'gaudi disable alias a'
# #   assert_line --index 0 "all atom"
# # }

# # @test "gaudi-shell completion: disable - provide the a* aliases when atom is enabled with the new location and priority-based name" {
# #   ln -s $GAUDI_SHELL/aliases/available/atom.aliases.bash $GAUDI_SHELL/enabled/150---atom.aliases.bash
# #   assert_link_exist "$GAUDI_SHELL/enabled/150---atom.aliases.bash"

# #   ln -s $GAUDI_SHELL/completion/available/apm.completion.bash $GAUDI_SHELL/enabled/350---apm.completion.bash
# #   assert_link_exist "$GAUDI_SHELL/enabled/350---apm.completion.bash"

# #   run __check_completion 'gaudi disable alias a'
# #   assert_line --index 0 "all atom"
# # }

# # @test "gaudi-shell completion: disable - provide the docker-machine plugin when docker-machine is enabled with the old location and name" {
# #   ln -s $GAUDI_SHELL/aliases/available/docker-compose.aliases.bash $GAUDI_SHELL/aliases/enabled/docker-compose.aliases.bash
# #   assert_link_exist "$GAUDI_SHELL/aliases/enabled/docker-compose.aliases.bash"

# #   ln -s $GAUDI_SHELL/plugins/available/docker-machine.plugin.bash $GAUDI_SHELL/plugins/enabled/docker-machine.plugin.bash
# #   assert_link_exist "$GAUDI_SHELL/plugins/enabled/docker-machine.plugin.bash"

# #   run __check_completion 'gaudi disable plugin docker'
# #   assert_line --index 0 "docker-machine"
# # }

# # @test "gaudi-shell completion: disable - provide the docker-machine plugin when docker-machine is enabled with the old location and priority-based name" {
# #   ln -s $GAUDI_SHELL/aliases/available/docker-compose.aliases.bash $GAUDI_SHELL/aliases/enabled/150---docker-compose.aliases.bash
# #   assert_link_exist "$GAUDI_SHELL/aliases/enabled/150---docker-compose.aliases.bash"

# #   ln -s $GAUDI_SHELL/plugins/available/docker-machine.plugin.bash $GAUDI_SHELL/plugins/enabled/350---docker-machine.plugin.bash
# #   assert_link_exist "$GAUDI_SHELL/plugins/enabled/350---docker-machine.plugin.bash"

# #   run __check_completion 'gaudi disable plugin docker'
# #   assert_line --index 0 "docker-machine"
# # }

# # @test "gaudi-shell completion: disable - provide the docker-machine plugin when docker-machine is enabled with the new location and priority-based name" {
# #   ln -s $GAUDI_SHELL/aliases/available/docker-compose.aliases.bash $GAUDI_SHELL/enabled/150---docker-compose.aliases.bash
# #   assert_link_exist "$GAUDI_SHELL/enabled/150---docker-compose.aliases.bash"

# #   ln -s $GAUDI_SHELL/plugins/available/docker-machine.plugin.bash $GAUDI_SHELL/enabled/350---docker-machine.plugin.bash
# #   assert_link_exist "$GAUDI_SHELL/enabled/350---docker-machine.plugin.bash"

# #   run __check_completion 'gaudi disable plugin docker'
# #   assert_line --index 0 "docker-machine"
# # }

# # @test "gaudi-shell completion: disable - provide the todo.txt-cli aliases when todo plugin is enabled with the old location and name" {
# #   ln -s $GAUDI_SHELL/aliases/available/todo.txt-cli.aliases.bash $GAUDI_SHELL/aliases/enabled/todo.txt-cli.aliases.bash
# #   assert_link_exist "$GAUDI_SHELL/aliases/enabled/todo.txt-cli.aliases.bash"

# #   ln -s $GAUDI_SHELL/plugins/available/todo.plugin.bash $GAUDI_SHELL/plugins/enabled/todo.plugin.bash
# #   assert_link_exist "$GAUDI_SHELL/plugins/enabled/todo.plugin.bash"

# #   run __check_completion 'gaudi disable alias to'
# #   assert_line --index 0 "todo.txt-cli"
# # }

# # @test "gaudi-shell completion: disable - provide the todo.txt-cli aliases when todo plugin is enabled with the old location and priority-based name" {
# #   ln -s $GAUDI_SHELL/aliases/available/todo.txt-cli.aliases.bash $GAUDI_SHELL/aliases/enabled/150---todo.txt-cli.aliases.bash
# #   assert_link_exist "$GAUDI_SHELL/aliases/enabled/150---todo.txt-cli.aliases.bash"

# #   ln -s $GAUDI_SHELL/plugins/available/todo.plugin.bash $GAUDI_SHELL/plugins/enabled/350---todo.plugin.bash
# #   assert_link_exist "$GAUDI_SHELL/plugins/enabled/350---todo.plugin.bash"

# #   run __check_completion 'gaudi disable alias to'
# #   assert_line --index 0 "todo.txt-cli"
# # }

# # @test "gaudi-shell completion: disable - provide the todo.txt-cli aliases when todo plugin is enabled with the new location and priority-based name" {
# #   ln -s $GAUDI_SHELL/aliases/available/todo.txt-cli.aliases.bash $GAUDI_SHELL/enabled/150---todo.txt-cli.aliases.bash
# #   assert_link_exist "$GAUDI_SHELL/enabled/150---todo.txt-cli.aliases.bash"

# #   ln -s $GAUDI_SHELL/plugins/available/todo.plugin.bash $GAUDI_SHELL/enabled/350---todo.plugin.bash
# #   assert_link_exist "$GAUDI_SHELL/enabled/350---todo.plugin.bash"

# #   run __check_completion 'gaudi disable alias to'
# #   assert_line --index 0 "todo.txt-cli"
# # }

# # @test "gaudi-shell completion: enable - show options" {
# #   run __check_completion 'gaudi enable '
# #   assert_line --index 0 "alias completion plugin"
# # }

# # @test "gaudi-shell completion: enable - show options a" {
# #   run __check_completion 'gaudi enable a'
# #   assert_line --index 0 "alias"
# # }

# # @test "gaudi-shell completion: enable - provide the atom aliases when not enabled" {
# #   run __check_completion 'gaudi enable alias ato'
# #   assert_line --index 0 "atom"
# # }

# # @test "gaudi-shell completion: enable - provide the a* aliases when not enabled" {
# #   run __check_completion 'gaudi enable alias a'
# #   assert_line --index 0 "all ag ansible applications apt atom"
# # }

# # @test "gaudi-shell completion: enable - provide the a* aliases when atom is enabled with the old location and name" {
# #   ln -s $GAUDI_SHELL/aliases/available/atom.aliases.bash $GAUDI_SHELL/aliases/enabled/atom.aliases.bash
# #   assert_link_exist "$GAUDI_SHELL/aliases/enabled/atom.aliases.bash"

# #   run __check_completion 'gaudi enable alias a'
# #   assert_line --index 0 "all ag ansible applications apt"
# # }

# # @test "gaudi-shell completion: enable - provide the a* aliases when atom is enabled with the old location and priority-based name" {
# #   ln -s $GAUDI_SHELL/aliases/available/atom.aliases.bash $GAUDI_SHELL/aliases/enabled/150---atom.aliases.bash
# #   assert_link_exist "$GAUDI_SHELL/aliases/enabled/150---atom.aliases.bash"

# #   run __check_completion 'gaudi enable alias a'
# #   assert_line --index 0 "all ag ansible applications apt"
# # }

# # @test "gaudi-shell completion: enable - provide the a* aliases when atom is enabled with the new location and priority-based name" {
# #   ln -s $GAUDI_SHELL/aliases/available/atom.aliases.bash $GAUDI_SHELL/enabled/150---atom.aliases.bash
# #   assert_link_exist "$GAUDI_SHELL/enabled/150---atom.aliases.bash"

# #   run __check_completion 'gaudi enable alias a'
# #   assert_line --index 0 "all ag ansible applications apt"
# # }

# # @test "gaudi-shell completion: enable - provide the docker-* plugins when nothing is enabled with the old location and name" {
# #   ln -s $GAUDI_SHELL/aliases/available/docker-compose.aliases.bash $GAUDI_SHELL/aliases/enabled/docker-compose.aliases.bash
# #   assert_link_exist "$GAUDI_SHELL/aliases/enabled/docker-compose.aliases.bash"

# #   run __check_completion 'gaudi enable plugin docker'
# #   assert_line --index 0 "docker-compose docker-machine docker"
# # }

# # @test "gaudi-shell completion: enable - provide the docker-* plugins when nothing is enabled with the old location and priority-based name" {
# #   ln -s $GAUDI_SHELL/aliases/available/docker-compose.aliases.bash $GAUDI_SHELL/aliases/enabled/150---docker-compose.aliases.bash
# #   assert_link_exist "$GAUDI_SHELL/aliases/enabled/150---docker-compose.aliases.bash"

# #   run __check_completion 'gaudi enable plugin docker'
# #   assert_line --index 0 "docker-compose docker-machine docker"
# # }

# # @test "gaudi-shell completion: enable - provide the docker-* plugins when nothing is enabled with the new location and priority-based name" {
# #   ln -s $GAUDI_SHELL/aliases/available/docker-compose.aliases.bash $GAUDI_SHELL/enabled/150---docker-compose.aliases.bash
# #   assert_link_exist "$GAUDI_SHELL/enabled/150---docker-compose.aliases.bash"

# #   run __check_completion 'gaudi enable plugin docker'
# #   assert_line --index 0 "docker-compose docker-machine docker"
# # }

# # @test "gaudi-shell completion: enable - provide the docker-* completions when nothing is enabled with the old location and name" {
# #   ln -s $GAUDI_SHELL/aliases/available/docker-compose.aliases.bash $GAUDI_SHELL/aliases/enabled/docker-compose.aliases.bash
# #   assert_link_exist "$GAUDI_SHELL/aliases/enabled/docker-compose.aliases.bash"

# #   run __check_completion 'gaudi enable completion docker'
# #   assert_line --index 0 "docker docker-compose docker-machine"
# # }

# # @test "gaudi-shell completion: enable - provide the docker-* completions when nothing is enabled with the old location and priority-based name" {
# #   ln -s $GAUDI_SHELL/aliases/available/docker-compose.aliases.bash $GAUDI_SHELL/aliases/enabled/150---docker-compose.aliases.bash
# #   assert_link_exist "$GAUDI_SHELL/aliases/enabled/150---docker-compose.aliases.bash"

# #   run __check_completion 'gaudi enable completion docker'
# #   assert_line --index 0 "docker docker-compose docker-machine"
# # }

# # @test "gaudi-shell completion: enable - provide the docker-* completions when nothing is enabled with the new location and priority-based name" {
# #   ln -s $GAUDI_SHELL/aliases/available/docker-compose.aliases.bash $GAUDI_SHELL/enabled/150---docker-compose.aliases.bash
# #   assert_link_exist "$GAUDI_SHELL/enabled/150---docker-compose.aliases.bash"

# #   run __check_completion 'gaudi enable completion docker'
# #   assert_line --index 0 "docker docker-compose docker-machine"
# # }

# # @test "gaudi-shell completion: enable - provide the todo.txt-cli aliases when todo plugin is enabled with the old location and name" {
# #   ln -s $GAUDI_SHELL/plugins/available/todo.plugin.bash $GAUDI_SHELL/plugins/enabled/todo.plugin.bash
# #   assert_link_exist "$GAUDI_SHELL/plugins/enabled/todo.plugin.bash"

# #   run __check_completion 'gaudi enable alias to'
# #   assert_line --index 0 "todo.txt-cli"
# # }

# # @test "gaudi-shell completion: enable - provide the todo.txt-cli aliases when todo plugin is enabled with the old location and priority-based name" {
# #   ln -s $GAUDI_SHELL/plugins/available/todo.plugin.bash $GAUDI_SHELL/plugins/enabled/350---todo.plugin.bash
# #   assert_link_exist "$GAUDI_SHELL/plugins/enabled/350---todo.plugin.bash"

# #   run __check_completion 'gaudi enable alias to'
# #   assert_line --index 0 "todo.txt-cli"
# # }

# # @test "gaudi-shell completion: enable - provide the todo.txt-cli aliases when todo plugin is enabled with the new location and priority-based name" {
# #   ln -s $GAUDI_SHELL/plugins/available/todo.plugin.bash $GAUDI_SHELL/enabled/350---todo.plugin.bash
# #   assert_link_exist "$GAUDI_SHELL/enabled/350---todo.plugin.bash"

# #   run __check_completion 'gaudi enable alias to'
# #   assert_line --index 0 "todo.txt-cli"
# # }

#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck disable=SC2207,SC2059

# @function _gaudi-shell-search
# @description  returns list of aliases, plugins and completions in gaudi-shell
#               name or description should match one of the search terms provided as arguments
# @usage:
#    ❯ gshell search [-|@]term1 [-|@]term2 ... \
#       [[ --enable ]] \
#       [[ --disable ]] \
#       [[ --plugin     | -p ]] \
#       [[ --alias      | -a ]] \
#       [[ --completion | -c ]] \
#       [[ --no-color   | -x ]] \
#       [[ --refresh    | -r ]] \
#       [[ --help       | -h ]]
#
#    Single dash, as in "-chruby", indicates a negative search term.
#    Double dash indicates a command that is to be applied to the search result
#    (--enable and --disable have no short form).
#    An '@' sign indicates an exact (not partial) match.
#
# @example
#    ❯ gshell search ruby rbenv rvm gem rake
#          aliases:  bundler
#          plugins:  chruby rbenv ruby rvm
#      completions:  gem rake rvm
#
#    ❯ gshell search ruby rbenv rvm gem rake -chruby
#          aliases:  bundler
#          plugins:  rbenv ruby rvm
#      completions:  gem rake rvm
#
# Examples of enabling or disabling results of the search:
#
#    ❯ gshell search ruby
#          aliases:  bundler
#          plugins:  chruby chruby-auto ruby
#
#    ❯ gshell search ruby -chruby --enable
#          aliases:  bundler
#          plugins:  ruby
#
# Examples of using exact match:
#
#    ❯ gshell search @git @ruby
#          aliases:  git
#          plugins:  git ruby
#      completions:  git
#

_gaudi-shell-search() {
	local GAUDI_SHELL_SEARCH_USE_COLOR="${GAUDI_SHELL_SEARCH_USE_COLOR:-true}"
	local COMPONENT="" word component
	local -a args
	args=()

	if [[ $# -eq 0 ]]; then
		_gaudi-shell-search-help
		return 0
	fi

	for word in "$@"; do
		case "${word}" in
		'-h' | '--help')
			_gaudi-shell-search-help
			return 0
			;;
		'-r' | '--refresh')
			_gaudi-shell-component-cache-clean
			;;
		'-x' | '--no-color')
			GAUDI_SHELL_SEARCH_USE_COLOR=false
			;;
		'-p' | '--plugin')
			COMPONENT="plugins"
			;;
		'-a' | '--alias')
			COMPONENT="aliases"
			;;
		'-c' | '--completion')
			COMPONENT="completions"
			;;
		*)
			args+=("${word}")
			;;
		esac
	done

	[[ ${#args[@]} -gt 0 ]] || return 0

	if [[ -n $COMPONENT ]]; then
		_gaudi-shell-search-component "${COMPONENT}" "${args[@]}"
		return
	fi
	# Success when any of the three types has a match
	local found=1
	for component in aliases plugins completions; do
		_gaudi-shell-search-component "${component}" "${args[@]}" && found=0
	done
	return "$found"
}

# @function     _gaudi-shell-component-term-matches-negation
# @description  matches the negation of the search term entered
# @param $1     search match: the search results matches
# @param $2     negation terms <array>: the terms we need to negate/remove from the search matches (result set)
# @return       String of search results without the negated terms
# @example      ❯ _gaudi-shell-component-term-matches-negation "${match}" "${negative_terms[@]}"
_gaudi-shell-component-term-matches-negation() {
	local match="$1"
	shift
	local negative

	for negative in "$@"; do
		[[ "${match}" =~ ${negative} ]] && return 0
	done
	return 1
}

# @function     _gaudi-shell-search-component
# @description  searches a component to match the search terms
# @param $1     component: the component to search in e.g., alias, completion, plugin
# @param $2     search terms: the terms we want to search for
# @return       Results that match our search term
# @example      ❯ _gaudi-shell-search-component aliases @git rake bundler -chruby
_gaudi-shell-search-component() {
	local component="$1" && shift

	# --enable or --disable among the terms is applied to the matches further down.
	local action="" term search_term match line
	if _array-contains "--enable" "$@"; then
		action="enable"
	elif _array-contains "--disable" "$@"; then
		action="disable"
	fi

	# Terms that should be included only if they match exactly
	local -a exact_terms
	exact_terms=()
	# Terms that should be included if they match partially
	local -a partial_terms
	partial_terms=()
	# Negated partial terms that should be excluded
	local -a negative_terms
	negative_terms=()
	# All components of this type (alias, plugin or completion)
	local -a component_list
	component_list=($(_gaudi-shell-component-list "${component}"))

	for term in "$@"; do
		search_term="${term:1}"
		if [[ "${term:0:2}" == "--" ]]; then
			continue
		elif [[ "${term:0:1}" == "-" ]]; then
			negative_terms+=("${search_term}")
		elif [[ "${term:0:1}" == "@" ]]; then
			if _array-contains "${search_term}" "${component_list[@]:-}"; then
				exact_terms+=("${search_term}")
			fi
		else
			while IFS='' read -r line; do
				partial_terms+=("$line")
			done < <(_gaudi-shell-component-list-matching "${component}" "${term}")
		fi
	done

	local -a total_matches
	total_matches=($(_array-dedupe "${exact_terms[@]}" "${partial_terms[@]}"))
	[[ ${#total_matches[@]} -eq 0 ]] && return 1

	local -a matches
	matches=()
	for match in "${total_matches[@]}"; do
		if [[ ${#negative_terms[@]} -gt 0 ]] &&
			_gaudi-shell-component-term-matches-negation "${match}" "${negative_terms[@]}"; then
			continue
		fi
		matches+=("${match}")
	done

	[[ ${#matches[@]} -eq 0 ]] && return 1

	if [[ -n "${action}" ]]; then
		for match in "${matches[@]}"; do
			"_gaudi-shell-${action}" "$component" "$match" >/dev/null
		done
		_gaudi-shell-component-cache-clean "${component}"
	fi

	_gaudi-shell-search-print-result "${component}" "${matches[@]}"
}

# @function     _gaudi-shell-search-print-result
# @description  prints the results of search result
# @param $1     component: the component to search in e.g., alias, completion, plugin
# @param $2...  the matching components
# @return       print the search results formatted and colored
# @example      ❯ _gaudi-shell-search-print-result "${component}" "${matches[@]}"
_gaudi-shell-search-print-result() {
	local component="$1" && shift
	local match

	[[ $# -gt 0 ]] || return 0

	if [[ "${GAUDI_SHELL_SEARCH_USE_COLOR}" == true ]]; then
		printf '%s\t' "${YELLOW}${component}:${NC}"
	else
		printf '%s:\t' "${component}"
	fi

	for match in "$@"; do
		if _gaudi-shell-component-item-is-enabled "${component}" "${match}"; then
			if [[ "${GAUDI_SHELL_SEARCH_USE_COLOR}" == true ]]; then
				printf '%s' "${CYAN}${GREEN}${match} ✓${NC}  ${NC}"
			else
				printf '%s\t' "${match} ✓"
			fi
		elif [[ "${GAUDI_SHELL_SEARCH_USE_COLOR}" == true ]]; then
			printf '%s' "${CYAN}${match}  ${NC}"
		else
			printf '%s\t' "${match}"
		fi
	done

	printf "\n"
}

# @function     _gaudi-shell-search-help
# @description  displays the gaudi-shell search help
# @return       Help manual for the search function
_gaudi-shell-search-help() {

	printf "${NC}%b" "

${YELLOW}USAGE${NC}

   gshell search [-|@]term1 [-|@]term2 ... \\
     [[ --enable ]] \\
     [[ --disable ]] \\
     [[ --plugin     | -p ]] \\
     [[ --alias      | -a ]] \\
     [[ --completion | -c ]] \\
     [[ --no-color   | -x ]] \\
     [[ --refresh    | -r ]] \\
     [[ --help       | -h ]]

${YELLOW}DESCRIPTION${NC}

   Use the ${GREEN}gshell search${NC} command to search for a list of terms or term negations
   across all components: aliases, completions and plugins. Components that are
   enabled are shown in green (or with a check mark if the --no-color option is used).

   In addition to simply finding the right component, you can use the results
   of the search to enable or disable all components that the search returns.

   When search is used to enable/disable components it becomes clear that
   you must be able to perform not just a partial match, but an exact match,
   as well as be able to exclude some components.

      * To exclude a component (or all components matching a substring) use
        a search term with minus as a prefix, eg '-flow'

      * To perform an exact match, use character '@' in front of the term,
        eg. '@git' would only match aliases, plugins and completions named 'git'.

${YELLOW}FLAGS${NC}
   --enable             ${MAGENTA}Enable all matching components${NC}
   --disable            ${MAGENTA}Disable all matching components${NC}
   --plugin     | -p    ${MAGENTA}Search plugins only${NC}
   --alias      | -a    ${MAGENTA}Search aliases only${NC}
   --completion | -c    ${MAGENTA}Search completions only${NC}
   --help       | -h    ${MAGENTA}Print this help${NC}
   --refresh    | -r    ${MAGENTA}Force a refresh of the search cache${NC}
   --no-color   | -x    ${MAGENTA}Disable color output and use monochrome text${NC}

${YELLOW}EXAMPLES${NC}

   For example, ${GREEN}gshell search git${NC} would match any alias, completion
   or plugin that has the word 'git' in either the module name or
   its description. You should see something like this when you run this
   command:

         ${GREEN}❯ gshell search git${NC}
               ${YELLOW}aliases:  ${GREEN}git ${NC}gitsvn
               ${YELLOW}plugins:  ${NC}autojump ${GREEN}git ${NC}git-subrepo jgitflow jump
           ${YELLOW}completions:  ${GREEN}git ${NC}git_flow git_flow_avh${NC}

   You can exclude some terms by prefixing a term with a minus, eg:

         ${GREEN}❯ gshell search git -flow -svn${NC}
               ${YELLOW}aliases:  ${NC}git
               ${YELLOW}plugins:  ${NC}autojump git git-subrepo jump
           ${YELLOW}completions:  ${NC}git${NC}

   Finally, if you prefix a term with '@' symbol, that indicates an exact
   match. Note, that we also pass the '--enable' flag, which would ensure
   that all matches are automatically enabled. The example is below:

         ${GREEN}❯ gshell search @git --enable${NC}
               ${YELLOW}aliases:  ${NC}git
               ${YELLOW}plugins:  ${NC}git
           ${YELLOW}completions:  ${NC}git${NC}

${YELLOW}SUMMARY${NC}

   Take advantage of the search functionality to discover what gaudi-shell can do
   for you. Try searching for partial term matches, mix and match with the
   negative terms, or specify an exact matches of any number of terms. Once
   you created the search command that returns ONLY the modules you need,
   simply append '--enable' or '--disable' at the end to activate/deactivate
   each module.

"
}

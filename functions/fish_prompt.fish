_load_ivy

function fish_prompt
    #Folder
	echo -n -s "⚡️ "
	if test "$theme_complete_path" = "yes"
		set cwd (prompt_pwd)
	else
		set cwd (basename (prompt_pwd))

		if git::is_repo
			set root_folder (command git rev-parse --show-toplevel 2>/dev/null)
			set parent_root_folder (dirname $root_folder)
			set cwd (echo $PWD | sed -e "s|$parent_root_folder/||")
		end
	end

	command -sq kubectl; and k8s::current_context >/dev/null 2>/dev/null; and begin
		set -l k8s_namespace (k8s::current_namespace)
        set -l k8s_ctx (string split '-' (string split '_' (k8s::current_context) | tail -1) | head -1)
		if test -z "$k8s_namespace"
			printf (yellow)"("(dim)$k8s_ctx(yellow)") "(off)
		else
			printf (yellow)"("(dim)$k8s_ctx":"(silver)"$k8s_namespace"(yellow)") "(off)
		end
	end

	if terraform::workspace
		set terraform_workspace_name (command cat .terraform/environment)
		printf (yellow)"("(dim)$terraform_workspace_name(yellow)") "(off)
	end

	printf (green)$cwd" "(off)

    #Git
	set -l symbol "\$"
    set -l code $status

	if test -n "$SSH_CLIENT"
		set -l host (hostname -s)
		set -l who (whoami)
		echo -n -s (red)"["(cyan)"$who"(red)":"(cyan)"$host"(red)"] "(off)
	end

	if git::is_repo
		set -l branch (git::branch_name 2>/dev/null)
		set -l ref (git show-ref --head --abbrev | awk '{print substr($0,0,7)}' | sed -n 1p)

		echo -n -s (white)"<"(off)

		if git::is_stashed
			echo -n -s (dim)"s "(off)
		end

		if command git symbolic-ref HEAD > /dev/null 2>&1
			if git::is_staged
				printf (cyan)"$branch"(off)
			else
				printf (white)"$branch"(off)
			end
		else
			printf (dim)"$ref"(off)
		end

		for remote in (git remote)
			set -l behind_count (echo (command git rev-list $branch..$remote/$branch 2>/dev/null | wc -l | tr -d " "))
			set -l ahead_count (echo (command git rev-list $remote/$branch..$branch 2>/dev/null | wc -l | tr -d " "))

			if test $ahead_count -ne 0; or test $behind_count -ne 0; and test (git remote | wc -l) -gt 1
				echo -n -s " "(orange)$remote(off)
			end

			if test $ahead_count -ne 0
				echo -n -s (white)" +"$ahead_count(off)
			end

			if test $behind_count -ne 0
				echo -n -s (white)" -"$behind_count(off)
			end
		end

		if git::is_dirty
			printf (orange)"*"(off)
		end

		echo -n -s (white)"> "(off)
	end

	if test "$code" = 0
		echo -n -s (white)"$symbol"(off)
	else
		echo -n -s (dim)"$symbol"(off)
	end
end

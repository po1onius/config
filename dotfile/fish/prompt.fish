function fish_prompt
	set_color green
	echo -n '['$(prompt_pwd)']'
	set_color normal
	if set -q GUIX_ENVIRONMENT
		set_color purple
		echo -n '[env]'
		set_color normal
	end
	echo -n '♨️ '
end

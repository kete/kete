# Override capistrano methods here (with description as to why and mark the lines added/changed)

# We need to append env PATH=$PATH to the sudo command to ensure the environment is passed through
def sudo(*parameters, &block)
  options = parameters.last.is_a?(Hash) ? parameters.pop.dup : {}
  command = parameters.first
  user = options[:as] && "-u #{options.delete(:as)}"

  sudo_prompt_option = "-p '#{sudo_prompt}'" unless sudo_prompt.empty?
  sudo_env_option = 'env PATH=$PATH' # added
  sudo_command = [fetch(:sudo, 'sudo'), sudo_prompt_option, user, sudo_env_option].compact.join(' ') # changed

  if command
    command = sudo_command + ' ' + command
    run(command, options, &block)
  else
    return sudo_command
  end
end

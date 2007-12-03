# check for missing software
include RequiredSoftware
required_software = load_required_software
MISSING_SOFTWARE = { 'Gems' => missing_libs(required_software), 'Commands' => missing_commands(required_software)}


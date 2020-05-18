#Requires -Modules Pester
function defParam($command, $name) {
    It "Has a -$name parameter" {
        $command.Parameters.Item($name) | Should Not BeNullOrEmpty
    }
}
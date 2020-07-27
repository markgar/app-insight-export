Get-SpqPesterTests -OutputPath './out/'
. ./azuredeploy.arm.ps1

$templatePath = "./out"

# output to "out" directory to keep things clean
# "out" directory is excluded in .gitignore
Get-Template -TemplateOutputPath $templatePath -EnvironmentName "dev"

# Test-Template -TemplatePath $templatePath
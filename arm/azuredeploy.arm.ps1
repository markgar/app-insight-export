<#
The function "Get-Template" is required
This is where you define your ARM template in PowerShell objects

This function is called in the YAML pipeline to export arm json and run tests.
If the tests are successful, then the arm json can be added to a build artifact.
#>

function Get-Template {
    Param(
        [parameter(Mandatory = $true)] [string] $TemplateOutputPath,
        [parameter(Mandatory = $true)] [string] $EnvironmentName
    )


    Write-Host "Generating Template..."

    $environmentName = "dev"
    $applicationCode = "appin"

    $baseTemplate = Get-SpqBaseTemplate

    $funcStorageAccount = Get-SpqStorageAccount `
        -ApplicationCode $applicationCode `
        -EnvironmentName $environmentName `
        -Location "centralus" `
        -StorageAccessTier "Standard_LRS" 
    $baseTemplate.resources += $funcStorageAccount


    $frontEndASP = Get-SpqAppServicePlan `
        -ApplicationCode $applicationCode `
        -EnvironmentName $EnvironmentName `
        -Location "centralus" `
        -AppServicePlanSKU "S1"
    $baseTemplate.resources += $frontEndASP 

    $frontEndSite = Get-SpqAppServiceWebSite `
        -ApplicationCode $applicationCode `
        -EnvironmentName $EnvironmentName `
        -Location "centralus" `
        -AppServicePlan $frontEndASP
    $baseTemplate.resources += $frontEndSite

    # convert the template object to a json string
    $templateJson = $baseTemplate | ConvertTo-Json -Depth 10

    $templatePathAndFile = Join-Path -Path $TemplateOutputPath -ChildPath "azuredeploy.json"

    # write the json string out to file
    $templateJson | Out-File -FilePath $templatePathAndFile
}

#region Bloilerplate Code
function Test-Template {
    Param(
        [parameter(Mandatory = $true)] [string] $TemplatePath
    )

    Write-Host "Testing template..."
    
    Write-Host "Installing Pester"
    Install-Module -Name Pester -Force

    Write-Host "Invoking Pester"
    # describe the location of the arm template to be tested
    # this is required in each file containing tests
    $parameters = @{ TemplatePath = $TemplatePath }

    # put that and a root location for where the tests are into the $script object
    $script = @{ Path = "."; Parameters = $parameters }
    Invoke-Pester -Script $script -OutputFile Tests.Report.xml -OutputFormat NUnitXml
}
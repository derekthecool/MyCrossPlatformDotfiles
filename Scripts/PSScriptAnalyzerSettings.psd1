@{
    Severity     = @('Error')
    ExcludeRules = @(
        'PSAvoidUsingInvokeExpression'
        'PSAlignAssignmentStatement'
        'PSAvoidUsingWriteHost'
        'PSAvoidUsingPlainTextForPassword'
    )
    IncludeRules = @(
        '*'
        # 'PSAvoidDefaultValueForMandatoryParameter',
        # 'PSAvoidDefaultValueSwitchParameter',
        # 'PSAvoidGlobalAliases',
        # 'PSAvoidGlobalFunctions',
        # 'PSAvoidGlobalVars',
        # 'PSAvoidTrapStatement',
        # 'PSAvoidUninitializedVariable',
        # 'PSAvoidUsingCmdletAliases',
        # 'PSAvoidUsingComputerNameHardcoded',
        # 'PSAvoidUsingConvertToSecureStringWithPlainText',
        # 'PSAvoidUsingEmptyCatchBlock',
        # 'PSAvoidUsingFilePath',
        # 'PSAvoidUsingInvokeExpression',
        # 'PSAvoidUsingPositionalParameters',
        # 'PSAvoidUsingUserNameAndPassWordParams',
        # 'PSAvoidUsingUserNameAndPasswordParams',
        # 'PSAvoidUsingWMICmdlet',
        # 'PSDSC*',
        # 'PSMisleadingBacktick',
        # 'PSMissingModuleManifestField',
        # 'PSPlaceCloseBrace',
        # 'PSPlaceOpenBrace',
        # 'PSPossibleIncorrectComparisonWithNull',
        # 'PSProvideCommentHelp'
        # 'PSReservedCmdletChar',
        # 'PSReservedParams',
        # 'PSReturnCorrectTypesForDSCFunctions',
        # 'PSShouldProcess',
        # 'PSStandardDSCFunctionsInResource',
        # 'PSUseApprovedVerbs',
        # 'PSUseCmdletCorrectly',
        # 'PSUseCompatibleSyntax',
        # 'PSUseConsistentIndentation',
        # 'PSUseConsistentWhitespace',
        # 'PSUseCore',
        # 'PSUseCorrectCasing',
        # 'PSUseDeclaredVarsMoreThanAssignments',
        # 'PSUseIdenticalMandatoryParametersForDSC',
        # 'PSUseIdenticalParametersForDSC',
        # 'PSUseLiteralInitializerForHashtable',
        # 'PSUseOutputTypeCorrectly',
        # 'PSUsePSCredentialType',
        # 'PSUseShouldProcessForStateChangingFunctions',
        # 'PSUseSingularNouns',
        # 'PSUseSupportsShouldProcess',
        # 'PSUseVerboseMessageInDSCResource'
        # 'PSUserToExportFieldsInManifest',
        # 'PsUseBOMForUnicodeEncodedFile'
    )
    Rules        = @{
        PSPlaceOpenBrace           = @{
            Enable             = $true
            OnSameLine         = $false
            NewLineAfter       = $true
            IgnoreOneLineBlock = $true
        }

        PSPlaceCloseBrace          = @{
            Enable             = $true
            NewLineAfter       = $false
            IgnoreOneLineBlock = $true
            NoEmptyLineBefore  = $false
        }

        PSUseConsistentIndentation = @{
            Enable              = $false
            Kind                = 'space'
            PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
            IndentationSize     = 4
        }

        PSAlignAssignmentStatement = @{
            Enable         = $true
            CheckHashtable = $true
        }

        PSUseCorrectCasing         = @{
            Enable = $true
        }

        PSUseConsistentWhitespace  = @{
            Enable                          = $true
            CheckInnerBrace                 = $true
            CheckOpenBrace                  = $true
            CheckOpenParen                  = $true
            CheckOperator                   = $true
            CheckPipe                       = $true
            CheckPipeForRedundantWhitespace = $true
            CheckSeparator                  = $true
            CheckParameter                  = $false
            IgnoreAssignmentOperatorInsideHashTable = $true
        }

        # Additionnal rules: see https://github.com/PowerShell/PSScriptAnalyzer/tree/master/docs/Rules

        PSAvoidUsingCmdletAliases = @{
            Enable             = $true
        }

        PSAvoidSemicolonsAsLineTerminators = @{
            Enable             = $true
        }

        PSAvoidLongLines = @{
            Enable = $true
            MaximumLineLength = 120
        }

    }
}

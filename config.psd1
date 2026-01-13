@{
    GraphApiMetaUri = 'https://graph.microsoft.com/beta/$metadata'
    
    OutputPath = ".\intune-dump"

    Endpoints = @{
        configurationPolicies = @{
            Uri = "/beta/deviceManagement/configurationPolicies"
            Children = @{
                settings    = "/beta/deviceManagement/configurationPolicies/{id}/settings"
                assignments = "/beta/deviceManagement/configurationPolicies/{id}/assignments"
            }
        }

        endpointSecurityPolicies = @{
            Uri = "/beta/deviceManagement/intents"
            Children = @{
                settings    = "/beta/deviceManagement/intents/{id}/settings"
                assignments = "/beta/deviceManagement/intents/{id}/assignments"
            }
        }

        groupPolicyConfigurations = @{
            Uri = "/beta/deviceManagement/groupPolicyConfigurations"
            Children = @{
                definitionValues = "/beta/deviceManagement/groupPolicyConfigurations/{id}/definitionValues"
                assignments      = "/beta/deviceManagement/groupPolicyConfigurations/{id}/assignments"
            }
        }

        compliancePolicies = @{
            Uri = "/beta/deviceManagement/deviceCompliancePolicies"
            Children = @{
                assignments = "/beta/deviceManagement/deviceCompliancePolicies/{id}/assignments"
            }
        }

        managedDevices = @{
            Uri = "/beta/deviceManagement/managedDevices"
        }
    }
}

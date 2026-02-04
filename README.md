# Microsoft Graph API - Device Management Endpoint Reference

This document provides a high-level overview of the data returned from each `deviceManagement` endpoint queried by the `Invoke-GraphEndpointQuery.ps1` script.

> **Note:** All endpoints require an [active Intune license](https://go.microsoft.com/fwlink/?linkid=839381) for the tenant.

---

## Successfully Retrieved Endpoints

### Device & App Management

| Endpoint | Description |
|----------|-------------|
| **managedDevices** | Devices managed or pre-enrolled through Intune. Contains device name, OS, compliance state, enrollment type, user info, hardware details (storage, memory, IMEI), encryption status, and last sync time. |
| **detectedApps** | Managed or unmanaged applications installed on managed devices. Returns app name, version, size, device count, publisher, and platform (Windows, iOS, macOS, etc.). |
| **windowsMalwareInformation** | Malware detected on Windows devices. Includes malware name, severity, category (adware, ransomware, trojan, etc.), and last detection time. |
| **managedDeviceEncryptionStates** | Encryption status of managed devices including BitLocker and FileVault states. |

### Device Configuration & Compliance

| Endpoint | Description |
|----------|-------------|
| **deviceConfigurations** | Device configuration profiles. Contains display name, description, version, created/modified dates, and assignment status. |
| **deviceCompliancePolicies** | Compliance policies defining device requirements. Includes policy name, description, scheduled actions for non-compliance, and device/user status summaries. |
| **deviceCompliancePolicySettingStateSummaries** | Aggregate compliance status for each setting across all compliance policies. |
| **deviceEnrollmentConfigurations** | Enrollment configurations including restrictions, limits, and Autopilot profiles. Contains priority, assignments, and platform-specific settings. |

### Windows Autopilot

| Endpoint | Description |
|----------|-------------|
| **windowsAutopilotDeviceIdentities** | Windows Autopilot registered devices. Returns serial number, model, manufacturer, group tag, enrollment state, Azure AD device ID, and assigned user. |
| **windowsAutopilotDeploymentProfiles** | Autopilot deployment profiles defining OOBE experience, naming patterns, and enrollment settings. |

### Group Policy (ADMX)

| Endpoint | Description |
|----------|-------------|
| **groupPolicyConfigurations** | Group Policy configurations created in Intune for Windows devices. Contains enabled/disabled policy definition values. |
| **groupPolicyDefinitions** | Available Group Policy definitions (ADMX templates). Returns policy name, description, category, supported platforms, and registry path. |
| **groupPolicyDefinitionFiles** | ADMX/ADML files imported into Intune. Contains file name, language, and target prefix. |
| **groupPolicyCategories** | Hierarchical categories organizing Group Policy definitions. |

### Settings Catalog & Templates

| Endpoint | Description |
|----------|-------------|
| **configurationPolicyTemplates** | Templates for Settings Catalog policies across platforms. |
| **configurationCategories** | Categories for organizing configuration settings. |
| **configurationSettings** | Individual settings available in the Settings Catalog. |
| **settingDefinitions** | Metadata about available settings including data types, constraints, and dependencies. |
| **templates** | Policy templates for security baselines and other configurations. |
| **reusableSettings** | Reusable setting instances that can be referenced across multiple policies. |
| **categories** | Top-level categories for organizing Intune settings and policies. |

### Compliance Settings (New)

| Endpoint | Description |
|----------|-------------|
| **complianceCategories** | Categories for the new compliance policy framework. |
| **complianceSettings** | Individual compliance settings in the new framework. |

### Role-Based Access Control (RBAC)

| Endpoint | Description |
|----------|-------------|
| **roleDefinitions** | Intune role definitions (built-in and custom). Contains role name, description, permissions, and whether it's a built-in role. |
| **roleScopeTags** | Scope tags for filtering management visibility. Used to limit which objects administrators can see and manage. |
| **resourceOperations** | Available operations that can be assigned to roles (Create, Read, Update, Delete operations per resource type). |

### Auditing & Remote Actions

| Endpoint | Description |
|----------|-------------|
| **auditEvents** | Audit log of administrative actions. Contains actor info (user/app), activity type, timestamp, affected resources, and before/after values for changes. |
| **remoteActionAudits** | Log of remote actions performed on devices (wipe, restart, sync, etc.) with status and results. |

### Partner Integrations

| Endpoint | Description |
|----------|-------------|
| **deviceManagementPartners** | Mobile Threat Defense and other partner integrations. Contains partner name, status, and last heartbeat. |
| **remoteAssistancePartners** | Remote assistance partners (e.g., TeamViewer). Returns onboarding status and connection URL. |
| **complianceManagementPartners** | Third-party compliance partners integrated with Intune. |

### Platform-Specific Enrollment

| Endpoint | Description |
|----------|-------------|
| **androidForWorkEnrollmentProfiles** | Android Enterprise enrollment profiles for corporate-owned devices. |
| **androidDeviceOwnerEnrollmentProfiles** | Android Device Owner (fully managed) enrollment profiles. |

### Notifications & Branding

| Endpoint | Description |
|----------|-------------|
| **notificationMessageTemplates** | Email/notification templates for compliance actions. Contains message content, branding options, and localized versions. |
| **intuneBrandingProfiles** | Company Portal branding (logos, colors, support info) for different user groups. |

### Windows Update

| Endpoint | Description |
|----------|-------------|
| **windowsUpdateCatalogItems** | Available Windows updates in the Microsoft Update catalog. |

### Microsoft Tunnel (VPN Gateway)

| Endpoint | Description |
|----------|-------------|
| **microsoftTunnelHealthThresholds** | Health thresholds for Microsoft Tunnel servers (CPU, memory, disk, latency metrics). |

---

## Endpoints with Access Errors

These endpoints returned errors, typically due to licensing, permissions, or feature availability:

### Forbidden (403) - Requires Additional Licensing or Permissions

| Endpoint | Description |
|----------|-------------|
| **userExperienceAnalytics*** | Endpoint Analytics data including device performance scores, anomalies, battery health, boot times, and remote connection metrics. Requires E3/E5 or Endpoint Analytics add-on. |
| **deviceShellScripts** | macOS shell scripts deployed via Intune. |
| **deviceComplianceScripts** | Custom compliance scripts for advanced compliance checks. |
| **hardwarePasswordDetails** | BIOS/UEFI password information for Dell devices. |
| **deviceManagementScripts** | PowerShell scripts deployed to Windows devices. |
| **deviceHealthScripts** | Proactive remediation scripts (detection + remediation pairs). |
| **deviceCustomAttributeShellScripts** | macOS scripts for collecting custom device attributes. |
| **zebraFotaArtifacts/Deployments** | Zebra Firmware Over-The-Air updates for Zebra Android devices. |
| **cloudCertificationAuthority** | Cloud-based PKI for certificate deployment. |

### Unauthorized (401) - Feature Not Enabled or Licensed

| Endpoint | Description |
|----------|-------------|
| **serviceNowConnections** | ServiceNow ITSM integration configuration. |
| **chromeOSOnboardingSettings** | Chrome OS device management settings (requires Chrome Enterprise). |
| **managedDeviceWindowsOSImages** | Windows OS images for device provisioning. |

### Bad Request (400) - Configuration or Parameter Issues

| Endpoint | Description |
|----------|-------------|
| **dataSharingConsents** | Data sharing agreements with third parties. |
| **exchangeOnPremisesPolicies** | Exchange on-premises connector policies. |
| **hardwarePasswordInfo** | Hardware password information (may require specific device types). |
| **templateSettings/Insights** | Template-related settings and analytics. |
| **androidManagedStoreAppConfigurationSchemas** | Managed Google Play app configuration schemas. |
| **androidForWorkAppConfigurationSchemas** | Android for Work app configuration schemas. |
| **certificateConnectorDetails** | Certificate connector health and configuration. |
| **mobileAppTroubleshootingEvents** | App installation troubleshooting events. |
| **operationApprovalRequests** | Multi-admin approval workflow requests. |

### Internal Server Error (500)

| Endpoint | Description |
|----------|-------------|
| **userExperienceAnalyticsRemoteConnection** | Remote work connection quality metrics. |
| **userExperienceAnalyticsImpactingProcess** | Processes impacting device performance. |
| **userExperienceAnalyticsCategories** | Endpoint Analytics category scores. |
| **configManagerCollections** | Configuration Manager collection sync (co-management). |

### Not Found (404)

| Endpoint | Description |
|----------|-------------|
| **cloudCertificationAuthorityLeafCertificate** | Issued certificates from cloud PKI. |

### Not Implemented (501)

| Endpoint | Description |
|----------|-------------|
| **exchangeConnectors** | Exchange ActiveSync connector configuration. |

---

## User Experience Analytics Endpoints (Requires Endpoint Analytics License)

All `userExperienceAnalytics*` endpoints provide Endpoint Analytics data:

- **Score History** - Historical performance scores over time
- **Anomaly/AnomalyDevice** - Detected performance anomalies
- **Anomaly Correlation Groups** - Related anomalies grouped together
- **Battery Health** - Battery performance metrics (app impact, model performance, OS performance, runtime history)
- **Device Timeline Events** - Device event history
- **Impacting Processes** - Resource-intensive processes
- **Remote Connection** - Remote work connection quality
- **Work From Anywhere Metrics** - Hybrid work readiness scores

---

## API Reference

For detailed schema information, visit the [Microsoft Graph API Reference for Intune](https://learn.microsoft.com/en-us/graph/api/resources/intune-graph-overview).

## Permissions Required

Most endpoints require one of these permissions:
- `DeviceManagementConfiguration.Read.All`
- `DeviceManagementManagedDevices.Read.All`
- `DeviceManagementApps.Read.All`
- `DeviceManagementRBAC.Read.All`
- `DeviceManagementServiceConfig.Read.All`

See [Microsoft Graph permissions reference](https://learn.microsoft.com/en-us/graph/permissions-reference) for complete details.

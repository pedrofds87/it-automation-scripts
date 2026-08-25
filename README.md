# NinjaOne Automation Scripts

> A collection of **118 custom PowerShell and Bash scripts** developed for automating IT operations across Windows and macOS endpoints, via NinjaOne RMM, Microsoft Intune, and standalone. These scripts represent real-world automation built to enforce security compliance, manage software lifecycles, administer SharePoint Online, and reduce manual IT workload across a distributed organization.

## Overview

| Metric | Value |
|--------|-------|
| Total Scripts | **118** |
| PowerShell (Windows) | **98** |
| Bash (macOS) | **20** |
| Categories | **12** |
| Platforms | NinjaOne RMM · Microsoft Intune · SharePoint Online · Standalone |

## Categories

- [🔒 Security Hardening & CVE Mitigations](#security-hardening) — 17 scripts
- [🛡️ Security Tools](#security-tools) — 19 scripts
- [💬 Microsoft Teams](#microsoft-teams) — 4 scripts
- [📄 Microsoft Office & 365](#microsoft-office) — 11 scripts
- [⚙️ .NET Core / ASP.NET Runtime](#dotnet-runtime) — 13 scripts
- [🍎 macOS Scripts](#macos) — 9 scripts
- [🌐 Browser Updates](#browser-updates) — 6 scripts
- [📦 Software Management](#software-management) — 7 scripts
- [🖥️ Hardware & Drivers](#hardware-drivers) — 4 scripts
- [🔌 Network Diagnostics](#network-diagnostics) — 1 script
- [🖧 System Administration](#system-administration) — 21 scripts
- [📋 SharePoint Online](#sharepoint) — 6 scripts

---

## 🔒 Security Hardening & CVE Mitigations
<a name="security-hardening"></a>

Scripts that remediate known CVEs, enforce secure protocol configurations, and harden Windows systems against common attack vectors including RC4, SSL/TLS weaknesses, SMB misconfigurations, PrintNightmare, and speculative execution vulnerabilities.

| Script | Platform | Description |
|--------|----------|-------------|
| [`Check if TLS is enabled`](security-hardening/235_Check_if_TLS_is_enabled.ps1) | Windows | — |
| [`Disable 3DES via registry`](security-hardening/219_Disable_3DES_via_registry.ps1) | Windows | — |
| [`Enable BitLocker on Entra ID joined device`](security-hardening/225_Enable_BitLocker_on_Entra_ID_joined_device.ps1) | Windows | — |
| [`Information rights management`](security-hardening/234_Information_rights_management.ps1) | Windows | — |
| [`Insecure Windows Service Permissions`](security-hardening/168_Insecure_Windows_Service_Permissions.ps1) | Windows | Path : c:\program files (x86)\pwprintserver\printservice_new.exe Used by services : ECSPrintService  |
| [`RC4 second step`](security-hardening/209_RC4_second_step.ps1) | Windows | — |
| [`RC4 second step`](security-hardening/210_RC4_second_step.ps1) | Windows | — |
| [`RC4 vulnerability`](security-hardening/208_RC4_vulnerability.ps1) | Windows | — |
| [`SMB Insecurely Configured Service`](security-hardening/115_SMB_Insecurely_Configured_Service.ps1) | Windows | — |
| [`SSL Medium Strength Cipher Suites Supported (SWEET32)`](security-hardening/222_SSL_Medium_Strength_Cipher_Suites_Supported_(SWEET32).ps1) | Windows | — |
| [`Script to disable TLS 1.0 and 1.1`](security-hardening/218_Script_to_disable_TLS_1.0_and_1.1.ps1) | Windows | — |
| [`WinVerify`](security-hardening/106_WinVerify.ps1) | Windows | WinVerifyTrust Signature Validation CVE-2013-3900 Mitigation (EnableCertPaddingCheck) |
| [`WinVerify 2`](security-hardening/151_WinVerify_2.ps1) | Windows | pstanczyk |
| [`Windows Speculative Execution Configuration Check - Intel BHI (CVE-2022-0001)`](security-hardening/220_Windows_Speculative_Execution_Configuration_Check_-_Intel_BH.ps1) | Windows | Windows Speculative Execution Configuration Check - Intel BHI (CVE-2022-0001) |
| [`domain-joined / local AD BitLocker script`](security-hardening/196_domain-joined_local_AD_BitLocker_script.ps1) | Windows | — |
| [`smb configuration`](security-hardening/221_smb_configuration.ps1) | Windows | — |
| [`Remediate PrintNightmare (CVE-2021-34527)`](security-hardening/Remediate-PrintNightmare.ps1) | Windows | Point and Print registry hardening for the PrintNightmare vulnerability |

## 🛡️ Security Tools
<a name="security-tools"></a>

Deployment and management scripts for endpoint security agents including Microsoft Defender, Sophos, Tenable Nessus, Cisco Umbrella, and Fortinet FortiClient — for both Windows and macOS, deployed via NinjaOne RMM and Microsoft Intune.

| Script | Platform | Description |
|--------|----------|-------------|
| [`Defender update + scan script`](security-tools/217_Defender_update_+_scan_script.ps1) | Windows | — |
| [`Install DUO for Windows`](security-tools/146_Install_DUO_for_Windows.ps1) | Windows | — |
| [`Install Defender KB2267602`](security-tools/223_Install_Defender_KB2267602.ps1) | Windows | — |
| [`Install FortiClient 7.2.14 (old)`](security-tools/144_Install_FortiClient_7.2.14_(old).ps1) | Windows | — |
| [`Install Tenable on workstation`](security-tools/145_Install_Tenable_on_workstation.ps1) | Windows | — |
| [`Remove FortiClient`](security-tools/118_Remove_FortiClient.ps1) | Windows | — |
| [`Server Enable Automatic Microsoft Defender signatures update`](security-tools/192_Server_Enable_Automatic_Microsoft_Defender_signatures_update.ps1) | Windows | — |
| [`Sophos Instalation`](security-tools/142_Sophos_Instalation.ps1) | Windows | — |
| [`Sophos for MAC`](security-tools/130_Sophos_for_MAC.sh) | Mac | — |
| [`Tenable Server Install`](security-tools/154_Tenable_Server_Install.ps1) | Windows | pstanczyk |
| [`Tenable for MAC`](security-tools/150_Tenable_for_MAC.sh) | Mac | pstanczyk |
| [`Umbrella Installation`](security-tools/143_Umbrella_Installation.ps1) | Windows | # pstanczyk 2024-12-04 |
| [`Update Microsoft Defender signatures manually`](security-tools/193_Update_Microsoft_Defender_signatures_manually.ps1) | Windows | — |
| [`Install Sophos Endpoint`](security-tools/Install-Sophos.ps1) | Windows | Downloads and silently installs Sophos Endpoint via Sophos cloud link |
| [`Install Duo for Windows (Login)`](security-tools/duoforWindows.ps1) | Windows | Silently installs Duo Windows Logon with configurable integration key and host |
| [`Install Tenable Nessus Agent (macOS)`](security-tools/tenable_nessus_mac.sh) | macOS | Downloads Nessus Agent DMG, installs, and links to Tenable cloud — deploy via Intune |
| [`Install FortiClient 7.2.x (macOS)`](security-tools/forticlient_mac.sh) | macOS | Downloads FortiClient from internal distribution server and installs silently — deploy via Intune |
| [`Install Sophos Endpoint (macOS)`](security-tools/sophos_mac.sh) | macOS | Downloads SophosInstall.zip from Sophos Central and installs endpoint agent — deploy via Intune |
| [`Install Duo Authentication (macOS)`](security-tools/duo_mac.sh) | macOS | Downloads and configures Duo Authentication for macOS logon — deploy via Intune |

## 💬 Microsoft Teams
<a name="microsoft-teams"></a>

Scripts to install, update, remove, and troubleshoot Microsoft Teams across user profiles and system-wide deployments.

| Script | Platform | Description |
|--------|----------|-------------|
| [`Remove MS Teams specific user`](microsoft-teams/113_Remove_MS_Teams_specific_user.ps1) | Windows | It needs the user as a parameter |
| [`Remove Support user MS Teams`](microsoft-teams/107_Remove_Support_user_MS_Teams.ps1) | Windows | — |
| [`check MS Teams version  and path`](microsoft-teams/112_check_MS_Teams_version_and_path.ps1) | Windows | — |
| [`update MS Teams`](microsoft-teams/111_update_MS_Teams.ps1) | Windows | — |

## 📄 Microsoft Office & 365
<a name="microsoft-office"></a>

Automation for Microsoft 365 / Office suite updates, macro security enforcement, ActiveX hardening, and Office components management on Windows and macOS.

| Script | Platform | Description |
|--------|----------|-------------|
| [`365 Office app update (v1.0)`](microsoft-office/213_365_Office_app_update_(v1.0).ps1) | Windows | — |
| [`Check and delete outlook signature folder`](microsoft-office/215_Check_and_delete_outlook_signature_folder.ps1) | Windows | — |
| [`Disable Untrusted Macro Execution in Excel`](microsoft-office/125_Disable_Untrusted_Macro_Execution_in_Excel.ps1) | Windows | — |
| [`Force Microsoft Office Updates on macOS`](microsoft-office/116_Force_Microsoft_Office_Updates_on_macOS.sh) | Mac | — |
| [`MS 365 Office update`](microsoft-office/170_MS_365_Office_update.ps1) | Windows | # Force Office to update to the latest version on the Current Channel |
| [`Microsoft Azure Data Studio Update`](microsoft-office/127_Microsoft_Azure_Data_Studio_Update.ps1) | Windows | — |
| [`Microsoft Office ActiveX Controls Enabled Without Restrictions Or Prompting`](microsoft-office/124_Microsoft_Office_ActiveX_Controls_Enabled_Without_Restrictio.ps1) | Windows | — |
| [`O365 installation`](microsoft-office/122_O365_installation.sh) | Mac | — |
| [`Office 365 App updates (use this one)`](microsoft-office/189_Office_365_App_updates_(use_this_one).ps1) | Windows | — |
| [`Solver`](microsoft-office/202_Solver.ps1) | Windows | — |
| [`Update MS Office for MAC`](microsoft-office/114_Update_MS_Office_for_MAC.sh) | Mac | — |

## ⚙️ .NET Core / ASP.NET Runtime
<a name="dotnet-runtime"></a>

Scripts to install, update, and cleanly remove specific .NET Core and ASP.NET Core runtime versions, including process detection and multi-version coexistence handling.

| Script | Platform | Description |
|--------|----------|-------------|
| [`.NET CORE to 8.0.11`](dotnet-runtime/108_.NET_CORE_to_8.0.11.ps1) | Windows | — |
| [`.NET Core 5.0.17 Complete Removal`](dotnet-runtime/149_.NET_Core_5.0.17_Complete_Removal.ps1) | Windows | — |
| [`.net core 6.0.36 Server`](dotnet-runtime/132_.net_core_6.0.36_Server.ps1) | Windows | — |
| [`Delete old version of .NET Core`](dotnet-runtime/109_Delete_old_version_of_.NET_Core.ps1) | Windows | — |
| [`Remove .NET Core (8.0.12)`](dotnet-runtime/182_Remove_.NET_Core_(8.0.12).ps1) | Windows | — |
| [`Remove .net core 6.0.36`](dotnet-runtime/138_Remove_.net_core_6.0.36.ps1) | Windows | — |
| [`Remove ASPNET Core (8.0.12)`](dotnet-runtime/183_Remove_ASPNET_Core_(8.0.12).ps1) | Windows | — |
| [`Update .NET Core (6.0.35)`](dotnet-runtime/110_Update_.NET_Core_(6.0.35).ps1) | Windows | — |
| [`install ASP.NET Core Runtime 8.0.21`](dotnet-runtime/181_install_ASP.NET_Core_Runtime_8.0.21.ps1) | Windows | — |
| [`list all the installed .NET Core versions and identify the processes using each version`](dotnet-runtime/131_list_all_the_installed_.NET_Core_versions_and_identify_the_p.ps1) | Windows | — |
| [`remove .net 6.0.32`](dotnet-runtime/139_remove_.net_6.0.32.ps1) | Windows | — |
| [`remove .net 8.0.12 (use this one)`](dotnet-runtime/191_remove_.net_8.0.12_(use_this_one).ps1) | Windows | — |
| [`stop all processes using .NET Core 6.0.36, then uninstall`](dotnet-runtime/135_stop_all_processes_using_.NET_Core_6.0.36,_then_uninstall.ps1) | Windows | — |

## 🍎 macOS Scripts
<a name="macos"></a>

macOS-specific automation scripts for software updates, security configuration, Sophos installation, NinjaOne permissions, and system maintenance.

| Script | Platform | Description |
|--------|----------|-------------|
| [`Installing winget into machine`](macos/140_Installing_winget_into_machine.ps1) | Windows | — |
| [`Ninja RMM has full permissions to connect on a macOS`](macos/129_Ninja_RMM_has_full_permissions_to_connect_on_a_macOS.sh) | Mac | — |
| [`Ruby REXML`](macos/190_Ruby_REXML.sh) | Mac | — |
| [`Zoom MAC`](macos/120_Zoom_MAC.sh) | Mac | — |
| [`chrome update for MacBook`](macos/185_chrome_update_for_MacBook.sh) | Mac | — |
| [`download and install Company Portal on a Mac`](macos/224_download_and_install_Company_Portal_on_a_Mac.sh) | Mac | — |
| [`macOS Software Update Script`](macos/128_macOS_Software_Update_Script.sh) | Mac | — |
| [`macOS update`](macos/207_macOS_update.sh) | Mac | — |
| [`uninstall Zoom on MAC`](macos/121_uninstall_Zoom_on_MAC.sh) | Mac | — |

## 🌐 Browser Updates
<a name="browser-updates"></a>

Automated update scripts for Google Chrome, Microsoft Edge, and Mozilla Firefox on Windows and macOS.

| Script | Platform | Description |
|--------|----------|-------------|
| [`Chrome Automation daily`](browser-updates/198_Chrome_Automation_daily.ps1) | Windows | — |
| [`Chrome update (use this one)`](browser-updates/180_Chrome_update_(use_this_one).ps1) | Windows | — |
| [`Install Chrome (NinjaOne Automation)`](browser-updates/152_Install_Chrome_(NinjaOne_Automation).ps1) | Windows | pstanczyk |
| [`Update MS Edge`](browser-updates/187_Update_MS_Edge.ps1) | Windows | — |
| [`Update MS Edge (using winget)`](browser-updates/186_Update_MS_Edge_(using_winget).ps1) | Windows | — |
| [`Update Mozilla`](browser-updates/188_Update_Mozilla.ps1) | Windows | — |

## 📦 Software Management
<a name="software-management"></a>

General-purpose software deployment scripts using Winget and direct installers for applications such as Slack, Zoom, and VLC.

| Script | Platform | Description |
|--------|----------|-------------|
| [`Check if slack needs update for Windows`](software-management/156_Check_if_slack_needs_update_for_Windows.ps1) | Windows | pstanczyk |
| [`Company Portal (needs winget, runs as logged user)`](software-management/194_Company_Portal_(needs_winget,_runs_as_logged_user).ps1) | Windows | — |
| [`Slack using winget Windows`](software-management/74_Slack_using_winget_Windows.ps1) | Windows | — |
| [`Uninstall VLC`](software-management/134_Uninstall_VLC.ps1) | Windows | — |
| [`delete registry keys related to Zoom`](software-management/147_delete_registry_keys_related_to_Zoom.ps1) | Windows | — |
| [`update Zoom`](software-management/119_update_Zoom.ps1) | Windows | — |
| [`Restart Solver Services`](software-management/Restart-SolverServices.ps1) | Windows | Restarts Solver Report, Publishing, and Maintenance services with timestamped logging |

## 🖥️ Hardware & Drivers
<a name="hardware-drivers"></a>

Scripts to update or remove Dell peripheral software and display drivers.

| Script | Platform | Description |
|--------|----------|-------------|
| [`Dell Peripheral Manager (Uninstall)`](hardware-drivers/123_Dell_Peripheral_Manager_(Uninstall).ps1) | Windows | — |
| [`Dell Peripheral Manager Update`](hardware-drivers/169_Dell_Peripheral_Manager_Update.ps1) | Windows | — |
| [`Remove Dell Display manager`](hardware-drivers/157_Remove_Dell_Display_manager.ps1) | Windows | — |
| [`remove myDell files`](hardware-drivers/201_remove_myDell_files.ps1) | Windows | — |

## 🔌 Network Diagnostics
<a name="network-diagnostics"></a>

Network scanning and port analysis utilities for endpoint diagnostics.

| Script | Platform | Description |
|--------|----------|-------------|
| [`PowerShell Script to Scan Open TCP Ports`](network-diagnostics/171_PowerShell_Script_to_Scan_Open_TCP_Ports.ps1) | Windows | — |

## 🖧 System Administration
<a name="system-administration"></a>

Broad-scope Windows administration scripts covering BitLocker, Active Directory, Group Policy, registry management, Azure AD services, SAP B1, Shopify, and scheduled server operations.

| Script | Platform | Description |
|--------|----------|-------------|
| [`8.0.12 removal`](system-administration/184_8.0.12_removal.ps1) | Windows | — |
| [`Adjust time EST (Windows)`](system-administration/137_Adjust_time_EST_(Windows).ps1) | Windows | — |
| [`Check signature (test)`](system-administration/216_Check_signature_(test).ps1) | Windows | — |
| [`Fix Permissions ECSPrintService`](system-administration/136_Fix_Permissions_ECSPrintService.ps1) | Windows | — |
| [`SSD Space Analysis`](system-administration/148_SSD_Space_Analysis.ps1) | Windows | — |
| [`Showing expired AD accounts (Run on DC)`](system-administration/195_Showing_expired_AD_accounts_(Run_on_DC).ps1) | Windows | — |
| [`Start Azure AD services on 100.3`](system-administration/212_Start_Azure_AD_services_on_100.3.ps1) | Windows | — |
| [`Stop SQLSERVERAGENT and MSSQLSERVER on .80`](system-administration/228_Stop_SQLSERVERAGENT_and_MSSQLSERVER_on_.80.ps1) | Windows | — |
| [`Stop Shopify services .82`](system-administration/229_Stop_Shopify_services_.82.ps1) | Windows | — |
| [`Stop sap business one server tools`](system-administration/203_Stop_sap_business_one_server_tools.ps1) | Windows | — |
| [`Terminal server register add`](system-administration/155_Terminal_server_register_add.ps1) | Windows | pstanczyk |
| [`Update Intel Chipset Device Software`](system-administration/126_Update_Intel_Chipset_Device_Software.ps1) | Windows | — |
| [`Update Microsoft Windows Subsystem for Linux (WSL2)`](system-administration/179_Update_Microsoft_Windows_Subsystem_for_Linux_(WSL2).ps1) | Windows | — |
| [`WSL update (use this one)`](system-administration/199_WSL_update_(use_this_one).ps1) | Windows | — |
| [`asp net removal toll`](system-administration/200_asp_net_removal_toll.ps1) | Windows | — |
| [`check if B1ServerTools64 is running on .83`](system-administration/227_check_if_B1ServerTools64_is_running_on_.83.ps1) | Windows | — |
| [`checking what is running .ASP NET`](system-administration/133_checking_what_is_running_.ASP_NET.ps1) | Windows | — |
| [`gp update`](system-administration/197_gp_update.ps1) | Windows | — |
| [`rdp self certificate`](system-administration/226_rdp_self_certificate.ps1) | Windows | — |
| [`shutdown server`](system-administration/244_shutdown_server.ps1) | Windows | pstanczyk |
| [`sleep and screen off to Never`](system-administration/141_sleep_and_screen_off_to_Never.ps1) | Windows | — |

## 📋 SharePoint Online
<a name="sharepoint"></a>

PowerShell scripts for SharePoint Online administration using PnP PowerShell and Microsoft Graph. Covers document library management, supplier directory automation, bulk file operations, and SharePoint group/web part provisioning.

| Script | Description |
|--------|-------------|
| [`Add-StatusColumnToLibraries.ps1`](sharepoint/Add-StatusColumnToLibraries.ps1) | Moves a shared Status column (Approved/Inactive) from document libraries to directory lists and bulk-sets existing suppliers to Approved |
| [`Populate-RADirectory.ps1`](sharepoint/Populate-RADirectory.ps1) | Builds a searchable supplier directory experience for RA/FL/WH document libraries, replacing Quick Launch entries with 3 filterable directory pages |
| [`Setup-VisitorsGroupAndWebPart.ps1`](sharepoint/Setup-VisitorsGroupAndWebPart.ps1) | Creates/verifies a Visitors SharePoint group with Read-only permissions and adds a People web part snapshot to the site Home page |
| [`Build-RawMaterial-Directories.ps1`](sharepoint/Build-RawMaterial-Directories.ps1) | Builds raw material directory structure from an Excel inventory spreadsheet |
| [`delete_sharepointfiles.ps1`](sharepoint/delete_sharepointfiles.ps1) | Bulk-deletes files from a SharePoint document library via PnP PowerShell |
| [`movetosp.ps1`](sharepoint/movetosp.ps1) | Uploads a local file to a SharePoint site using Microsoft Graph (device code auth) |

> **Prerequisites:** PnP.PowerShell module and/or Microsoft.Graph module. Update tenant URL and site path parameters before running.

---

## Usage

All scripts in this repository are designed to be deployed through **NinjaOne RMM** as automation policies or on-demand scripts. They can also be run manually for testing:

**PowerShell (Windows):**
```powershell
# Run locally (elevated prompt)
.\script_name.ps1
```

**Bash (macOS):**
```bash
chmod +x script_name.sh
sudo ./script_name.sh
```

## Author

**Pedro Stanczyk** — IT Manager / Systems Administrator

These scripts were developed to automate day-to-day IT operations, enforce security compliance standards, and reduce manual intervention across a mixed Windows/macOS environment. Each script has been tested and deployed in production through NinjaOne RMM.

---

*Scripts are provided as-is for portfolio and reference purposes. Review and test in a non-production environment before deploying.*
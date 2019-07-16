**Table Of Contents**
- [Definitions:](#Definitions)
  - [ADK - Assesment Deployment Kit](#ADK---Assesment-Deployment-Kit)
  - [USMT - User State Migration Tool](#USMT---User-State-Migration-Tool)
  - [ADMU - Active Directory Migration Utility](#ADMU---Active-Directory-Migration-Utility)
- [Windows Profile Types:](#Windows-Profile-Types)
  - [Local user profile](#Local-user-profile)
  - [Roaming user profile](#Roaming-user-profile)
  - [Microsoft Account based profile](#Microsoft-Account-based-profile)
  - [Azure AD Scenarios:](#Azure-AD-Scenarios)
    - [Azure AD Join](#Azure-AD-Join)
    - [Azure AD Registration](#Azure-AD-Registration)
    - [Hybrid Azure AD Join](#Hybrid-Azure-AD-Join)
- [What Is In A Profile?](#What-Is-In-A-Profile)
- [Running the ADMU Tool:](#Running-the-ADMU-Tool)
  - [Prerequisites:](#Prerequisites)
  - [Supported O/S Versions:](#Supported-OS-Versions)
  - [GUI](#GUI)
  - [Powershell](#Powershell)
  - [EXE](#EXE)
- [About the Tool:](#About-the-Tool)
- [Advanced Deployment Scenarios:](#Advanced-Deployment-Scenarios)
  - [MTP and MSP deployment scenarios and examples:](#MTP-and-MSP-deployment-scenarios-and-examples)
  - [Protected content migration dialogue explanation:](#Protected-content-migration-dialogue-explanation)
- [JCADMU Steps - What is the script doing?:](#JCADMU-Steps---What-is-the-script-doing)
  - [ADK & USMT INSTALLER:](#ADK--USMT-INSTALLER)
- [Limitations of User Account Conversion:](#Limitations-of-User-Account-Conversion)
  - [Examples:](#Examples)
- [How long will this take?](#How-long-will-this-take)
- [Future Development](#Future-Development)




# Definitions:


## ADK - Assesment Deployment Kit
```
Windows Assessment and Deployment Kit (ADK) for Windows 10 provides new and improved deployment tools for automating large-scale deployments of Windows 10.
```


## USMT - User State Migration Tool
```
Microsoft Tool bundled in the Windows ADK

[https://docs.microsoft.com/en-us/windows/deployment/usmt/usmt-overview](https://docs.microsoft.com/en-us/windows/deployment/usmt/usmt-overview)
```

## ADMU - Active Directory Migration Utility
```
Name for the JumpCloud tool that utilizes USMT to convert domain bound systems and accounts to JumpCloud.
```

# Windows Profile Types:

[https://docs.microsoft.com/en-us/windows/win32/shell/about-user-profiles](https://docs.microsoft.com/en-us/windows/win32/shell/about-user-profiles)


## Local user profile

```
* Created upon first logon
* Stored on local hard disk
* Changes to profile are computer and user specific
```


##  Roaming user profile
```
* Downloaded upon first logon & requires connection to server
* Stored and redirects to file share
* Syncs changes to file share when accessible 
* Merged with local profile to allow offline ‘cached version’
* Dissociated/unusable when system is unbound from domain
```

## Microsoft Account based profile
```
* Tied to online ‘Live ID’ or ‘Microsoft Account’
* Syncs account settings via cloud
* Can utilize onedrive to sync desktop, network profiles, passwords, wifi etc.
* Tightly coupled with online identity and services.
```

***This type of account is not supported with JumpCloud takeover***



## Azure AD Scenarios:

[https://docs.microsoft.com/en-us/azure/active-directory/devices/](https://docs.microsoft.com/en-us/azure/active-directory/devices/)



### Azure AD Join

Windows 10 systems can be ‘Azure AD Joined’ to an ‘Azure AD’ instance and shows up under ‘Devices’. Based on the ‘Azure AD’ settings, Users and Admins can associate a system to an ‘Azure AD’ identity allowing login to the system with ‘Azure AD’ credentials. This creates a cached local account that is associated to this account and named ‘AzureAD\Username’.



This type of account is not supported by JumpCloud takeover when binding users to a system and would create a new ‘local profile’ in this example if JumpCloud username was ‘BradStevens’ it would create ‘10PRO1809-1\BradStevens’ and not sync/link with the ‘AzureAD\BradStevens’ profile.



The ADMU v1.0.0 tool can not currently convert this account to a ‘local profile’. However this functionality will be added in the future to allow administrators a way to convert ‘Azure Ad Joined’ systems and accounts to migrate to JumpCloud.



![image0](https://raw.githubusercontent.com/TheJumpCloud/support-admin-tools/master/JumpCloud.Migration/JCADMU/images/img_0.png?token=AIMZ5WQY4QX3ES6KMY4DSOS5GX6QK)


![image1](https://raw.githubusercontent.com/TheJumpCloud/support-admin-tools/master/JumpCloud.Migration/JCADMU/images/img_1.png?token=AIMZ5WQY4QX3ES6KMY4DSOS5GX6QK)



### Azure AD Registration

A system can also be ‘registered’ to ‘Azure AD’, this is primarily for BYOD devices in which complete control of the system is not required or present. This can be done in windows 10 under Settings, Accounts, Access work or school, Connect. Once signed in the system would be registered, this registration is independent of the profile and simply associated to the underlying system profile. This means that as long as the parent profile is managed by JumpCloud it can co-exist vs the ‘Azure AD Join’ scenario above can not and requires account conversion.



![image alt text](img_2.png)

![image alt text](img_3.png)



### Hybrid Azure AD Join

It is also possible to ‘Hybrid Azure AD Join’ a system. This is when a system is both domain bound and azure ad joined to get the best of both scenarios. It also allows non windows 10 systems to be managed within ‘Azure Ad’ however it is more limited than the other windows 10 options. It does not impact or create any local profiles and JumpCloud can run alongside this scenario. However further thought would need to go into an ideal password reset flow and if azure ad paid tier is required for password writeback etc depending on the scenario and requirements.

# What Is In A Profile?

```
* A registry hive. The registry hive is the file NTuser.dat. The hive is loaded by the system at user logon, and it is mapped to the HKEY_CURRENT_USER registry key. The user's registry hive maintains the user's registry-based preferences and configuration.
```
```
* A set of profile folders stored in the file system. User-profile files are stored in the Profiles directory, on a folder per-user basis. The user-profile folder is a container for applications and other system components to populate with sub-folders, and per-user data such as documents and configuration files. Windows Explorer uses the user-profile folders extensively for such items as the user's Desktop, Start menu and Documents folder.
```
```
* App data folder contains data and settings related to applications. Each windows user/profile has its own broken down into roaming and local. If a system is domain joined certain settings can roam across the domain vs local will only be specific to that user on that system.
```

# Running the ADMU Tool:

## Prerequisites:
.net framework

JumpCloud Agent Requirements

Windows 10 ADK

## Supported O/S Versions:

Windows 7

Windows 8.1

Windows 10

Running an unsupported version? Reach out to [support@Jumpcloud.com](mailto:support@Jumpcloud.com) to submit a request to support your version of Windows.

Both the GUI and EXE implementations require a specific .net version to work.



Windows 7 ships with .net 3.5.1 by default

![image alt text](img_4.png)



Windows 8.1 ships with .net 4.5 and .net 3.5 not enabled by default

![image alt text](img_5.png)



Windows 10 ships with .net 4.7 and .net 3.5 not enabled by default

![image alt text](img_6.png)



To get around this we have a win7 and 8.1/10 versions of each .exe



This means for example if you install the win10/.net 4.5 on a windows 7 system it won’t ask to install and interfere with a zero touch install.



This will be addressed in the future and ideally there will be a single exe for all systems and requirements will be handled behind the scenes.



The ADMU tool v1.0.0 assumes and requires the following to work

* System should be currently Domain bound (The system does NOT have to be connected or currently connected to a Domain Controller).
* A domain based profile should exist on the system to convert
* Once the user account is converted the JumpCloud agent will be installed and the system bound to the JumpCloud instance



In order to provide administrators multiple ways to deploy and utilize the JumpCloud ADMU tool in different scenarios and enviroments we allow it to be run in the following ways:



## GUI
This is a Powershell launched GUI that utilizes WPF to collect input parameters to pass to the JCADMU powershell code.



If the GUI is ran and the system is not domain joined the utility will not let the user continue with the process. The only option is to quit the application

![image alt text](img_7.png)



## Powershell
This function can be passed the required parameters and utilized in larger or silent deployment scenarios as it is all CLI/PS based.



The powershell script jcadmu.ps1 requires both files to be present in the same directory as it relies on functions from the import_functions.ps1 file to work.

![image alt text](img_8.png)



![image alt text](img_9.png)



.\jcadmu.ps1 -DomainUserName tcruise -JumpCloudUserName tom.cruise -TempPassword Temp123! -JumpCloudConnectKey 4e7699c4c1c1e3126fb627240723cb3g292ebc75 -AcceptEULA $true



If -AcceptEULA $true is not added it will default to $false and prompt/confirmation will be seen and require interaction.



The Powershell script has validation on the parameters and requires them to not to be empty and the -jumpcloudconnectkey to be 40chars or it will not move forward.

![image alt text](img_10.png)



Currently if you pass in a domain username that doesn’t exist it will continue and error at a later part in the script when it tries to load the empty state to the new local account. Validation of this user accounts existence both locally and on the domain will be added into a future version to better gate and only allow conversions of possible accounts. This is better controlled by the GUI implementation and its selection list.

![image alt text](img_11.png)

![image alt text](img_12.png)



## EXE
The Powershell code has also been packaged as an exe for various deployment scenarios. 



# About the Tool:



EULA & Legal Explanation



Supporting tools & prerequisites

* .net requirements
* Agent framework requirements
* USMT and ADK requirements



Error logging & troubleshooting

* Logging levels
* example errors
* troubleshooting scenarios
* 



# Advanced Deployment Scenarios:
* Logon script via GPO
* Meraki deployment
* PDQ deployment
* Intune deployment





## MTP and MSP deployment scenarios and examples:
```
TO DO...
```




## Protected content migration dialogue explanation:

Currently upon the completion of account conversion the ‘protected content migration’ window is shown on first login. It asks for the password from the old computer. However this will not accept any old or new password even if entered correctly. This is a known bug and clicking cancel will have no ill effect and allow the wizard to be dismissed. In a future version of JCADMU the ‘DPAPI config’ will be excluded from the migration and not show on first login.![image alt text](img_13.png)



Application migration scenarios

* Outlook
* app data specific
* no app data



Unsupported scenarios and account types







![image alt text](img_14.png)



Scenario: Domain joined system 10PRO18091 on domain JCADB2.local with Local Domain Account named JCADB2\bob.lazar and a local account named 10PRO18091\Administrator.



* Convert JCADB2\bob.lazar to 10PRO18091\blazar
* Unjoin System from JCADB2.local domain
* Install JumpCloud agent onto system



![image alt text](img_15.png)



![image alt text](img_16.png)

JCADMU GUI utility is launched

![image alt text](img_17.png)

Local accounts are listed at the top of the window, showing the username, if the profile is currently loaded, the last time it was used and if roaming is configured. It also lists the computer name, domain name .



 ‘USMT status’ this is true if microsoft ADMT & USMT are found on the system in the required location. If this is false, the required tools and prerequisites will be downloaded and installed in the next steps (this will add time to the migration).



The ‘Accept EULA’ box allows true or false to be selected. More Info will link to more specifics on the EULA.



You will not be able to move forward with migration until the red text boxes are corrected and a profile is selected.



![image alt text](img_18.png)

[https://console.jumpcloud.com/#/systems/new](https://console.jumpcloud.com/#/systems/new)

The connect key specific to your organization and JC instance can be found in the systems, new system, windows aside.

![image alt text](img_19.png)

Once a profile is selected and text boxes correctly filled out, the ‘Migrate Profile’ button will become active and can be clicked.


# JCADMU Steps - What is the script doing?:

* Checks if USMT is installed on the system and present in C:\adk\Assessment and Deployment Kit\User State Migration Tool\



* If not present ‘windows ADK’ installer is downloaded. The ‘Accept EULA’ value is checked.
  * True, the USMT will be installed silently with no user interaction required
  * False, the USMT will be installed and require user interaction



## ADK & USMT INSTALLER:



![image alt text](img_20.png)

If the system already has ADK/USMT installed on the system but is not located in c:\adk the script will error and return:

**Microsoft Windows ADK  - User State Migration Tool not found in c:\adk. Make sure it is installed correctly and in the required location.**

This will need to be corrected before the tool can move forward, so ADK/USMT should be uninstalled and reinstalled in the required location.



![image alt text](img_21.png)

On win7 base systems .net framework is required for the ADK/USMT installer to work.



If ‘Accept EULA’ parameter is equal to $false or not present the end user will see:

```powershell
LOG: 'Installing Windows ADK at c:\adk\ please complete GUI prompts & accept EULA within 5mins or it will exit.'
```

![image alt text](img_22.png)

![image alt text](img_23.png)

![image alt text](img_24.png)

![image alt text](img_25.png)

![image alt text](img_26.png)

![image alt text](img_27.png)

Once this is completed the script will continue to the next steps and output to the log:

```powershell
LOG: 'Microsoft Windows ADK - User State Migration Tool ready to be used.'
```


![image alt text](img_28.png)

If the end user does not complete the above steps in 5mins the script will timeout and exit and have to be run again from the beginning.



If ‘Accept EULA’ is equal to $true the ADK/USMT will be installed silently to a  default location and simply show in the log it was installed or error accordingly.


```powershell
Log: 'Installing Windows ADK at c:\adk\ silently. By using "$AcceptEULA = "true" you are accepting the "Microsoft Windows ADK EULA". This process could take up to 3mins if .net is required to be installed, it will timeout if it takes longer than 5mins.'
```


If installed on the system it would show:

![image alt text](img_29.png)

Control Panel > Add remove programs Entry

![image alt text](img_30.png)

C:\adk installed folders



Next the ADMU will run the ‘Scanstate’ command from the ‘User State Migration Tool using the passed in parameters.


```powershell
Log: 'Starting scanstate tool on user '$netbiosname + '\' + $DomainUserName'
```

```powershell
Log: 'Scanstate Command: .\scanstate.exe c:\Windows\Temp\JCADMU\store /nocompress /i:miguser.xml /i:migapp.xml /l:c:\Windows\Temp\JCADMU\store\scan.log /progress:c:\Windows\Temp\JCADMU\store\scan_progress.log /o /ue:*\* /ui:' $netbiosname /c'
```



This step is capturing the current state of the profile and making a copy in c:\windows\temp\JCADMU\



It is possible that if the profile is very large in size and the available disk space is not enough, the capture could fail. If the JCADMU succeeds the captured profile is eventually deleted and space recovered.



Although this adds ‘duplication’ time and space it also provides the ability if there is an issue or error the ability to revert and return the system to the original state.



![image alt text](img_31.png)

![image alt text](img_32.png)

UPDATE TO C:\WINDOWS\TEMP\JCADMU\


```powershell
LOG: 'Scanstate tool completed on user' $netbiosname + '\' + $DomainUserName
```


Next the ‘Loadstate’ command is run against the previously captured profile from above.


```powershell
LOG: 'Starting loadstate tool on user ' $netbiosname + '\' + $DomainUserName + ' converting to ' + $localcomputername + '\' + $JumpCloudUserName)
```


```POWERSHELL
**LOG:** **'Loadstate Command:.\loadstate.exe c:\Windows\Temp\JCADMT\store /i:miguser.xml /i:migapp.xml /nocompress /l:c:\Windows\Temp\JCADMT\store\load.log /progress:c:\Windows\Temp\JCADMT\store\load_progress.log /ue:*\* /ui:' + $netbiosname + '\' + $DomainUserName + '/lac:$TEMPPASSWORD /lae /c /mu:' + $netbiosname + '`\' + $DomainUserName + '`:' + $localcomputername + '\' + $JumpCloudUserName)
```


The ‘Loadstate’ command is run and used to convert the captured domain profile to a local account with the entered temppassword.



![image alt text](img_33.png)

Once the conversion is completed the newly converted/created user is added to the computers ‘User group’. This allows the new account to show up on the logon screen and be used.



The latest JumpCloud windows agent is now downloaded & installed. The system is checked to make sure it is not previously installed. The system is also checked for the required ‘Microsoft Visual C++ Redistributables’. If they are not present they are downloaded and installed silently.



They agent is then installed using the passed in Connect Key. If this key was incorrect the installer would fail and script stopped. They system must also have an internet connection to register the system on JumpCloud during this step.



![image alt text](img_34.png)



Currently the JumpCloud agent will not run if the system is bound to a domain and the ‘network category’.

![image alt text](img_35.png)



If the agent install is successful the system will be prompted to reboot, this could be canceled with a keypress, if detected the system will leave the domain on next reboot. This step is required for the JumpCloud agent to start and check in to the console. At this stage the script will also delete the temporary duplicate copy of the profile made by the USMT scanstate tool in the previous step. If the script fails at a previous step this directory will still exist on the system until it gets to this step and succeeds.



![image alt text](img_36.png)

![image alt text](img_37.png)

Once the system checks in, the Jumpcloud user can be bound to the system. If the username matches the account will be ‘taken over’ and the password will update and sync with jumpcloud.

![image alt text](img_38.png)

Now the user can login with the same password as JumpCloud. This step will be automated in a future version utilizing ‘system context API’.



![image alt text](img_39.png)

![image alt text](img_40.png)



The system will now be bound to JumpCloud and no longer bound to the active directory domain. However the system still has a local copy of the original cached domain profile. This can be seen as ‘Account Unknown’ in the user profiles screen, and the corresponding folder in ```C:\Users\.``` This is useful incase the administrator wants to reverse or rejoin the system and access the previous domain account. For example maybe the conversion process broke a business critical application and they need a way for the user to quickly get back to the previous state.



In that case the administrator can just rejoin the system to the domain (the Jumpcloud agent will no longer function due to the network configuration changing back to DomainAuthenticated), but the profile will return to how it was.


![image alt text](img_41.png)


# Limitations of User Account Conversion:


```
There are various limitations and scenarios to the user conversion tools used. Because of this it would make sense for the administrator to follow a one, some, many approach to understand what and how the tool can and can not do. This is where further investigation needs to be done on streamlining and improving/documenting common scenarios and workarounds.
```
```
In future iterations of the tool it would be possible to allow and document a process to allow the administrator to select a testing machine, convert a local account, keep the system bound to the domain and run both accounts in parallel. Investigate and be sure the new ‘local account’ runs all applications and has all files as expected. Then switch over to that account and unbind from the domain. Providing this phased approach could help reduce friction and uncertainty in the process.
```


## Examples:

![image alt text](img_42.png)

 Windows default apps

```
After converting the account, outlooks .ost offline cache file must be recreated and the account re-logged into. However the office activation and association should still be present
```

[https://blogs.technet.microsoft.com/askds/2010/02/11/usmt-ost-and-pst/](https://blogs.technet.microsoft.com/askds/2010/02/11/usmt-ost-and-pst/)

![image alt text](img_43.png)

Outlook .ost file


# How long will this take?
```
Approximate timings:

:5 start → scanstate (USMT on win10)
:40 start → scanstate (NO USMT on win10)

:5 start → scanstate (USMT on win7)
:50 start → scanstate (NO USMT on win7)

1:30 Start → loadstate (win7 & win7 with 1gb file)
2:40 start → loadstate (USMT installed on win10)

1:00 loadstate → install agent (win10 & 7 missing prereq c++)
```



# Future Development

* Domain validation
* Ability to convert multiple accounts
* Custom USMT xml templates
* Show local, domain & azure accounts
* Show if account is in local admin group
* Ability to change username
* etc.


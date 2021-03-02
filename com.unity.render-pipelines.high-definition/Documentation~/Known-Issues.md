# Known issues

This page contains information on known about issues you may encounter while using HDRP. Each entry describes the issue and then details the steps to follow in order to resolve the issue.

## Material array size

If you upgrade your HDRP Project to a later version, you may encounter an error message similar to:

```
Property (_Env2DCaptureForward) exceeds previous array size (48 vs 6). Cap to previous size.

UnityEditor.EditorApplication:Internal_CallGlobalEventHandler()
```

To fix this issue, restart the Unity editor.

## Using Collaborate and the HDRP Config package

If your Unity Project uses a local version of the [HDRP config package](HDRP-Config-Package.md) and also uses [Collaborate](https://unity.com/unity/features/collaborate), be aware that, by default, Collaborate does not track the changes you make in the local version of the package. There are two ways to set up Collaborate to track changes you make to the HDRP config package:

* [Scripted setup](#scripted-setup): This method uses a python script and requires you to have Python 3.9.
* [Manual setup](#manual-setup): This method involves moving files from the local HDRP config package to the Assets folder.

### Scripted setup
HDRP provides a python script which automatically sets up your Project so that Collaborate works correctly with the HDRP Config package. This method requires:
1. Python 3.9
2. The right to create symbolic links on windows. To do this, you can either
   * Execute the script as an administrator.
   * Give your user the right to create symbolic links.

To create and version the HDRP config package:
1. Install the config package from the [HDRP Wizard](Render-Pipeline-Wizard.md). To do this, click the **Install Configuration Editable Package** button at the top of the [HDRP Wizard](Render-Pipeline-Wizard.md) window.
2. Run the utility script bundled in HDRP: `Packages/com.unity.render-pipelines.high-definition/Documentation~/tools/local_package_collab.py -p <PATH_TO_YOUR_UNITY_PROJECT>`.
3. In the Unity Collaborate interface, check in all the modified and added files.

To download from Collaborate or sync the Project from Collaborate:
1. Clone or sync the Project from Collaborate.
2. Run the utility script bundled in HDRP: `Packages/com.unity.render-pipelines.high-definition/Documentation~/tools/local_package_collab.py -p <PATH_TO_YOUR_UNITY_PROJECT>`.

### Manual setup
If you do not have Python 3.9, or prefer a manual solution, this section explains how to manually setup Collaborate and the HDRP Config package so they work together. This method involves restructuring your Project's folder structure so that the files that you want Collaborate to track are inside the Assets folder. This method requires:

* The right to create symbolic links on windows. To do this, you can either
  * Execute the script as an administrator.
  * Give your user the right to create symbolic links.

The following is a before and after representation of what your Project's folder structure should look like. For the sake of readability, it only includes important files. If you used the **Install Configuration Editable Package** button at the top of the [HDRP Wizard](Render-Pipeline-Wizard.md) window to install the local version of the package, your folder structure should look like this:
* Root
    * LocalPackages
        * com.unity.render-pipelines.high-definition-config
            * package.json
            * Runtime
                * ShaderConfig.cs
                * ShaderConfig.cs.hlsl
                * Unity.RenderPipelines.HighDefinition.Config.Runtime.asmdef
            * Tests
            * Documentation~
    * Assets

To make Collaborate track the relevant files in the local HDRP Config package, make your Project's folder structure align with the following:
* Root
    * LocalPackages
        * com.unity.render-pipelines.high-definition-config
            * package.json
            * Runtime
                * ShaderConfig.cs.hlsl (create a hard symbolic link to Assets/Packages/com.unity.render-pipelines.high-definition-config/ShaderConfig.cs.hlsl. For information on how to do this, see [Creating the symbolic link](#creating-the-symbolic-link).)
    * Assets
        * Packages
            * com.unity.render-pipelines.high-definition-config
                * Runtime
                    * ShaderConfig.cs
                    * ShaderConfig.cs.hlsl
                    * Unity.RenderPipelines.HighDefinition.Config.Runtime.asmdef
                * Tests

**Note**: Collaborate ignores hidden files and folders. However, the only hidden files and folders in the HDRP Config package are non-essential, such as the mostly empty Documentation~ folder (the documentation for the HDRP Config package is in the HDRP package documentation [here](HDRP-Config-Package.md)).

#### Creating the symbolic link

To create the symbolic link:

* On Windows: Use the `mklink /H <link> <target>` command. This requires the [Create Symbolic Link](https://docs.microsoft.com/en-us/windows/security/threat-protection/security-policy-settings/create-symbolic-links) right for your user, you can also use an Administrator shell.
* On Linux and OSX: Use the `ln -s <target> <link>` command.

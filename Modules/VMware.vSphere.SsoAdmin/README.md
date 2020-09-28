# PowerCLI Example module for managing vSphere SSO Admin
This module is combination of .NET binary libraries for accessin vSphere SSO Admin API and PowerShell advanced funcitons exposing cmdlet-like interface to the SSO Admin features.<br/>
<br/>
The module supports PowerShell 5.1 and PowerShell 7.0 and above.<br/>

# Using the module
The module can be used without the '/src' directory. The '/src' directory contains the source code of the module.<br/>

# Using the source code
## '/src' directory
This directory contains the .NET binaries sources code and Pester integration tests that cover both the binaries and the module advanced functions functionality.<br/>

## '/src/build.ps1' script
This is the build script of the module. It requires 'dotnet' sdk, and PowerCLI to be available on the machine which runs the script. <br/>

The script builds the binarires and publishes them to the 'net45' and 'netcoreapp2.0' directories of the module.<br/>

It has also the option to run module Pester tests. The optional parameters for VC server and credentials has to be specified in order the script to run the tests. Tests run in separate PowreShell process because PowerShell has to load the load the module binaries which are build output.<br/>

## '/src/test/RunTests.ps1' script
This script can be used to run the tests<br/>
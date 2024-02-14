#
# Script to move package caches to the desired dev drive
# Assumes package caches are in their default locations, otherwise it won't recognize or move them to dev drive
#
# Dev Drive must already exist, and passed in as a parameter
# TestMode allows you to see the output of potential changes, default=True
#
param ([Parameter(Mandatory)] [string]$DevDrive,
                              [bool]$TestMode=$True)

class packageCache {
    [string] $srcLocation
    [string] $destLocation
    [string] $envVar
    [string] $destPath
    [string] $scope

# class to handle the copy. 
# src & destination location may be a parent folder, so destPath enables ability to specify the drilldown specific cache location
    packageCache(
        [string] $srcLocation,
        [string] $destLocation,
        [string] $envVar,
        [string] $destPath,
        [string] $scope
    ){
        $this.srcLocation = $srcLocation
        $this.destLocation = $destLocation
        $this.envVar = $envVar
        $this.destPath = $destPath
        $this.scope = $scope
    }
}

# function to copy the package cache to Dev Drive and update environment variable overrides
function updatePackageCaches {

    param([System.Collections.Generic.List[packageCache]] $cacheList)
    
    foreach($pkgCache in $cacheList) {
        if (Test-Path $pkgCache.srcLocation) {
            Write-Output "Package cache $($pkgCache.srcLocation) does exist"
            Write-Output "         Copy $($pkgCache.srcLocation) to $($pkgCache.destLocation)"
            if (!($TestMode)) {
                Copy-Item -Path $pkgCache.srcLocation -Destination $pkgCache.destLocation -Recurse
            }
            Write-Output "         Setting $($pkgCache.envVar) to $($pkgCache.destPath) with scope $($pkgCache.scope)"
            if (!($TestMode)) {
                [Environment]::SetEnvironmentVariable($pkgCache.envVar, $pkgCache.destPath, $pkgCache.scope)
            }
        }
        else {
            Write-Output "Package cache $($pkgCache.srcLocation) does not exist"
        }
    }
}

#Display variables to user
$DevDrive = $DevDrive.ToUpper()
Write-Output "Setting Dev Drive to $DevDrive"
Write-Output "Setting TestMode to $TestMode"

# Validate Dev Drive exists
if (!(Test-Path $DevDrive)) {
    Write-Output "Dev Drive '$DevDrive' does not exist, please create one first."
    Exit
}

# Create a list of package caches for python, npm, dotnet, vcpkg, rust, maven, gradle
# add new package caches here in the future, eg: go, flutter, etc
#     - spacing for readability
$packageCacheList = [System.Collections.Generic.List[packageCache]]::new()
$packageCacheList.Add([packageCache]::new("$env:LocalAppData\pip\Cache",      "$DevDrive\Packages\pip",   "PIP_CACHE_DIR",              "$DevDrive\Packages\pip\Cache",              "User"))
$packageCacheList.Add([packageCache]::new("$env:LocalAppData\npm-cache",      "$DevDrive\Packages",       "npm_config_cache",           "$DevDrive\Packages\npm_cache",              "User"))
$packageCacheList.Add([packageCache]::new("$env:UserProfile\.nuget",          "$DevDrive\Packages",       "NUGET_PACKAGES",             "$DevDrive\Packages\.nuget\packages",        "User"))
$packageCacheList.Add([packageCache]::new("$env:LocalAppData\vcpkg\archives", "$DevDrive\Packages\vcpkg", "VCPKG_DEFAULT_BINARY_CACHE", "$DevDrive\Packages\vcpkg\archives",         "User"))
$packageCacheList.Add([packageCache]::new("$env:UserProfile\.cargo",          "$DevDrive\Packages",       "CARGO_HOME",                 "$DevDrive\Packages\cargo",                  "User"))
$packageCacheList.Add([packageCache]::new("$env:UserProfile\.m2",             "$DevDrive\Packages",       "MAVEN_OPTS",                 "-Dmaven.repo.local=$DevDrive\Packages\.m2", "User"))
$packageCacheList.Add([packageCache]::new("$env:UserProfile\.gradle",         "$DevDrive\Packages",       "GRADLE_USER_HOME",           "$DevDrive\Packages\.gradle",                "User"))

# Create packages directory on Dev Drive
# TODO - Consider:what if creating the DevDrive\Packages folder fails?
if (Test-Path -Path "$DevDrive\Packages") {
        Write-Output "$DevDrive\Packages already exists"
} else {
    Write-Output "$DevDrive\Packages does not exist"
    if (!($TestMode)) {
        Write-Output "Creating $DevDrive\Packages folder"
        New-Item -Path $DevDrive\ -Name "Packages" -ItemType "directory"
    }
}

# Update package caches
updatePackageCaches($packageCacheList)

# Tell user to validate and delete source location
Write-Output ""
Write-Output "Validate package caches and environment variables are correct, and then you can delete the source"
Write-Output ""

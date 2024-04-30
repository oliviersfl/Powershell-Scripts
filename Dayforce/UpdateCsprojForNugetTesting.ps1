$currentUserName = $env:USERNAME

$csprojContent = @"
    <PropertyGroup>
      <GeneratePackageOnBuild>True</GeneratePackageOnBuild>
      <Version>9999.9.9.9</Version>
      <DebugType>embedded</DebugType>
    </PropertyGroup>
    <Target Name=`"AfterPack`" AfterTargets=`"Pack`">
      <RemoveDir Directories=`"C:\Users\$currentUserName\.nuget\packages\$`(AssemblyName)\$`(Version)`" />
      <Copy SourceFiles=`"$`(PackageOutputPath)$`(AssemblyName).$`(Version).nupkg`" DestinationFolder=`"C:\Dayforce\GeneratedServicesPackages\$`(Version)`" />
    </Target>
"@

Get-ChildItem -Path '.' -Recurse -Filter '*.csproj' |
Where-Object { $_.Name -notmatch 'Tests\.csproj$' } |
ForEach-Object {
    $csproj = [xml](Get-Content $_.FullName)
    $projectNode = $csproj.Project
    $importNode = $csproj.CreateDocumentFragment()
    $importNode.InnerXml = $csprojContent
    $projectNode.InsertBefore($importNode, $projectNode.LastChild)
    $csproj.Save($_.FullName)
}
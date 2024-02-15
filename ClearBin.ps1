param($path)

Get-ChildItem -Path $path -Recurse -Directory -Include 'bin', 'obj' |
    Remove-Item -Recurse -Force
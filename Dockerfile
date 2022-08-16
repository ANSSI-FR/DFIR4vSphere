FROM vmware/powerclicore
RUN mkdir -p /root/.config/powershell
RUN echo 'Write-Host -ForegroundColor Yellow "DFIR4vSphere: Powershell module for VMWare vSphere forensics"' > /root/.config/powershell/Microsoft.PowerShell_profile.ps1
RUN echo 'Write-Host -ForegroundColor Yellow "https://github.com/ANSSI-FR/DFIR4vSphere"' >> /root/.config/powershell/Microsoft.PowerShell_profile.ps1
ADD dfir4vsphere /root/.local/share/powershell/Modules/DFIR4vSphere
RUN pwsh -noprofile -command Import-Module DFIR4vSphere
RUN mkdir -p /mnt/host/output
WORKDIR "/mnt/host/output"
CMD ["pwsh"]
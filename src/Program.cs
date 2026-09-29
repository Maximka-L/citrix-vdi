using System;
using System.Diagnostics;
using System.Windows.Forms;

static class Program
{
    [STAThread]
    static void Main()
    {
        try
        {
            ProcessStartInfo psi = new ProcessStartInfo();
            psi.FileName = "powershell.exe";
            psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -Command \"$p = Join-Path $env:TEMP 'citrix_install.ps1'; try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; (New-Object System.Net.WebClient).DownloadFile('https://raw.githubusercontent.com/Maximka-L/citrix-vdi/main/install.ps1', $p); Unblock-File $p -ErrorAction SilentlyContinue; & $p } catch { Write-Host $_; Read-Host }\"";
            psi.Verb = "runas";
            psi.UseShellExecute = true;
            psi.WindowStyle = ProcessWindowStyle.Normal;
            Process.Start(psi);
        }
        catch (System.ComponentModel.Win32Exception)
        {
            MessageBox.Show(
                "Для настройки Citrix и установки сертификатов требуются права Администратора.\n\nПожалуйста, запустите программу снова и в окне запроса нажмите 'ДА'.",
                "Citrix VDI Setup",
                MessageBoxButtons.OK,
                MessageBoxIcon.Warning
            );
        }
        catch (Exception ex)
        {
            MessageBox.Show(
                "Ошибка запуска: " + ex.Message,
                "Citrix VDI Setup",
                MessageBoxButtons.OK,
                MessageBoxIcon.Error
            );
        }
    }
}

#!/usr/bin/env bash
#
# Скрипт автоматического исправления Citrix Workspace & SSL для macOS (MegaFon VDI)
# https://github.com/Maximka-L/citrix-vdi
#

echo "=========================================================="
echo "    Citrix Workspace & SSL Fix для macOS (MegaFon VDI)    "
echo "=========================================================="

# Проверка и запрос прав sudo для добавления в системную Связку ключей
if [ "$EUID" -ne 0 ]; then
    echo "Для установки доверенных сертификатов требуются права администратора."
    echo "Пожалуйста, введите пароль от этого Mac (символы при вводе скрыты):"
    sudo -v </dev/tty 2>/dev/null || {
        echo "[-] Ошибка: не удалось подтвердить права администратора."
        exit 1
    }
    SUDO_CMD="sudo"
else
    SUDO_CMD=""
fi

TMP_DIR=$(mktemp -d /tmp/citrix_mac_XXXXXX)
trap 'rm -rf "$TMP_DIR"' EXIT

echo ""
echo "[1/4] Подготовка сертификатов безопасности..."

# 1. Russian Trusted Root CA (Минцифры РФ)
cat << 'EOF' | base64 -D > "$TMP_DIR/russian_root.cer"
LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tDQpNSUlGd2pDQ0E2cWdBd0lCQWdJQ0VBQXdEUVlKS29aSWh2Y05BUUVMQlFBd2NERUxNQWtHQTFVRUJoTUNVbFV4DQpQekE5QmdOVkJBb01ObFJvWlNCTmFXNXBjM1J5ZVNCdlppQkVhV2RwZEdGc0lFUmxkbVZzYjNCdFpXNTBJR0Z1DQpaQ0JEYjIxdGRXNXBZMkYwYVc5dWN6RWdNQjRHQTFVRUF3d1hVblZ6YzJsaGJpQlVjblZ6ZEdWa0lGSnZiM1FnDQpRMEV3SGhjTk1qSXdNekF4TWpFd05ERTFXaGNOTXpJd01qSTNNakV3TkRFMVdqQndNUXN3Q1FZRFZRUUdFd0pTDQpWVEUvTUQwR0ExVUVDZ3cyVkdobElFMXBibWx6ZEhKNUlHOW1JRVJwWjJsMFlXd2dSR1YyWld4dmNHMWxiblFnDQpZVzVrSUVOdmJXMTFibWxqWVhScGIyNXpNU0F3SGdZRFZRUUREQmRTZFhOemFXRnVJRlJ5ZFhOMFpXUWdVbTl2DQpkQ0JEUVRDQ0FpSXdEUVlKS29aSWh2Y05BUUVCQlFBRGdnSVBBRENDQWdvQ2dnSUJBTWZGT1o4cFVBTDMrcjJuDQpxcUUwWnA1MnNlbFhzS0dGWW9HMEdNNWJ3ejFiU0Z0Q3QrQVpRTWhrV1FoZUkzcG9aQVRvWUp1NjlwSExLUzZRDQpYQml3QkMxY3Z6WW1VWUtNWVpDN2pFNVloRVUyYlNMMG1YN05hTXhNRG1IMi9Od3VPVlJqOE9JbVZhNXMxRjRVDQp6bjRLdjNQRmxEQmpqU2pYS1ZZOWttalVCc1hRcklIZWFxbVVJc1BJbE5XVW5pbVhTMEkwYWJFeHFrYmRyWGJYDQpZd0NPWGhPTzJwRFV4M2NrbUpsQ01VR2FjVVRueWx5UVcyVnNKSXlJR0E4VjB4emRhZVVYZzBWWjZabU5VcjVZDQpCZXIvRUFPTFBiOE5ZcHNBaEplMm1Yak1CL0o5SE5zb0ZNQkZKMGxMT1QvK2RRdmpiZFJab09UOGVxSnBXblZEDQpVK1FML3FFWm56NTdOODhPV00zcmFiSmtSTmRVL1o3eDVTRklNOUZycXROOHhld3NpQldCSTBLNlhGdU9CT1REDQo0VjA4bzRUeko4K0NjcTVYbENVVzJMNDhwWk5DWXVCRGZCaDdGeGtCN3FEZ0dEaWFmdEVrWlpmQXBSZzJFK005DQpHOHdrTktUUExEYzR3SDBGRFRpamhneFIzWTRQaVMxSEwyWmh3N2JEM0Nic2xtRUdnZm5uWm9qTmtKdGNMZUJIDQpCTGE1Mi9kU3dOVTRXV0x1YmFZU2lBbUE5SVVNWDEvUnBmcHhPeGQ0WWttaHo5N29GYlVhREpGaXBJZ2d4NXNYDQplUEFsa1RkV252K1JXQnhsSndNUTI1b0VIbVJndU5ZZjRaci9SeHI5Y1M5M1krbWRYSVphQkVFMEtTMmlMUnFhDQpPaVdCa2k5SU1RVTRwaHFQT0JBYUc3QStlUDhQQWdNQkFBR2paakJrTUIwR0ExVWREZ1FXQkJUaDBZSGx6bHBmDQpCS3JTNmJhZFpySEYrcXdzaHpBZkJnTlZIU01FR0RBV2dCVGgwWUhsemxwZkJLclM2YmFkWnJIRitxd3NoekFTDQpCZ05WSFJNQkFmOEVDREFHQVFIL0FnRUVNQTRHQTFVZER3RUIvd1FFQXdJQmhqQU5CZ2txaGtpRzl3MEJBUXNGDQpBQU9DQWdFQUFMSVkxd2tpbHQvdXJmRVZNNXZLenI2dXRPZURXQ1Vjem1XWC9SWDRsanBSZGdGKzVmQUlTNHZIDQp0bVhrcXBTQ09WZVdVckpWOVF2Wm42TDIyN1p3dUUxNWNXaThEQ0RhbDNVZTkwV2dBSkpaTWZUc2hONE9JOGNxDQpXOUU0RUc5d2dsYkV0TW5PYkhsbXM4RjNDSG1ydzNrNkttVWtXR29hKy9FTm1jVmw2OHUvY01SbDFKYlcyYk0rDQovM0ErU0FnMmM2aVBEbGVoY3pLeDJvYTk1UVcwU2tQUFdHdU5BL0NFOENweUFOSWh1OVhGcmozUlEzRXFlUmNTDQpBUVFvZDFSTnVIcGZFVExVL0EyZ01tdm4vdy9zeDdUQjNXNUJQczZycHJPQTM3dHV0UHE5dTZGVFpPY0cxT3FqDQpDL0I3eVRxZ0k3cmJ5dm94N0RFWG9YN3JJaUVxeU5OVWd1VGsvdTNTWjRWWEUya214ZG1TaDNUUXZ5YmZiblhWDQo0SmJDWlZhcWlacmFxYzdvWk1uUm9XclhSRzN6dGJuYmVzLzlxaFJHSTdQcVhxZUtKQnp0eFJURVZqOE9NczFkDQpXTjVzelR3YVBJdmhraE8zQ081RXJVMnJWZFVyODl3S3BOWGJCT0RGS1J0Z3hVVDcwWXBtSjQ2VlZhcWRBaE9aDQpEOUVVVW40WWFlTGFTOEFqU0YvaDdVa2pPaWJOYzRxVkRpUFArcmtlaEZXTTY2UFZuUDFNc2g5M3RjK3RhSWZDDQpFWVZNeGpoOHpOYkZ1b2M3Znp2dnJGSUxMZTdpZnZFSVVxU1ZJQy9BenBsTS9KeHc3YnVYRmVHUDFxVkNCRUhxDQozOTFkLzlSQWZhWjEyemt3RnNsK0lLd0UvT1p4VzhBSGE5aTFwNEdPMFlTTnVjenpFbTQ9DQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tDQo=
EOF

# 2. Russian Trusted Sub CA (Минцифры РФ)
cat << 'EOF' | base64 -D > "$TMP_DIR/russian_sub.cer"
LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tDQpNSUlIUWpDQ0JTcWdBd0lCQWdJQ0VBSXdEUVlKS29aSWh2Y05BUUVMQlFBd2NERUxNQWtHQTFVRUJoTUNVbFV4DQpQekE5QmdOVkJBb01ObFJvWlNCTmFXNXBjM1J5ZVNCdlppQkVhV2RwZEdGc0lFUmxkbVZzYjNCdFpXNTBJR0Z1DQpaQ0JEYjIxdGRXNXBZMkYwYVc5dWN6RWdNQjRHQTFVRUF3d1hVblZ6YzJsaGJpQlVjblZ6ZEdWa0lGSnZiM1FnDQpRMEV3SGhjTk1qSXdNekF5TVRFeU5URTVXaGNOTWpjd016QTJNVEV5TlRFNVdqQnZNUXN3Q1FZRFZRUUdFd0pTDQpWVEUvTUQwR0ExVUVDZ3cyVkdobElFMXBibWx6ZEhKNUlHOW1JRVJwWjJsMFlXd2dSR1YyWld4dmNHMWxiblFnDQpZVzVrSUVOdmJXMTFibWxqWVhScGIyNXpNUjh3SFFZRFZRUUREQlpTZFhOemFXRnVJRlJ5ZFhOMFpXUWdVM1ZpDQpJRU5CTUlJQ0lqQU5CZ2txaGtpRzl3MEJBUUVGQUFPQ0FnOEFNSUlDQ2dLQ0FnRUE5WVBxQktPazE5TkZ5bXJFDQp3ZWh6cmhCRWdUMmF0TGV6cGR1QjI0bVE3Q2lPYS9IVnBGQ0RSWnpkeHFsaDhkcmt1NDA4L3RUbVd6bE5IL2JyDQpIdVFoWi9taVdLT2YzNWxwS3pqeUJkNlRQTTIzdUFmSnZFT1EyL2RuS0dHSmJzVW8xL3VkS1N2eFF3VkhwVnYzDQpTODBPbGx1S2ZoV1BERVhRcGd5RnFJelBveElRVExaMGRlaXJad01WSGFyWjV1OEhxSGV0UnVBdG1PMlpER1FuDQp2Vk9KWUFqbHMrSGl1ZXE3TGo3T2NlN0NRc1R3VlplUCtYUXgyOFBBYUVaM3k2c1FFdDZyTDA2ZGRwU2RvVE1wDQpCbkNxVGJ4VytlV015amtJbjZ0OUdCdFVWNDV5QjFFa0hObmoyRXg0R3dDaU45VDg0UVFqS1NyKzhmMHBzR3JaDQp2UGJDYlFBd05GSmppc0xpeG5qbEdQTEthNXZPbU53SWgvTEF5VVc1RGpwa0N4MDA0TFBEdXFQcEZzS1hOS3BhDQpMMkRtNnVjMHg0Sm81bStnVVRWT1JCNmhPU3pXbldEajJHV2ZvbUx6enlqRzgxRFJHRkJwY28vTzkzemVjc0lODQozU0wyWXNqcHExemRvUzAxQ01ZeGllLy85eld2WXd6STI1L09aaWd0bnBDSXJjZDJqMVk2ZE1VRlFBekF0SEUrDQpxc1hmbFNMOEhJUytJSkVGSVFvYkxsWWhIa29FM2F2Z054NWpsdStPTFllMGRGMFlreDFQR05qYndxdlRYMzdSDQpDbjMyTk1qbG90VzJRY0dFWmhES2orM3VyWml6cDV4ZFRQWml0QSthRWpaTS9OaTcxVk9kaU9QMGlnYnc2YXNaDQoyZnhkb3paMVRuU1NZTll2TkFUd3RoTm1aeXNDQXdFQUFhT0NBZVV3Z2dIaE1CSUdBMVVkRXdFQi93UUlNQVlCDQpBZjhDQVFBd0RnWURWUjBQQVFIL0JBUURBZ0dHTUIwR0ExVWREZ1FXQkJUUjRYRU5DeTJCVG02S1NvOU1JN05NDQpYcXRwQ3pBZkJnTlZIU01FR0RBV2dCVGgwWUhsemxwZkJLclM2YmFkWnJIRitxd3NoekNCeHdZSUt3WUJCUVVIDQpBUUVFZ2Jvd2diY3dPd1lJS3dZQkJRVUhNQUtHTDJoMGRIQTZMeTl5YjNOMFpXeGxZMjl0TG5KMUwyTmtjQzl5DQpiMjkwWTJGZmMzTnNYM0p6WVRJd01qSXVZM0owTURzR0NDc0dBUVVGQnpBQ2hpOW9kSFJ3T2k4dlkyOXRjR0Z1DQplUzV5ZEM1eWRTOWpaSEF2Y205dmRHTmhYM056YkY5eWMyRXlNREl5TG1OeWREQTdCZ2dyQmdFRkJRY3dBb1l2DQphSFIwY0RvdkwzSmxaWE4wY2kxd2Eya3VjblV2WTJSd0wzSnZiM1JqWVY5emMyeGZjbk5oTWpBeU1pNWpjblF3DQpnYkFHQTFVZEh3U0JxRENCcFRBMW9ET2dNWVl2YUhSMGNEb3ZMM0p2YzNSbGJHVmpiMjB1Y25VdlkyUndMM0p2DQpiM1JqWVY5emMyeGZjbk5oTWpBeU1pNWpjbXd3TmFBem9ER0dMMmgwZEhBNkx5OWpiMjF3WVc1NUxuSjBMbkoxDQpMMk5rY0M5eWIyOTBZMkZmYzNOc1gzSnpZVEl3TWpJdVkzSnNNRFdnTTZBeGhpOW9kSFJ3T2k4dmNtVmxjM1J5DQpMWEJyYVM1eWRTOWpaSEF2Y205dmRHTmhYM056YkY5eWMyRXlNREl5TG1OeWJEQU5CZ2txaGtpRzl3MEJBUXNGDQpBQU9DQWdFQVJCVnpabHM3OUFkaVNDcGFyMTVkQTVIci9yclQ0V2JyT2Z6bHBJK3hyTGVSUHJVRzZlVVdJVzR2DQpTdWkxeXgzaXFHTENqUGNLYitIT1R3b1JNYkk2eXRQL25kcDNUbFl1YTJhZHZZQkVoU3Zqcys0dkRaTndYci9EDQphbmJ3SVdkdXJabVZpUVJCREZlYnBrdm5JdnJ1L1JwV3VkLzVyNjI0V3A4dm9aTVJ0ai9jbTZhSTlMdHZCZlQ5DQpjZnpoT2FleEkvOTljMTRkeWl1azErNlFoZHdLYUNSVGMxbWRmTlFtbmZXTlJiZldoV0JsSzNoNEdHRTlKSzMzDQpHazhaUzhETXJrZEFoMHhieTR4QVEvbVNXQWZXckJtZnpsT3FHeW9CMVU0N1dUT2VxTmJXa2tvQVAyeXM5NCtzDQpKZzROVGtpRFZ0WFJGNm5yNmZZaTBiU092T0ZnMElRck1YTzJZOGd5ZzlBUmRQSndLdHZXWDhWUEFEQ1lNaVdIDQpoNG44Ylpva0lySW1WS0xEUUtIWTRqQ3NORDJISGRKZm5yZEwyWUp3MXFGc2tOTzRjU05tWnlkdzBXa2dqdjlrDQpGK0t4cXJES2xCOE1adTJIY2xwaDZ2L0NaMGZROVl1RTgvbHNIWjBRYzJIeWlTTW52amdLNWZEYzNURDRmYThGDQpFOGdNTnVyTStrVjhQVDhMTklNKzRacytMS0VWOG5xUldCYXhrSVZKR2Vra1ZLTzh4REJPRy9hTjYyQVpLSE9lDQpHY3lJZHU3eU5NTVJpaEdWWkNZcjhyWWlKb0tpT3pEcU9rUGtMT1BkaHRWbGduaG93ekhEeE1ITkQvRTJXQTVwDQpaSHVOTS9tMFRYdDJ3VFRQTDdKSDJZQzBnUHovQnZ2U3pqa3NnelU1ckxiUnlVS1FrZ1U9DQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tDQo=
EOF

# 3. AAA Certificate Services (Sectigo)
cat << 'EOF' > "$TMP_DIR/aaa_root.crt"
-----BEGIN CERTIFICATE-----
MIIEMjCCAxqgAwIBAgIBATANBgkqhkiG9w0BAQUFADB7MQswCQYDVQQGEwJHQjEb
MBkGA1UECAwSR3JlYXRlciBNYW5jaGVzdGVyMRAwDgYDVQQHDAdTYWxmb3JkMRow
GAYDVQQKDBFDb21vZG8gQ0EgTGltaXRlZDEhMB8GA1UEAwwYQUFBIENlcnRpZmlj
YXRlIFNlcnZpY2VzMB4XDTA0MDEwMTAwMDAwMFoXDTI4MTIzMTIzNTk1OVowezEL
MAkGA1UEBhMCR0IxGzAZBgNVBAgMEkdyZWF0ZXIgTWFuY2hlc3RlcjEQMA4GA1UE
BwwHU2FsZm9yZDEaMBgGA1UECgwRQ29tb2RvIENBIExpbWl0ZWQxITAfBgNVBAMM
GEFBQSBDZXJ0aWZpY2F0ZSBTZXJ2aWNlczCCASIwDQYJKoZIhvcNAQEBBQADggEP
ADCCAQoCggEBAL5AnfRu4ep2hxxNRUSOvkbIgwadwSr+GB+O5AL686tdUIoWMQua
BtDFcCLNSS1UY8y2bmhGC1Pqy0wkwLxyTurxFa70VJoSCsN6sjNg4tqJVfMiWPPe
3M/vg4aijJRPn2jymJBGhCfHdr/jzDUsi14HZGWCwEiwqJH5YZ92IFCokcdmtet4
YgNW8IoaE+oxox6gmf049vYnMlhvB/VruPsUK6+3qszWY19zjNoFmag4qMsXeDZR
rOme9Hg6jc8P2ULimAyrL58OAd7vn5lJ8S3frHRNG5i1R8XlKdH5kBjHYpy+g8cm
ez6KJcfA3Z3mNWgQIJ2P2N7Sw4ScDV7oL8kCAwEAAaOBwDCBvTAdBgNVHQ4EFgQU
oBEKIz6W8Qfs4q8p74Klf9AwpLQwDgYDVR0PAQH/BAQDAgEGMA8GA1UdEwEB/wQF
MAMBAf8wewYDVR0fBHQwcjA4oDagNIYyaHR0cDovL2NybC5jb21vZG9jYS5jb20v
QUFBQ2VydGlmaWNhdGVTZXJ2aWNlcy5jcmwwNqA0oDKGMGh0dHA6Ly9jcmwuY29t
b2RvLm5ldC9BQUFDZXJ0aWZpY2F0ZVNlcnZpY2VzLmNybDANBgkqhkiG9w0BAQUF
AAOCAQEACFb8AvCb6P+k+tZ7xkSAzk/ExfYAWMymtrwUSWgEdujm7l3sAg9g1o1Q
GE8mTgHj5rCl7r+8dFRBv/38ErjHT1r0iWAFf2C3BUrz9vHCv8S5dIa2LX1rzNLz
Rt0vxuBqw8M0Ayx9lt1awg6nCpnBBYurDC/zXDrPbDdVCYfeU0BsWO/8tqtlbgT2
G9w84FoVxp7Z8VlIMCFlA2zs6SFz7JsDoeA3raAVGI/6ugLOpyypEBMs1OUIJqsi
l2D4kF501KKaU73yqWjgom7C12yxow+ev+to51byrvLjKzg6CYG1a4XXvi3tPxq3
smPi9WIsgtRqAEFQ8TmDn5XpNpaYbg==
-----END CERTIFICATE-----
EOF

echo "[2/4] Добавление сертификатов в системную Связку ключей (System Keychain)..."
# 1. Импорт сертификатов в System Keychain
$SUDO_CMD security add-certificate -k /Library/Keychains/System.keychain "$TMP_DIR/russian_root.cer" 2>/dev/null || true
$SUDO_CMD security add-certificate -k /Library/Keychains/System.keychain "$TMP_DIR/russian_sub.cer" 2>/dev/null || true
$SUDO_CMD security add-certificate -k /Library/Keychains/System.keychain "$TMP_DIR/aaa_root.crt" 2>/dev/null || true

# 2. Установка полного доверия (trustRoot) без конфликтующих флагов
$SUDO_CMD security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain "$TMP_DIR/russian_root.cer"
$SUDO_CMD security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain "$TMP_DIR/russian_sub.cer"
$SUDO_CMD security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain "$TMP_DIR/aaa_root.crt"

# 3. Также добавляем в связку пользователя для гарантированного доверия в профиле
security add-certificate -k ~/Library/Keychains/login.keychain-db "$TMP_DIR/russian_root.cer" 2>/dev/null || true
security add-certificate -k ~/Library/Keychains/login.keychain-db "$TMP_DIR/russian_sub.cer" 2>/dev/null || true
echo "  [OK] Сертификаты зарегистрированы и установлены в доверенные."

echo "[3/4] Исправление настроек Citrix Workspace..."
killall "Citrix Viewer" "Citrix Workspace" "AuthManager_Mac" "ServiceRecords" 2>/dev/null || true
defaults write com.citrix.receiver.nomas EnableAOTLog -bool false 2>/dev/null || true
defaults write com.citrix.receiver.nomas EnableAOTLogParseTokenForHybridLaunch -bool false 2>/dev/null || true
echo "  [OK] Ошибочные флаги AOT-логирования отключены."

echo "[4/4] Проверка доступности портов шлюзов МегаФон VDI (порт 443)..."
for host in "ica2-ext.megafon.ru" "vdi2.megafon.ru"; do
    if nc -z -G 3 "$host" 443 2>/dev/null || nc -z -w 3 "$host" 443 2>/dev/null; then
        echo "  [OK] $host:443 доступен"
    else
        echo "  [!] $host:443 НЕ ОТВЕЧАЕТ! (Проверьте корпоративный VPN или отключите мешающий личный VPN/прокси)"
    fi
done

echo ""
echo "=========================================================="
echo "Успешно завершено! Запустите сессию Citrix Workspace заново."
echo "=========================================================="

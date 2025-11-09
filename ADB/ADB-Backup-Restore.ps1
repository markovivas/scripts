<#
    Script: ADB-Backup-Restore.ps1
    Funcao: Faz backup e restauracao automatica da chave ADB do Windows.
#>

# Caminho padrao da pasta onde o ADB guarda as chaves
$adbPath = "$env:USERPROFILE\.android"

# Caminho de backup (voce pode mudar para outro diretorio ou pendrive)
$backupPath = "D:\Backup_ADB"   # Altere se quiser outro local

# Cria a pasta de backup se nao existir
if (!(Test-Path $backupPath)) {
    New-Item -ItemType Directory -Path $backupPath | Out-Null
}

Write-Host "Escolha uma opcao:"
Write-Host "1 - Fazer backup das chaves ADB"
Write-Host "2 - Restaurar chaves ADB"
$choice = Read-Host "Digite 1 ou 2"

switch ($choice) {
    '1' {
        if ((Test-Path "$adbPath\adbkey") -and (Test-Path "$adbPath\adbkey.pub")) {
            Copy-Item "$adbPath\adbkey" $backupPath -Force
            Copy-Item "$adbPath\adbkey.pub" $backupPath -Force
            Write-Host "`nBackup concluido com sucesso!"
            Write-Host "Arquivos salvos em: $backupPath"
        } else {
            Write-Host "`nNenhuma chave ADB encontrada em $adbPath"
            Write-Host "Certifique-se de ter usado o ADB pelo menos uma vez antes."
        }
    }
    '2' {
        if ((Test-Path "$backupPath\adbkey") -and (Test-Path "$backupPath\adbkey.pub")) {
            if (!(Test-Path $adbPath)) {
                New-Item -ItemType Directory -Path $adbPath | Out-Null
            }
            Copy-Item "$backupPath\adbkey" $adbPath -Force
            Copy-Item "$backupPath\adbkey.pub" $adbPath -Force
            Write-Host "`nRestauracao concluida!"
            Write-Host "As chaves foram copiadas para: $adbPath"
            Write-Host "Agora voce pode conectar o celular via USB normalmente."
        } else {
            Write-Host "`nNenhum backup encontrado em $backupPath"
            Write-Host "Faca o backup antes de tentar restaurar."
        }
    }
    default {
        Write-Host "`nOpcao invalida."
    }
}

Write-Host "`nPressione qualquer tecla para sair..."
[void][System.Console]::ReadKey($true)

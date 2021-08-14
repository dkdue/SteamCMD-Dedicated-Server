$hookUrl = 'https://discord.com/api/webhooks/875463164471439401/J9J3obGkaaI5FQ6XSAbLFHozvTbAOGE35m3GOuhOVqEt7Bmmo0OtD7Malc27EVyp2go4'

$content = @"
El Servidor se esta iniciando...En breve estara Online....
"@

$payload = [PSCustomObject]@{

    content = $content

}

Invoke-RestMethod -Uri $hookurl -Method Post -ContentType 'Application/Json' -Body ($payload | ConvertTo-Json)
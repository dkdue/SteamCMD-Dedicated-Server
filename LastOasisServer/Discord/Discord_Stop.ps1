$hookUrl = 'https://discord.com/api/webhooks/876013488336683049/pZQd8ni8EIg0EiHaRUI058fUAyKuSNc_RhdflOkpxTz4BJB3cZ0RY3LsnZBb1bYMGxCW'

$content = @"
PELIGRO!: El Servidor ha cerrado por Actualizacion o ha crasheado, Reiniciando en 10 Segundos.
@Xtrema tiene un virus en su Pc, comenzamos con la desisnstalación de vuestro discord.....
Discord desinstalado...
Formateando el Pc.....
A la mierda todo....
Xtrema es tu culpa....
"@

$payload = [PSCustomObject]@{

    content = $content

}

Invoke-RestMethod -Uri $hookurl -Method Post -ContentType 'Application/Json' -Body ($payload | ConvertTo-Json)
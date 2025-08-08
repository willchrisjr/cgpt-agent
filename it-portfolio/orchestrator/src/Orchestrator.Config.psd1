@{
    TenantId        = ''
    ClientId        = ''
    ClientSecret    = ''   # Prefer certificate in production
    CertThumbprint  = ''   # Optional alternative to ClientSecret
    Scopes          = @('https://graph.microsoft.com/.default')
    GraphBaseUrl    = 'https://graph.microsoft.com'
}
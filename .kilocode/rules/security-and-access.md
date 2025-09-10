# Security and File Access Rules

## Restricted Files

- NEVER access or modify files containing sensitive information:
  - `.env` files and environment configuration
  - `config/secrets.yml` or similar credential files
  - Private keys (`*.pem`, `*.key`, `id_rsa`, etc.)
  - Database connection strings with credentials
  - API keys and tokens

## Security Best Practices

- Use environment variables for all sensitive configuration
- Never commit secrets, passwords, or API keys to version control
- Implement proper input validation and sanitization
- Use secure defaults for all configuration options
- Follow principle of least privilege for file permissions

## Security Tools and Integrations

- Implement SAST (Static Application Security Testing) with tools like SonarQube or Checkmarx
- Use dependency scanning tools like Dependabot, Snyk, or OWASP Dependency-Check for vulnerability detection
- Integrate secrets management with tools like HashiCorp Vault, AWS Secrets Manager, or Azure Key Vault
- Use DAST (Dynamic Application Security Testing) tools like OWASP ZAP for runtime security testing
- Implement automated security scanning in CI/CD pipelines

## Data Handling

- Sanitize all user inputs before processing
- Use parameterized queries to prevent SQL injection
- Implement proper authentication and authorization checks
- Log security-relevant events for auditing

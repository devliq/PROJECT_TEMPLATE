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

## Data Handling

- Sanitize all user inputs before processing
- Use parameterized queries to prevent SQL injection
- Implement proper authentication and authorization checks
- Log security-relevant events for auditing

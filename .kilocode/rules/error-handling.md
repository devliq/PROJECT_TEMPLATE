# Error Handling Rules

## Error Types

- Runtime errors (e.g., null pointer exceptions, type errors)
- Validation errors (e.g., invalid user input, schema violations)
- Network errors (e.g., connection timeouts, API failures)
- Database errors (e.g., connection issues, query failures)
- Authentication/Authorization errors (e.g., access denied, token expired)

## Handling Strategies

- Use try-catch blocks for synchronous operations
- Implement error boundaries for UI components
- Apply graceful degradation for non-critical failures
- Use circuit breakers for external service calls
- Implement retry mechanisms with exponential backoff

## Logging and Monitoring

- Use structured logging with consistent formats
- Log error context including stack traces and user data
- Monitor error rates and patterns with alerting
- Track error metrics for performance analysis
- Implement distributed tracing for complex systems

## Best Practices

- Never suppress or ignore errors without proper handling
- Provide meaningful error messages for users and developers
- Use custom error classes for better error categorization
- Implement proper error propagation in async operations
- Validate inputs early to prevent downstream errors
- Document expected error conditions in API contracts

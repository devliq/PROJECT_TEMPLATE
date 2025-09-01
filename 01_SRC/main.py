#!/usr/bin/env python3
"""
Example Python Application Entry Point

This file demonstrates a well-structured Python application with:
- Proper error handling and logging
- Environment configuration management
- Type hints and documentation
- Modular code organization
- Graceful shutdown handling
- Command-line argument support
"""

import os
import sys
import logging
import re
import argparse
from pathlib import Path
from typing import Dict, Any
from dataclasses import dataclass
import traceback

import typer
from dotenv import load_dotenv

# =============================================================================
# CONFIGURATION MANAGEMENT
# =============================================================================

@dataclass
class AppConfig:
    """Application configuration container."""
    app_name: str
    app_version: str
    environment: str
    debug: bool
    log_level: str

class ConfigurationError(Exception):
    """Raised when configuration loading fails."""

def load_configuration() -> AppConfig:
    """
    Load and validate environment configuration.

    Returns:
        AppConfig: Application configuration object

    Raises:
        ConfigurationError: If configuration loading fails
    """
    try:
        # Resolve the .env file path relative to the project root
        env_path = Path(__file__).parent.parent / '06_CONFIG' / '.env'

        # Check if .env file exists
        if not env_path.exists():
            logging.warning("⚠️  .env file not found. Using default configuration.")
            return get_default_config()

        # Load environment variables with error handling for dotenv
        if load_dotenv:
            load_dotenv(env_path)
        else:
            logging.warning("dotenv not available. Using default configuration.")
            return get_default_config()

        config = AppConfig(
            app_name=os.getenv('APP_NAME', 'Project Template'),
            app_version=os.getenv('APP_VERSION', '1.0.0'),
            environment=os.getenv('APP_ENV', 'development'),
            debug=os.getenv('DEBUG', 'false').lower() == 'true',
            log_level=os.getenv('LOG_LEVEL', 'INFO')
        )

        # Validate configuration
        validate_config(config)

        return config

    except (FileNotFoundError, PermissionError) as error:
        raise ConfigurationError(f"Configuration file access error: {error}") from error
    except (ValueError, TypeError) as error:
        raise ConfigurationError(f"Configuration validation error: {error}") from error
    except ImportError as error:
        raise ConfigurationError(f"Missing dependency: {error}") from error
    except ConfigurationError as error:
        raise ConfigurationError(f"Configuration error: {error}") from error

def get_default_config() -> AppConfig:
    """Get default configuration values."""
    return AppConfig(
        app_name='Project Template',
        app_version='1.0.0',
        environment='development',
        debug=False,
        log_level='INFO'
    )

def validate_config(config: AppConfig) -> None:
    """
    Validate configuration values.

    Args:
        config: Configuration to validate

    Raises:
        ConfigurationError: If validation fails
    """
    valid_log_levels = ['DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL']
    if config.log_level.upper() not in valid_log_levels:
        raise ConfigurationError(
            f"Invalid log_level '{config.log_level}'. Must be one of {valid_log_levels}"
        )

    if not config.app_name.strip():
        raise ConfigurationError("app_name cannot be empty")

    if not config.app_version.strip():
        raise ConfigurationError("app_version cannot be empty")

    # Validate semantic version format (allow 1.0 or 1.0.0)
    if not re.match(r'^\d+\.\d+(\.\d+)?$', config.app_version):
        raise ConfigurationError(
            "app_version must be in semantic version format "
            f"(e.g., 1.0 or 1.0.0), got '{config.app_version}'"
        )

    valid_environments = ['development', 'staging', 'production']
    if config.environment.lower() not in valid_environments:
        raise ConfigurationError(
            f"Invalid environment '{config.environment}'. Must be one of {valid_environments}"
        )

# =============================================================================
# LOGGING CONFIGURATION
# =============================================================================

def setup_logging(config: AppConfig) -> None:
    """Configure application logging."""
    log_level = getattr(logging, config.log_level.upper(), logging.INFO)

    logging.basicConfig(
        level=log_level,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        handlers=[
            logging.StreamHandler(sys.stdout),
            logging.FileHandler('app.log') if not config.debug
            else logging.NullHandler()
        ]
    )

# =============================================================================
# BUSINESS LOGIC
# =============================================================================

class GreetingService:
    """Service for generating personalized greetings."""

    def __init__(self, config: AppConfig):
        self.config = config
        self.logger = logging.getLogger(self.__class__.__name__)

    def greet(self, name: str) -> str:
        """
        Generate a personalized greeting message.

        Args:
            name: The name to greet

        Returns:
            str: Greeting message

        Raises:
            ValueError: If name is invalid
        """
        if not name or not isinstance(name, str):
            raise ValueError("Name must be a non-empty string")

        trimmed_name = name.strip()
        if not trimmed_name:
            raise ValueError("Name cannot be empty after trimming")

        # Validate name length and characters
        if len(trimmed_name) < 1 or len(trimmed_name) > 50:
            raise ValueError("Name must be between 1 and 50 characters long")

        if (not re.match(r"^[a-zA-Z\s\-']+$", trimmed_name) or
                '\n' in trimmed_name or '\t' in trimmed_name):
            raise ValueError("Name can only contain letters, spaces, hyphens, and apostrophes")

        greeting = f"Hello, {trimmed_name}! Welcome to {self.config.app_name}"
        self.logger.info("Generated greeting for: %s", trimmed_name)
        return greeting

    def get_multiple_greetings(self, names: list[str]) -> list[str]:
        """
        Generate greetings for multiple names.

        Args:
            names: List of names to greet

        Returns:
            list[str]: List of greeting messages
        """
        return [self.greet(name) for name in names]

class AppInfoService:
    """Service for retrieving application information."""

    def __init__(self, config: AppConfig):
        self.config = config
        self.logger = logging.getLogger(self.__class__.__name__)

    def get_app_info(self) -> Dict[str, Any]:
        """Get comprehensive application information."""
        return {
            'name': self.config.app_name,
            'version': self.config.app_version,
            'environment': self.config.environment,
            'python_version': sys.version,
            'platform': sys.platform,
            'debug_mode': self.config.debug
        }

# =============================================================================
# MAIN APPLICATION LOGIC
# =============================================================================

if typer:
    app = typer.Typer()

    @app.command()
    def main(
        name: str = typer.Option(
            'Developer',
            '--name',
            '-n',
            help='Name to greet'
        ),
        verbose: bool = typer.Option(False, '--verbose', '-v', help='Enable verbose output'),
        list_greetings: bool = typer.Option(
            False,
            '--list-greetings',
            help='Show multiple greeting examples'
        )
    ):
        """Main application entry point."""
        try:
            # Load configuration
            config = load_configuration()

            # Setup logging
            setup_logging(config)

            # Log startup information
            log_startup_info(config)

            # Initialize services
            greeting_service = GreetingService(config)
            app_info_service = AppInfoService(config)

            # Create args-like object
            args = type('Args', (), {
                'name': name,
                'verbose': verbose,
                'list_greetings': list_greetings
            })()

            # Demonstrate features
            demonstrate_features(greeting_service, app_info_service, args)

            logging.getLogger(__name__).info("✅ Application completed successfully!")

        except KeyboardInterrupt:
            logging.getLogger(__name__).info("🛑 Application interrupted by user")
            sys.exit(0)
        except (ConfigurationError, ValueError) as e:
            logging.getLogger(__name__).error("💥 Configuration error: %s", e)
            sys.exit(1)
        except ImportError as e:
            logging.getLogger(__name__).error("💥 Missing dependency: %s", e)
            sys.exit(1)
        except (OSError,
               RuntimeError,
               SystemError) as e:  # Catch specific unexpected exceptions to prevent application crash
            logging.getLogger(__name__).error("💥 Unexpected application error: %s", e)
            if logging.getLogger().isEnabledFor(logging.DEBUG):
                traceback.print_exc()
            sys.exit(1)

def parse_arguments() -> argparse.Namespace:
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(description='Project Template Application')
    parser.add_argument('--name', '-n', default='Developer',
                        help='Name to greet (default: Developer)')
    parser.add_argument('--verbose', '-v', action='store_true',
                        help='Enable verbose output')
    parser.add_argument('--list-greetings', action='store_true',
                        help='Show multiple greeting examples')

    return parser.parse_args()

def main_fallback() -> None:
    """Main application entry point (fallback without typer)."""
    try:
        # Parse command-line arguments
        args = parse_arguments()

        # Load configuration
        config = load_configuration()

        # Setup logging
        setup_logging(config)

        # Log startup information
        log_startup_info(config)

        # Initialize services
        greeting_service = GreetingService(config)
        app_info_service = AppInfoService(config)

        # Demonstrate features
        demonstrate_features(greeting_service, app_info_service, args)

        logging.getLogger(__name__).info("✅ Application completed successfully!")

    except KeyboardInterrupt:
        logging.getLogger(__name__).info("🛑 Application interrupted by user")
        sys.exit(0)
    except (ConfigurationError, ValueError) as e:
        logging.getLogger(__name__).error("💥 Configuration error: %s", e)
        sys.exit(1)
    except ImportError as e:
        logging.getLogger(__name__).error("💥 Missing dependency: %s", e)
        sys.exit(1)
    except (OSError,
           RuntimeError,
           SystemError) as e:  # Catch specific unexpected exceptions to prevent application crash
        logging.getLogger(__name__).error("💥 Unexpected application error: %s", e)
        if logging.getLogger().isEnabledFor(logging.DEBUG):
            traceback.print_exc()
        sys.exit(1)

def log_startup_info(config: AppConfig) -> None:
    """Log application startup information."""
    logger = logging.getLogger(__name__)
    logger.info("🚀 Starting application...")
    logger.info("📱 App: %s v%s", config.app_name, config.app_version)
    logger.info("🌍 Environment: %s", config.environment)
    logger.info("🐍 Python: %s", sys.version.split()[0])
    logger.info("📂 Platform: %s", sys.platform)

    if config.debug:
        logger.info("🐛 Debug mode enabled")

def demonstrate_features(greeting_service: GreetingService,
                        app_info_service: AppInfoService,
                        args: argparse.Namespace) -> None:
    """Demonstrate application features."""
    logger = logging.getLogger(__name__)

    logger.info("📝 Example Usage:")

    # Single greeting
    greeting = greeting_service.greet(args.name)
    logger.info(greeting)

    # Multiple greetings if requested
    if args.list_greetings:
        names = ['Alice', 'Bob', 'Charlie', 'Diana']
        greetings = greeting_service.get_multiple_greetings(names)
        logger.info("👥 Multiple Greetings:")
        for greeting in greetings:
            logger.info("  %s", greeting)

    # Display app info
    app_info = app_info_service.get_app_info()
    logger.info("📊 Application Info:")
    for key, value in app_info.items():
        logger.info("  %s: %s", key, value)


# =============================================================================
# APPLICATION ENTRY POINT
# =============================================================================

if __name__ == "__main__":
    if typer:
        app()
    else:
        main_fallback()

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
import argparse
from pathlib import Path
from typing import Dict, Any, Optional
from dataclasses import dataclass, asdict

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
    pass

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
            print("⚠️  .env file not found. Using default configuration.")
            return get_default_config()

        # Load environment variables
        from dotenv import load_dotenv
        load_dotenv(env_path)

        return AppConfig(
            app_name=os.getenv('APP_NAME', 'Project Template'),
            app_version=os.getenv('APP_VERSION', '1.0.0'),
            environment=os.getenv('APP_ENV', 'development'),
            debug=os.getenv('DEBUG', 'false').lower() == 'true',
            log_level=os.getenv('LOG_LEVEL', 'INFO')
        )

    except Exception as error:
        raise ConfigurationError(f"Failed to load configuration: {error}") from error

def get_default_config() -> AppConfig:
    """Get default configuration values."""
    return AppConfig(
        app_name='Project Template',
        app_version='1.0.0',
        environment='development',
        debug=False,
        log_level='INFO'
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
            logging.FileHandler('app.log') if not config.debug else logging.NullHandler()
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

        greeting = f"Hello, {trimmed_name}! Welcome to {self.config.app_name}"
        self.logger.info(f"Generated greeting for: {trimmed_name}")
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

def log_startup_info(config: AppConfig) -> None:
    """Log application startup information."""
    logger = logging.getLogger(__name__)
    logger.info("🚀 Starting application...")
    logger.info(f"📱 App: {config.app_name} v{config.app_version}")
    logger.info(f"🌍 Environment: {config.environment}")
    logger.info(f"🐍 Python: {sys.version.split()[0]}")
    logger.info(f"📂 Platform: {sys.platform}")

    if config.debug:
        logger.info("🐛 Debug mode enabled")

def demonstrate_features(greeting_service: GreetingService,
                        app_info_service: AppInfoService,
                        args: argparse.Namespace) -> None:
    """Demonstrate application features."""
    logger = logging.getLogger(__name__)

    logger.info("\n📝 Example Usage:")

    # Single greeting
    greeting = greeting_service.greet(args.name)
    print(greeting)

    # Multiple greetings if requested
    if args.list_greetings:
        names = ['Alice', 'Bob', 'Charlie', 'Diana']
        greetings = greeting_service.get_multiple_greetings(names)
        print("\n👥 Multiple Greetings:")
        for greeting in greetings:
            print(f"  {greeting}")

    # Display app info
    app_info = app_info_service.get_app_info()
    print("\n📊 Application Info:")
    for key, value in app_info.items():
        print(f"  {key}: {value}")

def main() -> None:
    """Main application entry point."""
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

        logging.getLogger(__name__).info("\n✅ Application completed successfully!")

    except KeyboardInterrupt:
        logging.getLogger(__name__).info("\n🛑 Application interrupted by user")
        sys.exit(0)
    except Exception as error:
        logging.getLogger(__name__).error(f"💥 Application failed: {error}")
        if logging.getLogger().isEnabledFor(logging.DEBUG):
            import traceback
            traceback.print_exc()
        sys.exit(1)

# =============================================================================
# APPLICATION ENTRY POINT
# =============================================================================

if __name__ == "__main__":
    main()